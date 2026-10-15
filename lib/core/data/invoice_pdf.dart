import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice.dart';
import '../models/service_history.dart';

// Bundled OFL font; no network fonts, Storage, or upload.
Future<Uint8List> buildInvoicePdf(Invoice invoice) async {
  final d = invoice.data;
  final font = pw.Font.ttf(
    await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
  );
  final pdf = pw.Document(
    theme: pw.ThemeData.withFont(base: font, bold: font),
  );
  pdf.addPage(
    pw.MultiPage(
      build: (_) => [
        pw.Header(level: 0, text: 'BengkelKu - ${invoice.text('invoiceNo')}'),
        pw.Text('SO: ${invoice.id} | ${invoice.text('vehiclePlate')}'),
        pw.Text('Terbit: ${historyDate(invoice.date('createdAt'))}'),
        pw.Text(
          'Status: ${invoice.text('status')} | ${invoice.text('method')}',
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          '${invoice.text('serviceName')}: ${rupiah(invoice.number('laborPrice'))}',
        ),
        for (final p in (d['parts'] as List).cast<Map>())
          pw.Text(
            '${p['name']} | ${p['kind']} | ${p['quantity']} x ${rupiah(p['sellPrice'] as int)}',
          ),
        pw.Divider(),
        for (final pair in [
          ('Subtotal', 'subtotal'),
          ('Diskon', 'discount'),
          ('Biaya tambahan', 'fee'),
          ('Total', 'grandTotal'),
          ('Dibayar (net)', 'paidAmount'),
          ('Kembalian kumulatif', 'change'),
          ('Sisa', 'due'),
        ])
          pw.Text('${pair.$1}: ${rupiah(invoice.number(pair.$2))}'),
        pw.Text('Lunas: ${historyDate(invoice.date('paidAt'))}'),
        pw.Text('Petugas: ${invoice.text('recordedBy')}'),
        pw.Text('Catatan: ${invoice.text('notes')}'),
        pw.SizedBox(height: 16),
        pw.Text(
          'Pembayaran tunai/transfer diverifikasi manual. Simpan bukti pembayaran.',
        ),
      ],
    ),
  );
  return pdf.save();
}
