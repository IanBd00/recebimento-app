import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/pdf_service.dart';

const Color kGold = Color(0xFFC9A84C);
const String baseUrl = 'https://web-production-7c79c.up.railway.app';

class HistoricoDetalheScreen extends StatefulWidget {
  final int historicoId;
  final String nome;

  const HistoricoDetalheScreen({
    super.key,
    required this.historicoId,
    required this.nome,
  });

  @override
  State<HistoricoDetalheScreen> createState() => _HistoricoDetalheScreenState();
}

class _HistoricoDetalheScreenState extends State<HistoricoDetalheScreen> {
  Map<String, dynamic>? detalhe;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDetalhe();
  }

  Future<void> _carregarDetalhe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/historico/${widget.historicoId}'),
    );
    if (response.statusCode == 200) {
      setState(() {
        detalhe = jsonDecode(response.body);
        carregando = false;
      });
    }
  }

  int get totalCaixas {
    if (detalhe == null) return 0;
    return (detalhe!['itens'] as List)
        .fold(0, (sum, item) => sum + (item['quantidade'] as int));
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
        title: Text(widget.nome.toUpperCase()),
        actions: [
          if (detalhe != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () {
                  PdfService.gerarRelatorioRecebimento(
                    context: context,
                    nomeRecebimento: widget.nome,
                    data: _formatarData(detalhe!['data']),
                    itens: List<Map<String, dynamic>>.from(detalhe!['itens']),
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
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: carregando
          ? const Center(
              child: CircularProgressIndicator(color: kGold, strokeWidth: 2),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatarData(detalhe!['data']),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${(detalhe!['itens'] as List).length} produto(s)  ·  $totalCaixas caixas no total',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF888888),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 40, height: 1, color: kGold),
                    ],
                  ),
                ),
                Container(height: 1, color: const Color(0xFFF0F0F0)),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: (detalhe!['itens'] as List).length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                      color: Color(0xFFF5F5F5),
                    ),
                    itemBuilder: (_, i) {
                      final item = detalhe!['itens'][i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nome'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'DUN-14: ${item['dun14']}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFAAAAAA),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF5E9),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                '${item['quantidade']} cx',
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
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
