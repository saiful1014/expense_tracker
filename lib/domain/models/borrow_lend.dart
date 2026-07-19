class BorrowLend {
  final int? id;
  final String personName;
  final double amount;
  final DateTime date;
  final String type; // 'borrow' (you owe them) or 'lend' (they owe you)
  final String? description;
  final bool completed; // Whether the transaction is completed
  final bool synced; // Whether the transaction has been synced to cloud

  BorrowLend({
    this.id,
    required this.personName,
    required this.amount,
    required this.date,
    required this.type,
    this.description,
    this.completed = false,
    this.synced = false,
  });

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
    };
  }

  factory BorrowLend.fromMap(Map<String, dynamic> map) {
    return BorrowLend(
      id: map['id'] as int?,
      personName: map['person_name'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      description: map['description'] as String?,
      completed: (map['completed'] as int? ?? 0) == 1,
      synced: (map['synced'] as int? ?? 0) == 1,
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
    );
  }
}

