import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PdfExportService {
  Future<pw.Document> generateReport({
    required List<Map<String, dynamic>> incomes,
    required List<Map<String, dynamic>> expenses,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text("Rapport Financier")),
              pw.SizedBox(height: 20),
              pw.Text("Revenus:"),
              pw.Bullet(text: "Total Revenus: ${incomes.length}"),
              pw.SizedBox(height: 10),
              pw.Text("Dépenses:"),
              pw.Bullet(text: "Total Dépenses: ${expenses.length}"),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
