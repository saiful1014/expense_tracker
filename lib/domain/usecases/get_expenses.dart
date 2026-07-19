import 'package:test_new_things/domain/models/expense.dart';
import 'package:test_new_things/domain/repositories/expense_repository.dart';

class GetExpenses {
  final ExpenseRepository repository;

  GetExpenses(this.repository);

  Future<List<Expense>> call({DateTime? startDate, DateTime? endDate}) async {
    if (startDate != null && endDate != null) {
      return await repository.getExpensesByDateRange(startDate, endDate);
    }
    return await repository.getExpenses();
  }
}

