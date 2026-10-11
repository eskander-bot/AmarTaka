enum TxnType { income, expense }
class Txn {
  final int? id;
  final int amountMinor;
  final String category;
  final String note;
  final DateTime date;
  final TxnType type;
  const Txn({this.id, required this.amountMinor, required this.category, this.note = '', required this.date, required this.type});
  Map<String, Object?> toMap() => {'id':id, 'amount_minor':amountMinor, 'category':category, 'note':note, 'date':date.toIso8601String(), 'type':type.name};
  factory Txn.fromMap(Map<String, Object?> m) => Txn(id:m['id'] as int?, amountMinor:m['amount_minor'] as int, category:m['category'] as String, note:m['note'] as String? ?? '', date:DateTime.parse(m['date'] as String), type:TxnType.values.byName(m['type'] as String));
}
