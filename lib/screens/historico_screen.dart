import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const Color kGold = Color(0xFFC9A84C);
const String baseUrl = 'https://web-production-7c79c.up.railway.app';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  List<dynamic> recebimentos = [];
  bool carregando = true;
  DateTime? dataInicio;
  DateTime? dataFim;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => carregando = true);

    String url = '$baseUrl/recebimento/historico';
    final params = <String>[];
    if (dataInicio != null) params.add('data_inicio=${dataInicio!.toIso8601String().substring(0, 10)}');
    if (dataFim != null) params.add('data_fim=${dataFim!.toIso8601String().substring(0, 10)}');
    if (params.isNotEmpty) url += '?${params.join('&')}';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() {
        recebimentos = jsonDecode(response.body);
        carregando = false;
      });
    } else {
      setState(() => carregando = false);
    }
  }

  Future<void> _selecionarData(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: kGold),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) dataInicio = picked;
        else dataFim = picked;
      });
      _carregarHistorico();
    }
  }

  void _limparFiltros() {
    setState(() {
      dataInicio = null;
      dataFim = null;
    });
    _carregarHistorico();
  }

  String _formatarData(String isoDate) {
    final dt = DateTime.parse(isoDate);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('HISTÓRICO'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: Column(
        children: [
          // Filtro de data
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selecionarData(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        dataInicio != null
                            ? _formatarData(dataInicio!.toIso8601String())
                            : 'Data início',
                        style: TextStyle(
                          fontSize: 11,
                          color: dataInicio != null ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selecionarData(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Text(
                        dataFim != null
                            ? _formatarData(dataFim!.toIso8601String())
                            : 'Data fim',
                        style: TextStyle(
                          fontSize: 11,
                          color: dataFim != null ? const Color(0xFF1A1A1A) : const Color(0xFFAAAAAA),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                if (dataInicio != null || dataFim != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _limparFiltros,
                    child: const Icon(Icons.close, size: 18, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          // Lista
          Expanded(
            child: carregando
                ? const Center(
                    child: CircularProgressIndicator(color: kGold, strokeWidth: 1.5),
                  )
                : recebimentos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text(
                              'Nenhum recebimento encontrado',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: recebimentos.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: Color(0xFFF5F5F5),
                        ),
                        itemBuilder: (_, i) {
                          final r = recebimentos[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['nome'] ?? 'Sem nome',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _formatarData(r['data']),
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAF5E9),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child: Text(
                                        '${r['total_caixas']} cx',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: kGold,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${r['total_itens']} produto(s)',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFFAAAAAA),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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