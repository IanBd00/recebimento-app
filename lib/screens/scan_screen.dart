import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'relatorio_screen.dart';

const String baseUrl = 'https://web-production-7c79c.up.railway.app';

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
      final diferenca = agora.difference(ultimaLeitura!).inMilliseconds;
      if (diferenca < 1000) return true;
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
      content: Text('${produto['nome']} — $qtd cx'),
      duration: const Duration(milliseconds: 600),
      backgroundColor: Colors.green,
    ));

    http.post(Uri.parse('$baseUrl/recebimento/$recebimentoId/item?dun14=$dun14'));

    // Mantém tela branca pelo tempo do debounce
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => debounceAtivo = false);
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Caixas'),
        actions: [
          if (itens.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Finalizar', style: TextStyle(color: Colors.white)),
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
            ),
        ],
      ),
      body: Column(
        children: [
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
                if (debounceAtivo)
                  AnimatedOpacity(
                    opacity: debounceAtivo ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: Container(
                      color: Colors.white,
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: itens.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum item escaneado ainda',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: itens.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.inventory),
                      title: Text(itens[i]['nome']),
                      trailing: Text(
                        '${itens[i]['quantidade']} cx',
                        style: const TextStyle(fontWeight: FontWeight.bold),
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