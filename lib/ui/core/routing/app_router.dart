import 'package:go_router/go_router.dart';
import 'package:test_new_things/ui/features/splash/views/splash_screen.dart';
import 'package:test_new_things/ui/features/home/views/home_screen.dart';
import 'package:test_new_things/ui/features/expenses/views/add_expense_screen.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/deferred_borrow_lend.dart';
import 'package:test_new_things/ui/features/borrow_lend/views/add_borrow_lend_screen.dart';
import 'package:test_new_things/ui/features/sync/views/sync_setup_screen.dart';
import 'package:test_new_things/ui/features/insights/views/insights_screen.dart';
import 'package:test_new_things/ui/features/expenses/views/manage_categories_screen.dart';
import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/domain/models/borrow_lend.dart';

/// Application route configuration using GoRouter.
final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) {
        final expense = state.extra as Expense?;
        return AddExpenseScreen(expense: expense);
      },
    ),
    GoRoute(
      path: '/borrow-lend',
      builder: (context, state) => const DeferredBorrowLend(),
    ),
    GoRoute(
      path: '/add-borrow-lend',
      builder: (context, state) {
        final transaction = state.extra as BorrowLend?;
        return AddBorrowLendScreen(transaction: transaction);
      },
    ),
    GoRoute(
      path: '/sync-setup',
      builder: (context, state) => const SyncSetupScreen(),
    ),
    GoRoute(
      path: '/insights',
      builder: (context, state) => const InsightsScreen(),
    ),
    GoRoute(
      path: '/manage-categories',
      builder: (context, state) => const ManageCategoriesScreen(),
    ),
  ],
);
