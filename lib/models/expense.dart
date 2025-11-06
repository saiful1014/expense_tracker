class Expense {
  final int? id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final bool synced; // Whether the expense has been synced to cloud

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'synced': synced ? 1 : 0,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      description: map['description'] as String,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  Expense copyWith({
    int? id,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    bool? synced,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      synced: synced ?? this.synced,
    );
  }
}


