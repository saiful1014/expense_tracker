import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

class MonthlyBarChartCard extends StatelessWidget {
  final Map<String, double> monthlyData;

  const MonthlyBarChartCard({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxAmount = monthlyData.values.fold(0.0, max);
    final primaryGradient = AppTheme.getPrimaryGradient(isDark);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true, // Show newest months first on the right side
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthlyData.entries.map((entry) {
                    final heightFactor = maxAmount > 0 ? (entry.value / maxAmount) : 0.0;
                    return Container(
                      width: 65,
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '\$${entry.value.toStringAsFixed(0)}',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 130 * heightFactor,
                            width: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: primaryGradient,
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryGradient[0].withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
