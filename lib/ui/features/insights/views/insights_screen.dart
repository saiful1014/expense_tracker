import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/ui/features/expenses/view_models/expense_view_model.dart';
import 'package:test_new_things/ui/features/insights/views/widgets/category_pie_chart_card.dart';
import 'package:test_new_things/ui/features/insights/views/widgets/monthly_bar_chart_card.dart';
import 'package:test_new_things/ui/core/utils/pdf_generator.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ExpenseViewModel>().loadExpenses();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDateRange(BuildContext context, ExpenseViewModel viewModel) async {
    final startPicked = await showDatePicker(
      context: context,
      initialDate: viewModel.startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select start date',
    );

    if (startPicked == null) return;
    if (!context.mounted) return;

    final endPicked = await showDatePicker(
      context: context,
      initialDate: viewModel.endDate ?? startPicked,
      firstDate: startPicked,
      lastDate: DateTime.now(),
      helpText: 'Select end date',
    );

    if (endPicked != null && context.mounted) {
      await viewModel.setDateRange(
        DateTime(startPicked.year, startPicked.month, startPicked.day),
        DateTime(endPicked.year, endPicked.month, endPicked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ExpenseViewModel>(
      builder: (context, viewModel, child) {
        final categoryData = viewModel.getCategoryBreakdown();
        final monthlyData = viewModel.getMonthlyTrends();
        final isFiltered = viewModel.startDate != null && viewModel.endDate != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Spending Insights',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Download PDF Report',
                onPressed: () async {
                  if (viewModel.startDate == null || viewModel.endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a date range first to download the PDF report.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    if (context.mounted) {
                      _selectDateRange(context, viewModel);
                    }
                  } else {
                    try {
                      await PdfGenerator.generateAndShareExpenseReport(
                        expenses: viewModel.expenses,
                        startDate: viewModel.startDate!,
                        endDate: viewModel.endDate!,
                      );
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to generate PDF: $e'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.date_range_outlined),
                tooltip: 'Filter by date range',
                onPressed: () => _selectDateRange(context, viewModel),
              ),
              if (isFiltered)
                IconButton(
                  icon: const Icon(Icons.filter_alt_off_outlined),
                  tooltip: 'Clear date filter',
                  onPressed: () => viewModel.clearDateFilter(),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isFiltered)
                Container(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Showing: ${_formatDate(viewModel.startDate!)} - ${_formatDate(viewModel.endDate!)}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => viewModel.clearDateFilter(),
                        child: Text(
                          'Clear Filter',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Previous month',
                        onPressed: () => viewModel.goToPreviousMonth(),
                      ),
                      Text(
                        viewModel.selectedMonthLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Next month',
                        onPressed: viewModel.canGoToNextMonth
                            ? () => viewModel.goToNextMonth()
                            : null,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: categoryData.isEmpty && monthlyData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 80,
                              color: (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight).withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions for this period',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try selecting a wider date range.',
                              style: GoogleFonts.inter(
                                color: (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight).withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (categoryData.isNotEmpty) ...[
                              _buildSectionHeader(context, 'Category Breakdown'),
                              const SizedBox(height: 12),
                              CategoryPieChartCard(categoryData: categoryData),
                              const SizedBox(height: 24),
                            ],
                            if (monthlyData.isNotEmpty) ...[
                              _buildSectionHeader(context, 'Monthly Trends'),
                              const SizedBox(height: 12),
                              MonthlyBarChartCard(monthlyData: monthlyData),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
