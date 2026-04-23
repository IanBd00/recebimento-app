import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const Color kGold = Color(0xFFC9A84C);
const String baseUrl = 'https://web-production-7c79c.up.railway.app';

class RelatorioScreen extends StatefulWidget {
  final int recebimentoId;
  final List<Map<String, dynamic>> itens;

  const RelatorioScreen({
    super.key,
    required this.recebimentoId,
    required this.itens,
  });

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  bool salvando = false;

  int get totalCaixas =>
      widget.itens.fold(0, (sum, item) => sum + (item['quantidade'] as int));

  Future<void> _salvarHistorico() async {
    final controller = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: const Text(
          'SALVAR RECEBIMENTO',
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
            const Text(
              'Dê um nome para identificar este recebimento no histórico.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF888888),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Ex: Fornecedor X — Abril 2026',
                hintStyle: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kGold),
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
                fontSize: 10,
                color: Color(0xFF888888),
                letterSpacing: 1.5,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text(
              'SALVAR',
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
    );

    if (nome == null) return;

    setState(() => salvando = true);

    await http.post(
      Uri.parse('$baseUrl/historico/?recebimento_id=${widget.recebimentoId}&nome=${Uri.encodeComponent(nome)}'),
    );

    setState(() => salvando = false);

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recebimento #${widget.recebimentoId}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.itens.length} produto(s)  ·  $totalCaixas caixas no total',
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
              itemCount: widget.itens.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: Color(0xFFF5F5F5),
              ),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.itens[i]['nome'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'DUN-14: ${widget.itens[i]['dun14']}',
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF5E9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        '${widget.itens[i]['quantidade']} cx',
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: salvando ? null : _salvarHistorico,
                child: salvando
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('SALVAR E CONCLUIR'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}