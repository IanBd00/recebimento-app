import 'package:flutter/material.dart';

class RelatorioScreen extends StatelessWidget {
  final int recebimentoId;
  final List<Map<String, dynamic>> itens;

  const RelatorioScreen({super.key, required this.recebimentoId, required this.itens});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Recebimento'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recebimento #$recebimentoId', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${itens.length} produto(s) recebido(s)', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            Expanded(
              child: ListView.builder(
                itemCount: itens.length,
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.blue),
                    title: Text(itens[i]['nome'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('DUN-14: ${itens[i]['dun14']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                      child: Text('${itens[i]['quantidade']} cx', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Concluir', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ),
          ],
        ),
      ),
    );
  }
}