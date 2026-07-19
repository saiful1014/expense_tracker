import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:test_new_things/domain/models/expense.dart';

class PdfGenerator {
  static Future<void> generateAndShareExpenseReport({
    required List<Expense> expenses,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    // Sort expenses chronologically (newest first)
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate overall stats
    final totalSpent = expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
    final count = expenses.length;
    final avgSpent = count > 0 ? totalSpent / count : 0.0;

    // Calculate category breakdown
    final Map<String, double> categoryBreakdown = {};
    for (final exp in expenses) {
      categoryBreakdown[exp.category] = (categoryBreakdown[exp.category] ?? 0.0) + exp.amount;
    }
    final sortedCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Formatting helpers
    String formatCurrency(double amount) => '\$${amount.toStringAsFixed(2)}';
    String formatDate(DateTime date) =>
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    // Theme colors
    const primaryColor = PdfColor.fromInt(0xFF1E3A8A); // Slate Blue
    const secondaryColor = PdfColor.fromInt(0xFF3B82F6); // Bright Blue
    const textColor = PdfColor.fromInt(0xFF1F2937); // Dark Slate Grey
    const lightBg = PdfColor.fromInt(0xFFF3F4F6); // Off-white/light grey

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.SizedBox(); // Main header is in the body of page 1
          }
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(bottom: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 0.5)),
            ),
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Expense Report',
                  style: pw.TextStyle(color: primaryColor, fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${formatDate(startDate)} - ${formatDate(endDate)}',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                ),
              ],
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated on ${formatDate(DateTime.now())} - Expense Tracker',
                  style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8),
                ),
              ],
            ),
          );
        },
        build: (context) => [
          // Elegant Cover/Main Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EXPENSE REPORT',
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Spending analysis and transaction log',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Text(
                      'FILTERED',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '${formatDate(startDate)} - ${formatDate(endDate)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 2, color: primaryColor),
          pw.SizedBox(height: 16),

          // Overview Metrics Section
          pw.Row(
            children: [
              _buildMetricCard(
                title: 'TOTAL SPENT',
                value: formatCurrency(totalSpent),
                bgColor: const PdfColor.fromInt(0xFFEFF6FF), // Soft Blue
                borderColor: secondaryColor,
                textColor: primaryColor,
              ),
              pw.SizedBox(width: 12),
              _buildMetricCard(
                title: 'TRANSACTIONS',
                value: count.toString(),
                bgColor: lightBg,
                borderColor: PdfColors.grey300,
                textColor: textColor,
              ),
              pw.SizedBox(width: 12),
              _buildMetricCard(
                title: 'DAILY AVERAGE',
                value: formatCurrency(avgSpent),
                bgColor: lightBg,
                borderColor: PdfColors.grey300,
                textColor: textColor,
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Category Breakdown Title
          pw.Text(
            'Spending by Category',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),

          // Category table with visual progress indicators
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: primaryColor),
                children: [
                  _tableHeaderCell('Category'),
                  _tableHeaderCell('Total Spent', alignRight: true),
                  _tableHeaderCell('Percentage', alignRight: true),
                  _tableHeaderCell('Proportion'),
                ],
              ),
              // Category rows
              ...sortedCategories.map((entry) {
                final pct = totalSpent > 0 ? (entry.value / totalSpent) : 0.0;
                return pw.TableRow(
                  children: [
                    _tableCell(entry.key, bold: true),
                    _tableCell(formatCurrency(entry.value), alignRight: true),
                    _tableCell('${(pct * 100).toStringAsFixed(1)}%', alignRight: true),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Container(
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Stack(
                          children: [
                            pw.Container(
                              height: 6,
                              width: 80,
                              decoration: const pw.BoxDecoration(
                                color: PdfColors.grey200,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                              ),
                            ),
                            pw.Container(
                              height: 6,
                              width: 80 * pct,
                              decoration: const pw.BoxDecoration(
                                color: secondaryColor,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 28),

          // Transaction Log Title
          pw.Text(
            'Transaction Logs',
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),

          // Transaction Logs Table
          pw.Table(
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: primaryColor),
                children: [
                  _tableHeaderCell('Date'),
                  _tableHeaderCell('Category'),
                  _tableHeaderCell('Description'),
                  _tableHeaderCell('Amount', alignRight: true),
                ],
              ),
              // Transaction Rows with zebra striping
              ...sortedExpenses.asMap().entries.map((item) {
                final idx = item.key;
                final exp = item.value;
                final isEven = idx % 2 == 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isEven ? PdfColors.white : const PdfColor.fromInt(0xFFFAFAFA),
                  ),
                  children: [
                    _tableCell(formatDate(exp.date)),
                    _tableCell(exp.category),
                    _tableCell(exp.description),
                    _tableCell(formatCurrency(exp.amount), bold: true, alignRight: true),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    // Prompt user to save/share/print the PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'expense_report_${formatDate(startDate).replaceAll('/', '_')}_to_${formatDate(endDate).replaceAll('/', '_')}.pdf',
    );
  }

  static pw.Widget _buildMetricCard({
    required String title,
    required String value,
    required PdfColor bgColor,
    required PdfColor borderColor,
    required PdfColor textColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: borderColor, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _tableHeaderCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Container(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text, {bool bold = false, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Container(
        alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}
