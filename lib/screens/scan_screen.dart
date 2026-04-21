import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'relatorio_screen.dart';

const String baseUrl = 'https://web-production-7c79c.up.railway.app';

const Color kGold = Color(0xFFC9A84C);
const Color kGoldLight = Color(0xFFE8C97A);

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  int? recebimentoId;
  List<Map<String, dynamic>> itens = [];
  bool processando = false;
  bool debounceAtivo = false;
  String? ultimoDun14Lido;
  DateTime? ultimaLeitura;
  final MobileScannerController cameraController = MobileScannerController();
  final Map<String, Map<String, dynamic>> cacheProdutos = {};

  @override
  void initState() {
    super.initState();
    _iniciarRecebimento();
  }

  Future<void> _iniciarRecebimento() async {
    final response = await http.post(Uri.parse('$baseUrl/recebimento/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => recebimentoId = data['id']);
    }
  }

  bool _scanDuplicado(String dun14) {
    final agora = DateTime.now();
    if (ultimoDun14Lido == dun14 && ultimaLeitura != null) {
      if (agora.difference(ultimaLeitura!).inMilliseconds < 1000) return true;
    }
    ultimoDun14Lido = dun14;
    ultimaLeitura = agora;
    return false;
  }

  Future<void> _processarScan(String dun14) async {
    if (processando) return;
    if (_scanDuplicado(dun14)) return;

    setState(() {
      processando = true;
      debounceAtivo = true;
    });

    Map<String, dynamic>? produto = cacheProdutos[dun14];
    if (produto == null) {
      final produtoRes = await http.get(Uri.parse('$baseUrl/produto/$dun14'));
      if (produtoRes.statusCode != 200) {
        _mostrarErro('Produto não encontrado: $dun14');
        setState(() {
          processando = false;
          debounceAtivo = false;
        });
        return;
      }
      produto = jsonDecode(produtoRes.body);
      cacheProdutos[dun14] = produto!;
    }

    setState(() {
      final index = itens.indexWhere((i) => i['dun14'] == dun14);
      if (index >= 0) {
        itens[index]['quantidade'] += 1;
      } else {
        itens.add({'nome': produto!['nome'], 'dun14': dun14, 'quantidade': 1});
      }
      processando = false;
    });

    final qtd = itens.firstWhere((i) => i['dun14'] == dun14)['quantidade'];
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        '${produto['nome']}  ·  $qtd cx',
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
      duration: const Duration(milliseconds: 600),
      backgroundColor: kGold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      margin: const EdgeInsets.all(16),
    ));

    http.post(Uri.parse('$baseUrl/recebimento/$recebimentoId/item?dun14=$dun14'));

    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => debounceAtivo = false);
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ESCANEAR CAIXAS'),
        actions: [
          if (itens.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RelatorioScreen(
                        recebimentoId: recebimentoId!,
                        itens: itens,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'FINALIZAR',
                  style: TextStyle(
                    color: kGold,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: Column(
        children: [
          // Câmera
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.first;
                    if (barcode.rawValue != null) {
                      _processarScan(barcode.rawValue!);
                    }
                  },
                ),
                // Overlay de mira
                Center(
                  child: Container(
                    width: 220,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: kGold, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                // Flash branco do debounce
                if (debounceAtivo)
                  AnimatedOpacity(
                    opacity: debounceAtivo ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          color: kGold,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Divisor
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          // Lista de itens
          Expanded(
            flex: 2,
            child: itens.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            size: 32, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text(
                          'Nenhum item escaneado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: itens.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF5F5F5),
                    ),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              itens[i]['nome'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF333333),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF5E9),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              '${itens[i]['quantidade']} cx',
                              style: const TextStyle(
                                fontSize: 11,
                                color: kGold,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}