import 'package:flutter/material.dart';

const Color kGold = Color(0xFFC9A84C);

class RelatorioScreen extends StatelessWidget {
  final int recebimentoId;
  final List<Map<String, dynamic>> itens;

  const RelatorioScreen({
    super.key,
    required this.recebimentoId,
    required this.itens,
  });

  int get totalCaixas =>
      itens.fold(0, (sum, item) => sum + (item['quantidade'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('RELATÓRIO'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF0F0F0)),
        ),
      ),
      body: Column(
        children: [
          // Header com resumo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recebimento #$recebimentoId',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${itens.length} produto(s)  ·  $totalCaixas caixas no total',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 1,
                  color: kGold,
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F0F0)),
          // Lista
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: itens.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFF5F5F5),
              ),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itens[i]['nome'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'DUN-14: ${itens[i]['dun14']}',
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
          // Botão concluir
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('CONCLUIR'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}