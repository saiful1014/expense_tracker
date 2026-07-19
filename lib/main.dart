import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:test_new_things/ui/core/routing/app_router.dart';
import 'package:test_new_things/data/services/offline_sync_service.dart';
import 'package:test_new_things/data/services/connectivity_service.dart';
import 'package:test_new_things/data/services/database_helper.dart';
import 'package:test_new_things/data/services/cloud_sync_service.dart';
import 'package:test_new_things/domain/repositories/expense_repository.dart';
import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';
import 'package:test_new_things/data/repositories/expense_repository_impl.dart';
import 'package:test_new_things/data/repositories/borrow_lend_repository_impl.dart';
import 'package:test_new_things/ui/features/expenses/view_models/expense_view_model.dart';
import 'package:test_new_things/domain/usecases/get_expenses.dart';
import 'package:test_new_things/domain/usecases/delete_expense.dart';
import 'package:test_new_things/domain/usecases/process_recurring_expenses.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:test_new_things/data/services/notification_service.dart';

import 'package:test_new_things/ui/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Firebase not configured - app will work in local-only mode
    debugPrint('Firebase initialization failed: $e');
  }
  
  // Initialize timezones and notifications
  tz.initializeTimeZones();
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();
  
  // Initialize offline sync service to listen for connectivity changes
  OfflineSyncService.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ConnectivityService>.value(value: ConnectivityService.instance),
        Provider<DatabaseHelper>.value(value: DatabaseHelper.instance),
        Provider<CloudSyncService>(create: (_) => CloudSyncService()),
        Provider<ExpenseRepository>(create: (_) => ExpenseRepositoryImpl()),
        Provider<BorrowLendRepository>(create: (_) => BorrowLendRepositoryImpl()),
        ChangeNotifierProvider<ExpenseViewModel>(
          create: (context) {
            final repo = context.read<ExpenseRepository>();
            final cloud = context.read<CloudSyncService>();
            final connectivity = context.read<ConnectivityService>();
            return ExpenseViewModel(
              repository: repo,
              getExpenses: GetExpenses(repo),
              deleteExpense: DeleteExpense(
                repository: repo,
                connectivity: connectivity,
                cloudSync: cloud,
              ),
              processRecurringExpenses: ProcessRecurringExpenses(repo),
              cloudSync: cloud,
            );
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Daily Expenses',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
      ),
    );
  }
}
