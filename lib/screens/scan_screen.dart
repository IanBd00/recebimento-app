import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'relatorio_screen.dart';

const Color kGold = Color(0xFFC9A84C);
const String baseUrl = 'https://web-production-7c79c.up.railway.app';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  int? recebimentoId;
  List<Map<String, dynamic>> itens = [];
  bool processando = false;
  bool debounceAtivo = false;
  String? ultimoDun14Lido;
  DateTime? ultimaLeitura;
  final Map<String, Map<String, dynamic>> cacheProdutos = {};
  late AnimationController _lineController;
  late Animation<double> _lineAnimation;

  final List<String> _fila = [];
  bool _processandoFila = false;

  int get totalCaixas =>
      itens.fold(0, (sum, i) => sum + (i['quantidade'] as int));

  @override
  void initState() {
    super.initState();
    _iniciarRecebimento();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lineAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_lineController);
  }

  Future<void> _iniciarRecebimento() async {
    final response = await http.post(Uri.parse('$baseUrl/recebimento/'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => recebimentoId = data['id']);
    }
  }

  Future<void> _processarFila() async {
    if (_processandoFila) return;
    _processandoFila = true;

    while (_fila.isNotEmpty) {
      final dun14 = _fila.first;
      bool sucesso = false;

      for (int tentativa = 0; tentativa < 3; tentativa++) {
        try {
          final response = await http
              .post(
                Uri.parse(
                    '$baseUrl/recebimento/$recebimentoId/item?dun14=$dun14'),
              )
              .timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            sucesso = true;
            break;
          }
        } catch (_) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      if (sucesso || true) _fila.removeAt(0);
    }

    _processandoFila = false;
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
        itens.add({
          'nome': produto!['nome'],
          'dun14': dun14,
          'quantidade': 1,
        });
      }
      processando = false;
    });

    _fila.add(dun14);
    _processarFila();

    if (!kIsWeb) HapticFeedback.mediumImpact();

    final qtd = itens.firstWhere((i) => i['dun14'] == dun14)['quantidade'];
    final nomeProduto = produto['nome'];

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$nomeProduto  ·  $qtd cx',
          style: const TextStyle(
              fontSize: 12, letterSpacing: 0.5, color: Colors.white),
        ),
        duration: const Duration(milliseconds: 800),
        backgroundColor: kGold,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        margin: const EdgeInsets.all(16),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() => debounceAtivo = false);
  }

  Future<void> _editarQuantidade(int index) async {
    final item = itens[index];
    int qtdTemp = item['quantidade'] as int;

    final novaQtd = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text(
            'EDITAR QUANTIDADE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['nome'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (qtdTemp > 0) {
                        setStateDialog(() => qtdTemp -= 1);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Icon(Icons.remove,
                          size: 18, color: Color(0xFF888888)),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFEEEEEE)),
                        bottom: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                    ),
                    child: Text(
                      '$qtdTemp cx',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setStateDialog(() => qtdTemp += 1);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Icon(Icons.add, size: 18, color: kGold),
                    ),
                  ),
                ],
              ),
              if (qtdTemp == 0)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Quantidade 0 remove o item da lista.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                    fontSize: 10, color: Color(0xFF888888), letterSpacing: 1.5),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, qtdTemp),
              child: const Text(
                'CONFIRMAR',
                style: TextStyle(
                  fontSize: 10,
                  color: kGold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (novaQtd == null) return;

    final dun14 = itens[index]['dun14'] as String;
    final qtdAtual = itens[index]['quantidade'] as int;
    final diferenca = novaQtd - qtdAtual;

    setState(() {
      if (novaQtd == 0) {
        itens.removeAt(index);
      } else {
        itens[index]['quantidade'] = novaQtd;
      }
    });

    if (diferenca > 0) {
      for (int i = 0; i < diferenca; i++) {
        _fila.add(dun14);
      }
      _processarFila();
    } else if (diferenca < 0) {
      for (int i = 0; i < diferenca.abs(); i++) {
        http.delete(
            Uri.parse('$baseUrl/recebimento/$recebimentoId/item?dun14=$dun14'));
      }
    } else if (novaQtd == 0) {
      http.delete(
          Uri.parse('$baseUrl/recebimento/$recebimentoId/item?dun14=$dun14'));
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ESCANEAR'),
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
          Expanded(
            flex: 3,
            child: kIsWeb
                ? Container(
                    color: const Color(0xFF111111),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'MODO DE TESTE',
                            style: TextStyle(
                              fontSize: 9,
                              color: kGold,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => _processarScan('10012345678901'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: kGold, width: 1.5),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2_outlined,
                                      color: kGold, size: 28),
                                  SizedBox(height: 8),
                                  Text(
                                    'SABONETE GIOVANA',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: kGold,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '10012345678901',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFF888888),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      // ZXing scanner
                      ReaderWidget(
                        onScan: (result) {
                          if (result.isValid && result.text != null) {
                            final code = result.text!;
                            if (RegExp(r'^\d{14}$').hasMatch(code)) {
                              _processarScan(code);
                            }
                          }
                        },
                        codeFormat: Format.itf,
                        tryHarder: true,
                        tryInverted: false,
                        showGallery: false,
                        showToggleCamera: false,
                        scannerOverlay: FixedScannerOverlay(
                          borderColor: kGold,
                          borderRadius: 0,
                          borderLength: 22,
                          borderWidth: 3,
                          cutOutSize: 220,
                          overlayColor: Colors.black54,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.55),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: const Text(
                            'LENDO DUN-14',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              color: kGold,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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
          Container(
            color: const Color(0xFFFAF8F4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${itens.length} ${itens.length == 1 ? 'ITEM' : 'ITENS'}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFFAAAAAA),
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$totalCaixas CX TOTAL',
                  style: const TextStyle(
                    fontSize: 9,
                    color: kGold,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          Expanded(
            flex: 2,
            child: itens.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner,
                            size: 28, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        Text(
                          'Nenhum item escaneado',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: itens.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Color(0xFFF5F5F5),
                    ),
                    itemBuilder: (_, i) => GestureDetector(
                      onLongPress: () => _editarQuantidade(i),
                      child: Padding(
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
                              decoration: const BoxDecoration(
                                color: Color(0xFFFAF5E9),
                                border: Border(
                                  left: BorderSide(color: kGold, width: 2),
                                ),
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
          ),
        ],
      ),
    );
  }
}
