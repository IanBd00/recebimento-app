import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

const PdfColor kGoldPdf = PdfColor.fromInt(0xFFC9A84C);
const PdfColor kDarkPdf = PdfColor.fromInt(0xFF1A1A1A);
const PdfColor kGrayPdf = PdfColor.fromInt(0xFF888888);
const PdfColor kLightPdf = PdfColor.fromInt(0xFFFAF8F4);

class PdfService {
  // PDF de um recebimento específico
  static Future<void> gerarRelatorioRecebimento({
    required BuildContext context,
    required String nomeRecebimento,
    required String data,
    required List<Map<String, dynamic>> itens,
  }) async {
    final pdf = pw.Document();
    final totalCaixas =
        itens.fold(0, (sum, i) => sum + (i['quantidade'] as int));
    final produtoMaior = itens.isEmpty
        ? null
        : itens.reduce((a, b) =>
            (a['quantidade'] as int) > (b['quantidade'] as int) ? a : b);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TRYNT GROUP',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: kGoldPdf,
                      letterSpacing: 3,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Recebimento de Estoque',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: kGrayPdf,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'RELATÓRIO DE RECEBIMENTO',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: kGrayPdf,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    data,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: kDarkPdf,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(color: kGoldPdf, thickness: 0.5),
          pw.SizedBox(height: 16),

          // Nome do recebimento
          pw.Text(
            nomeRecebimento,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: kDarkPdf,
            ),
          ),
          pw.SizedBox(height: 16),

          // Estatísticas
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: kLightPdf,
              border: pw.Border(
                left: pw.BorderSide(color: kGoldPdf, width: 3),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statItem('TOTAL DE CAIXAS', '$totalCaixas cx'),
                _statItem('PRODUTOS DISTINTOS', '${itens.length}'),
                if (produtoMaior != null)
                  _statItem('MAIOR VOLUME',
                      '${produtoMaior['quantidade']} cx\n${_truncar(produtoMaior['nome'], 20)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Tabela de produtos
          pw.Text(
            'PRODUTOS RECEBIDOS',
            style: pw.TextStyle(
              fontSize: 8,
              color: kGrayPdf,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder(
              bottom: pw.BorderSide(color: kGoldPdf, width: 0.5),
              horizontalInside:
                  pw.BorderSide(color: PdfColors.grey300, width: 0.3),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              // Header da tabela
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kLightPdf),
                children: [
                  _tableHeader('PRODUTO'),
                  _tableHeader('DUN-14'),
                  _tableHeader('QTD'),
                ],
              ),
              // Linhas de produtos
              ...itens.map(
                (item) => pw.TableRow(
                  children: [
                    _tableCell(item['nome']),
                    _tableCell(item['dun14']),
                    _tableCellBold('${item['quantidade']} cx'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Rodapé
          pw.Divider(color: PdfColors.grey300, thickness: 0.3),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Gerado pelo app Trynt Estoque',
                style: pw.TextStyle(fontSize: 7, color: kGrayPdf),
              ),
              pw.Text(
                data,
                style: pw.TextStyle(fontSize: 7, color: kGrayPdf),
              ),
            ],
          ),
        ],
      ),
    );

    await _compartilhar(context, pdf, nomeRecebimento);
  }

  // PDF geral do histórico com estatísticas
  static Future<void> gerarRelatorioGeral({
    required BuildContext context,
    required List<dynamic> historicos,
    required String periodo,
  }) async {
    final pdf = pw.Document();

    final totalRecebimentos = historicos.length;
    final totalCaixas = historicos.fold<int>(
        0, (sum, h) => sum + (h['total_caixas'] as int));
    final mediaCaixas =
        totalRecebimentos > 0 ? (totalCaixas / totalRecebimentos).round() : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TRYNT GROUP',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: kGoldPdf,
                      letterSpacing: 3,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Recebimento de Estoque',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: kGrayPdf,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'RELATÓRIO GERAL',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: kGrayPdf,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    periodo,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: kDarkPdf,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Divider(color: kGoldPdf, thickness: 0.5),
          pw.SizedBox(height: 16),

          // Estatísticas gerais
          pw.Text(
            'RESUMO DO PERÍODO',
            style: pw.TextStyle(
              fontSize: 8,
              color: kGrayPdf,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: kLightPdf,
              border: pw.Border(
                left: pw.BorderSide(color: kGoldPdf, width: 3),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statItem('RECEBIMENTOS', '$totalRecebimentos'),
                _statItem('TOTAL DE CAIXAS', '$totalCaixas cx'),
                _statItem('MÉDIA POR RECEBIMENTO', '$mediaCaixas cx'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Tabela de recebimentos
          pw.Text(
            'HISTÓRICO DE RECEBIMENTOS',
            style: pw.TextStyle(
              fontSize: 8,
              color: kGrayPdf,
              letterSpacing: 2,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder(
              bottom: pw.BorderSide(color: kGoldPdf, width: 0.5),
              horizontalInside:
                  pw.BorderSide(color: PdfColors.grey300, width: 0.3),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: kLightPdf),
                children: [
                  _tableHeader('RECEBIMENTO'),
                  _tableHeader('DATA'),
                  _tableHeader('PRODUTOS'),
                  _tableHeader('CAIXAS'),
                ],
              ),
              ...historicos.map(
                (h) => pw.TableRow(
                  children: [
                    _tableCell(h['nome']),
                    _tableCell(_formatarData(h['data'])),
                    _tableCell('${h['total_produtos']}'),
                    _tableCellBold('${h['total_caixas']} cx'),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Rodapé
          pw.Divider(color: PdfColors.grey300, thickness: 0.3),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Gerado pelo app Trynt Estoque',
                style: pw.TextStyle(fontSize: 7, color: kGrayPdf),
              ),
              pw.Text(
                periodo,
                style: pw.TextStyle(fontSize: 7, color: kGrayPdf),
              ),
            ],
          ),
        ],
      ),
    );

    await _compartilhar(context, pdf, 'relatorio-geral');
  }

  // Helpers
  static pw.Widget _statItem(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            color: kGrayPdf,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: kGoldPdf,
          ),
        ),
      ],
    );
  }

  static pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: kGrayPdf,
          letterSpacing: 1,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, color: kDarkPdf),
      ),
    );
  }

  static pw.Widget _tableCellBold(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: kGoldPdf,
        ),
      ),
    );
  }

  static String _truncar(String texto, int max) {
    return texto.length > max ? '${texto.substring(0, max)}...' : texto;
  }

  static String _formatarData(String isoDate) {
    final data = DateTime.parse(isoDate);
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  static Future<void> _compartilhar(
      BuildContext context, pw.Document pdf, String nome) async {
    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$nome.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: nome,
    );
  }
}