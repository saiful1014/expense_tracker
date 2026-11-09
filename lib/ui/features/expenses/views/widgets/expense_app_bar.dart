import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_new_things/ui/features/expenses/view_models/expense_view_model.dart';
import 'package:test_new_things/ui/core/theme/app_theme.dart';

class ExpenseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String Function(DateTime) formatDate;
  final VoidCallback onSyncTap;
  final SyncStatus syncStatus;
  final int unsyncedCount;
  final VoidCallback onBorrowLend;
  final VoidCallback onDateRange;
  final VoidCallback onInsights;
  final VoidCallback onManageCategories;
  final VoidCallback? onClearFilter;

  const ExpenseAppBar({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.formatDate,
    required this.onSyncTap,
    required this.syncStatus,
    required this.unsyncedCount,
    required this.onBorrowLend,
    required this.onDateRange,
    required this.onInsights,
    required this.onManageCategories,
    this.onClearFilter,
  });

  Widget _buildSyncIcon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textCol = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    switch (syncStatus) {
      case SyncStatus.syncing:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        );
      case SyncStatus.synced:
        return Icon(Icons.cloud_done_outlined, color: isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight);
      case SyncStatus.pendingSync:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.cloud_upload_outlined, color: Color(0xFFF59E0B)),
            if (unsyncedCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Center(
                    child: Text(
                      '$unsyncedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      case SyncStatus.notSignedIn:
        return Icon(Icons.cloud_off_outlined, color: textCol.withValues(alpha: 0.4));
      case SyncStatus.error:
        return const Icon(Icons.sync_problem_outlined, color: Color(0xFFEF4444));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Expenses',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          if (startDate != null && endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                startDate == endDate
                    ? formatDate(startDate!)
                    : '${formatDate(startDate!)} - ${formatDate(endDate!)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                ),
              ),
            ),
        ],
      ),
      actions: [
        InkWell(
          onTap: onSyncTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Tooltip(
              message: 'Cloud Sync Status',
              child: Center(child: _buildSyncIcon(context)),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.insights_outlined),
          tooltip: 'Spending Insights',
          onPressed: onInsights,
        ),
        IconButton(
          icon: const Icon(Icons.wallet_outlined),
          tooltip: 'Borrow & Lend',
          onPressed: onBorrowLend,
        ),
        IconButton(
          icon: const Icon(Icons.date_range_outlined),
          tooltip: 'Filter by date range',
          onPressed: onDateRange,
        ),
        IconButton(
          icon: const Icon(Icons.category_outlined),
          tooltip: 'Manage Categories',
          onPressed: onManageCategories,
        ),
        if (onClearFilter != null)
          IconButton(
            icon: const Icon(Icons.filter_alt_off_outlined),
            tooltip: 'Show all expenses',
            onPressed: onClearFilter,
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
