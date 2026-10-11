enum TxnType { income, expense }

class Transaction {
  final int? id;
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final TxnType type;

  Transaction({
    this.id,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
        'type': type.name,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as int?,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        note: map['note'] as String? ?? '',
        date: DateTime.parse(map['date'] as String),
        type: TxnType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => TxnType.expense,
        ),
      );
}
