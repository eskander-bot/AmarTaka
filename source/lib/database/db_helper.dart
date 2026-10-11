import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';

class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      join(dir, 'amar_taka.db'),
      version: 1,
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL, category TEXT NOT NULL, note TEXT, date TEXT NOT NULL, type TEXT NOT NULL)',
        );
        await database.execute(
          'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL)',
        );
        const expenseCats = [
          'Bazar', 'Transport', 'Bills', 'Health', 'Education', 'Entertainment', 'Misc',
        ];
        const incomeCats = [
          'Salary', 'Freelance', 'Business', 'Gift', 'Misc',
        ];
        for (final c in expenseCats) {
          await database.insert('categories', {'name': c, 'type': 'expense'});
        }
        for (final c in incomeCats) {
          await database.insert('categories', {'name': c, 'type': 'income'});
        }
      },
    );
  }

  Future<int> insertTransaction(Transaction t) async {
    final d = await db;
    return d.insert('transactions', t.toMap());
  }

  Future<List<Transaction>> getTransactions({int? limit}) async {
    final d = await db;
    final rows = await d.query('transactions', orderBy: 'date DESC', limit: limit);
    return rows.map(Transaction.fromMap).toList();
  }

  Future<int> deleteTransaction(int id) async {
    final d = await db;
    return d.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getMonthTotals() async {
    final d = await db;
    final now = DateTime.now();
    final rows = await d.query('transactions');
    double income = 0, expense = 0;
    for (final r in rows) {
      final date = DateTime.parse(r['date'] as String);
      if (date.year != now.year || date.month != now.month) continue;
      final amt = (r['amount'] as num).toDouble();
      if (r['type'] == 'income') {
        income += amt;
      } else {
        expense += amt;
      }
    }
    return {'income': income, 'expense': expense};
  }

  Future<List<String>> getCategories(TxnType type) async {
    final d = await db;
    final rows = await d.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type.name],
    );
    return rows.map((r) => r['name'] as String).toList();
  }
}
