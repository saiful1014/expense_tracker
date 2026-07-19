import 'package:flutter/material.dart';
import 'package:test_new_things/data/services/database_helper.dart';
import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/domain/repositories/expense_repository.dart';

class ProcessRecurringExpenses {
  final ExpenseRepository repository;

  ProcessRecurringExpenses(this.repository);

  Future<void> call() async {
    try {
      final db = DatabaseHelper.instance;
      final localDb = await db.database;
      final templatesMap = await localDb.query(
        'expenses',
        where: 'is_recurring = 1',
      );
      final templates = templatesMap.map((m) => Expense.fromMap(m)).toList();
      final now = DateTime.now();

      for (final template in templates) {
        if (template.lastProcessed == null) continue;
        
        DateTime nextProcessDate = template.lastProcessed!;
        final interval = template.recurrenceInterval;
        bool hasProcessedNew = false;

        while (true) {
          if (interval == 'weekly') {
            nextProcessDate = nextProcessDate.add(const Duration(days: 7));
          } else if (interval == 'monthly') {
            nextProcessDate = DateTime(
              nextProcessDate.year,
              nextProcessDate.month + 1,
              nextProcessDate.day,
              nextProcessDate.hour,
              nextProcessDate.minute,
            );
          } else if (interval == 'yearly') {
            nextProcessDate = DateTime(
              nextProcessDate.year + 1,
              nextProcessDate.month,
              nextProcessDate.day,
              nextProcessDate.hour,
              nextProcessDate.minute,
            );
          } else {
            break;
          }

          if (nextProcessDate.isAfter(now)) {
            break;
          }

          final newExpense = Expense(
            description: template.description,
            amount: template.amount,
            date: nextProcessDate,
            category: template.category,
            synced: false,
            isRecurring: false,
          );

          final newId = await repository.insertExpense(newExpense);
          try {
            await repository.syncToCloud(newExpense.copyWith(id: newId, synced: false));
            await repository.markAsSynced(newId);
          } catch (_) {}
          
          hasProcessedNew = true;
        }

        if (hasProcessedNew) {
          final updatedTemplate = template.copyWith(
            lastProcessed: now,
            synced: false,
          );
          await DatabaseHelper.instance.updateExpense(updatedTemplate);
          try {
            await repository.syncToCloud(updatedTemplate);
            await repository.markAsSynced(template.id!);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error processing recurring expenses: $e');
    }
  }
}
