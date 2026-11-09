import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';
import 'package:test_new_things/ui/core/utils/expense_utils.dart';

class CategoryPieChartCard extends StatelessWidget {
  final Map<String, double> categoryData;

  const CategoryPieChartCard({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double total = categoryData.values.fold(0.0, (sum, val) => sum + val);

    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final chartColors = sortedEntries.map((e) => ExpenseUtils.getCategoryColor(e.key)).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  data: sortedEntries.map((e) => e.value).toList(),
                  colors: chartColors,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Spent',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${total.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
                final color = chartColors[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ExpenseUtils.getCategoryIcon(entry.key),
                          size: 16,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.key,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Text(
                        '\$${entry.value.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;

  _DonutChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = data.fold(0.0, (sum, val) => sum + val);
    if (total == 0.0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    for (int i = 0; i < data.length; i++) {
      if (data[i] <= 0) continue;
      final sweepAngle = (data[i] / total) * 2 * pi;
      if (sweepAngle <= 0.06) {
        startAngle += sweepAngle;
        continue;
      }
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle + 0.03, sweepAngle - 0.06, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
