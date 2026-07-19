class Expense {
  final int? id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final bool synced; // Whether the expense has been synced to cloud
  final bool isRecurring;
  final String? recurrenceInterval; // 'weekly', 'monthly', 'yearly'
  final DateTime? lastProcessed;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.synced = false,
    this.isRecurring = false,
    this.recurrenceInterval,
    this.lastProcessed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'synced': synced ? 1 : 0,
      'is_recurring': isRecurring ? 1 : 0,
      'recurrence_interval': recurrenceInterval,
      'last_processed': lastProcessed?.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      synced: (map['synced'] as int? ?? 0) == 1,
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      recurrenceInterval: map['recurrence_interval'] as String?,
      lastProcessed: map['last_processed'] != null
          ? DateTime.parse(map['last_processed'] as String)
          : null,
    );
  }

  Expense copyWith({
    int? id,
    String? description,
    double? amount,
    DateTime? date,
    String? category,
    bool? synced,
    bool? isRecurring,
    String? recurrenceInterval,
    DateTime? lastProcessed,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      synced: synced ?? this.synced,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      lastProcessed: lastProcessed ?? this.lastProcessed,
    );
  }
}


