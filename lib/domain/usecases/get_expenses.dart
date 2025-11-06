import '../../models/expense.dart';
import '../repositories/expense_repository.dart';

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

