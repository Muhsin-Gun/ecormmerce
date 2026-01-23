import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class InvoiceGenerator {
  static Future<File> generateInvoice(Map<String, dynamic> order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('PROMARKET INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                  pw.Text('Order ID: ${order['id']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}'),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('Customer: ${order['userName'] ?? 'Valued Customer'}'),
              pw.Text('Contact: ${order['userEmail'] ?? 'N/A'}'),
              pw.SizedBox(height: 10),
              pw.Text('Order Date: ${order['createdAt'] ?? 'N/A'}'),
              pw.SizedBox(height: 30),
              
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Item', 'Quantity', 'Price', 'Total'],
                  ...((order['items'] as List?) ?? []).map((item) => [
                    item['productName'] ?? 'Item',
                    item['quantity']?.toString() ?? '1',
                    'KES ${item['price'] ?? '0'}',
                    'KES ${(item['price'] ?? 0) * (item['quantity'] ?? 1)}',
                  ]),
                ],
              ),
              
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Subtotal: KES ${order['totalAmount'] ?? '0'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Delivery: KES 0.00'),
                      pw.Divider(),
                      pw.Text('TOTAL: KES ${order['totalAmount'] ?? '0'}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // For web and mobile, printing is more reliable
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "invoice_${order['id']}.pdf",
    );

    // Legacy return for compatibility (should be avoided on web)
    if (kIsWeb) return File(''); 
    
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/invoice_${order['id']}.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
