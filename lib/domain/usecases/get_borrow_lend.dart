import 'package:test_new_things/domain/models/borrow_lend.dart';
import 'package:test_new_things/domain/repositories/borrow_lend_repository.dart';

class GetBorrowLend {
  final BorrowLendRepository repository;

  GetBorrowLend(this.repository);

  Future<List<BorrowLend>> callByType(String type) async {
    return await repository.getBorrowLendByType(type);
  }

  Future<List<BorrowLend>> callCompleted() async {
    return await repository.getCompletedBorrowLend();
  }
}

