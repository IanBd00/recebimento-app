import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'historico_detalhe_screen.dart';
import '../services/pdf_service.dart';

const Color kGold = Color(0xFFC9A84C);
const String baseUrl = 'https://web-production-7c79c.up.railway.app';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List<dynamic> historicos = [];
  bool carregando = true;
  DateTime? dataInicio;
  DateTime? dataFim;
  final TextEditingController _inicioController = TextEditingController();
  final TextEditingController _fimController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  void dispose() {
    _inicioController.dispose();
    _fimController.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    setState(() => carregando = true);
    String url = '$baseUrl/historico/';
    final params = <String>[];
    if (dataInicio != null)
      params.add('data_inicio=${dataInicio!.toIso8601String()}');
    if (dataFim != null) params.add('data_fim=${dataFim!.toIso8601String()}');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() {
        historicos = jsonDecode(response.body);
        carregando = false;
      });
    } else {
      setState(() => carregando = false);
    }
  }

  Future<void> _deletarHistorico(int id) async {
    await http.delete(Uri.parse('$baseUrl/historico/$id'));
    _carregarHistorico();
  }

  Future<void> _deletarTodos() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          'APAGAR TUDO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: const Text(
          'Todos os históricos serão apagados permanentemente. Deseja continuar?',
          style: TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                  fontSize: 10, color: Color(0xFF888888), letterSpacing: 1.5),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'APAGAR',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await http.delete(Uri.parse('$baseUrl/historico/'));
      _carregarHistorico();
    }
  }

  void _onDataChanged(String value, bool isInicio) {
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) formatted += '/';
      formatted += digits[i];
    }

    final controller = isInicio ? _inicioController : _fimController;
    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    if (digits.length == 8) {
      try {
        final dia = int.parse(digits.substring(0, 2));
        final mes = int.parse(digits.substring(2, 4));
        final ano = int.parse(digits.substring(4, 8));
        final data = DateTime(ano, mes, dia);
        setState(() {
          if (isInicio)
            dataInicio = data;
          else
            dataFim = data;
        });
        _carregarHistorico();
      } catch (_) {}
    } else {
      setState(() {
        if (isInicio)
          dataInicio = null;
        else
          dataFim = null;
      });
    }
  }

  void _limparFiltros() {
    _inicioController.clear();
    _fimController.clear();
    setState(() {
      dataInicio = null;
      dataFim = null;
    });
    _carregarHistorico();
  }

  String _formatarData(String isoDate) {
    final data = DateTime.parse(isoDate);
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('HISTÓRICO'),
        actions: [
          if (historicos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton(
                onPressed: () {
                  PdfService.gerarRelatorioGeral(
                    context: context,
                    historicos: historicos,
                    periodo: 'Relatório Geral',
                  );
                },
                child: const Text(
                  'EXPORTAR PDF',
                  style: TextStyle(
                    fontSize: 10,
                    color: kGold,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _deletarTodos,
                child: const Text(
                  'APAGAR TUDO',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inicioController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _onDataChanged(v, true),
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A)),
                    decoration: const InputDecoration(
                      hintText: 'dd/mm/aaaa',
                      hintStyle:
                          TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: kGold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fimController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _onDataChanged(v, false),
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF1A1A1A)),
                    decoration: const InputDecoration(
                      hintText: 'dd/mm/aaaa',
                      hintStyle:
                          TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: kGold),
                      ),
                    ),
                  ),
                ),
                if (dataInicio != null || dataFim != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _limparFiltros,
                    child: const Icon(Icons.close,
                        size: 18, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          Expanded(
            child: carregando
                ? const Center(
                    child:
                        CircularProgressIndicator(color: kGold, strokeWidth: 2),
                  )
                : historicos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 32, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(
                              'Nenhum recebimento encontrado',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: historicos.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Color(0xFFF5F5F5),
                        ),
                        itemBuilder: (_, i) {
                          final h = historicos[i];
                          return Dismissible(
                            key: Key(h['id'].toString()),
                            direction: DismissDirection.startToEnd,
                            background: Container(
                              color: Colors.red.shade50,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero),
                                  title: const Text(
                                    'APAGAR',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  content: Text(
                                    'Apagar "${h['nome']}"?',
                                    style: const TextStyle(
                                        fontSize: 12, color: Color(0xFF666666)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text(
                                        'CANCELAR',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF888888),
                                            letterSpacing: 1.5),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'APAGAR',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) => _deletarHistorico(h['id']),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HistoricoDetalheScreen(
                                      historicoId: h['id'],
                                      nome: h['nome'],
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            h['nome'],
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1A1A),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatarData(h['data']),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFFAAAAAA),
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${h['total_caixas']} cx',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: kGold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${h['total_produtos']} produto(s)',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFAAAAAA),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right,
                                        size: 16, color: Color(0xFFCCCCCC)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
