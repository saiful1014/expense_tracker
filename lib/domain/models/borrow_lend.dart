import 'dart:convert';

class Repayment {
  final double amount;
  final DateTime date;

  Repayment({
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Repayment.fromMap(Map<String, dynamic> map) {
    return Repayment(
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }
}

class BorrowLend {
  final int? id;
  final String personName;
  final double amount;
  final DateTime date;
  final String type; // 'borrow' (you owe them) or 'lend' (they owe you)
  final String? description;
  final bool completed; // Whether the transaction is completed
  final bool synced; // Whether the transaction has been synced to cloud
  final List<Repayment> repayments;
  final DateTime? dueDate;

  BorrowLend({
    this.id,
    required this.personName,
    required this.amount,
    required this.date,
    required this.type,
    this.description,
    this.completed = false,
    this.synced = false,
    this.repayments = const [],
    this.dueDate,
  });

  double get paidAmount => repayments.fold(0.0, (sum, r) => sum + r.amount);
  double get remainingAmount => amount - paidAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person_name': personName,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'completed': completed ? 1 : 0,
      'synced': synced ? 1 : 0,
      'repayments': jsonEncode(repayments.map((r) => r.toMap()).toList()),
      'due_date': dueDate?.toIso8601String(),
    };
  }

  factory BorrowLend.fromMap(Map<String, dynamic> map) {
    List<Repayment> reps = const [];
    if (map['repayments'] != null && map['repayments'] is String) {
      try {
        final decoded = jsonDecode(map['repayments'] as String) as List;
        reps = decoded.map((item) => Repayment.fromMap(Map<String, dynamic>.from(item as Map))).toList();
      } catch (e) {
        reps = const [];
      }
    }
    return BorrowLend(
      id: map['id'] as int?,
      personName: map['person_name'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      description: map['description'] as String?,
      completed: (map['completed'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
      repayments: reps,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
    );
  }

  BorrowLend copyWith({
    int? id,
    String? personName,
    double? amount,
    DateTime? date,
    String? type,
    String? description,
    bool? completed,
    bool? synced,
    List<Repayment>? repayments,
    DateTime? dueDate,
  }) {
    return BorrowLend(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      synced: synced ?? this.synced,
      repayments: repayments ?? this.repayments,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
