import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../finance/portfolio.dart';

class DbHelper {
  DbHelper._();
  static final instance = DbHelper._();
  Future<Database>? _opening;
  Future<Database> get db => _opening ??= _open().catchError((Object e) { _opening = null; throw e; });
  Future<Database> _open() async => openDatabase(join(await getDatabasesPath(), 'amar_taka.db'), version:4, onCreate:create, onUpgrade:upgrade);
  static Future<void> create(Database d, int version) async {
    await d.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, amount_minor INTEGER NOT NULL CHECK(amount_minor > 0), category TEXT NOT NULL, note TEXT NOT NULL DEFAULT "", date TEXT NOT NULL, type TEXT NOT NULL CHECK(type IN ("income","expense")))');
    await d.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL, UNIQUE(name,type))');
    for (final type in TxnType.values) {
      final cats = type == TxnType.income ? ['Salary','Freelance','Business','Gift','Misc'] : ['Bazar','Transport','Bills','Health','Education','Entertainment','Misc'];
      for (final c in cats) { await d.insert('categories', {'name':c,'type':type.name}); }
    }
    await _extras(d);
    if(version>=3) await _finance(d);
    if(version>=4) await _features(d);
  }
  static Future<void> upgrade(Database d, int old, int version) async {
    if (old < 2) {
      // Preserve existing IDs and records; convert taka to integer paisa once.
      await d.execute('ALTER TABLE transactions RENAME TO transactions_v1');
      await d.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, amount_minor INTEGER NOT NULL CHECK(amount_minor > 0), category TEXT NOT NULL, note TEXT NOT NULL DEFAULT "", date TEXT NOT NULL, type TEXT NOT NULL CHECK(type IN ("income","expense")))');
      await d.execute('INSERT INTO transactions SELECT id, CAST(ROUND(amount * 100) AS INTEGER), category, COALESCE(note,""), date, type FROM transactions_v1');
      await d.execute('DROP TABLE transactions_v1');
      await _extras(d);
    }
    if (old < 3 && version >= 3) await _finance(d);
    if (old < 4 && version >= 4) await _features(d);
  }
  static Future<void> _features(Database d) async {
    await d.execute('ALTER TABLE transactions ADD COLUMN account_id INTEGER');
    await d.execute("ALTER TABLE transactions ADD COLUMN receipt TEXT NOT NULL DEFAULT ''");
    await d.execute("ALTER TABLE goals ADD COLUMN deadline TEXT NOT NULL DEFAULT ''");
    await d.execute("ALTER TABLE goals ADD COLUMN plan_start TEXT NOT NULL DEFAULT ''");
    await d.execute('ALTER TABLE goals ADD COLUMN plan_saved INTEGER NOT NULL DEFAULT 0');
    await d.execute('CREATE TABLE loan_payments(id INTEGER PRIMARY KEY AUTOINCREMENT,loan_id INTEGER NOT NULL,amount_minor INTEGER NOT NULL CHECK(amount_minor>0),date TEXT NOT NULL,note TEXT NOT NULL)');
    await d.execute('CREATE TABLE quick_entries(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,amount_minor INTEGER NOT NULL,category TEXT NOT NULL,type TEXT NOT NULL,note TEXT NOT NULL,account_id INTEGER)');
    await d.execute('CREATE TABLE recurring(id INTEGER PRIMARY KEY AUTOINCREMENT,title TEXT NOT NULL,amount_minor INTEGER NOT NULL,category TEXT NOT NULL,type TEXT NOT NULL,note TEXT NOT NULL,account_id INTEGER,start TEXT NOT NULL,next_date TEXT NOT NULL,enabled INTEGER NOT NULL)');
    await d.execute('CREATE INDEX transactions_account ON transactions(account_id)');
  }
  static Future<void> _finance(Database d) async {
    await d.execute('CREATE TABLE holdings(id INTEGER PRIMARY KEY AUTOINCREMENT,kind TEXT NOT NULL,title TEXT NOT NULL,institution TEXT NOT NULL,reference TEXT NOT NULL,subtype TEXT NOT NULL,note TEXT NOT NULL,amount_minor INTEGER NOT NULL CHECK(amount_minor>=0),value_minor INTEGER NOT NULL CHECK(value_minor>=0),rate_bps INTEGER NOT NULL CHECK(rate_bps>=0),months_paid INTEGER NOT NULL CHECK(months_paid>=0),active INTEGER NOT NULL,start TEXT NOT NULL,end TEXT NOT NULL)');
    await d.execute('CREATE TABLE account_movements(id INTEGER PRIMARY KEY AUTOINCREMENT,account_id INTEGER NOT NULL,target_id INTEGER,type TEXT NOT NULL,amount_minor INTEGER NOT NULL CHECK(amount_minor>0),date TEXT NOT NULL,note TEXT NOT NULL)');
    await d.execute('CREATE INDEX movements_account ON account_movements(account_id)');
    await d.execute('CREATE TABLE category_budgets(id INTEGER PRIMARY KEY AUTOINCREMENT,month TEXT NOT NULL,category TEXT NOT NULL,amount_minor INTEGER NOT NULL CHECK(amount_minor>0),UNIQUE(month,category))');
  }
  static Future<void> _extras(Database d) async {
    await d.execute('CREATE INDEX transactions_date ON transactions(date)');
    await d.execute('CREATE TABLE budgets(month TEXT PRIMARY KEY, amount_minor INTEGER NOT NULL CHECK(amount_minor > 0))');
    await d.execute('CREATE TABLE goals(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, target_minor INTEGER NOT NULL CHECK(target_minor > 0), saved_minor INTEGER NOT NULL DEFAULT 0 CHECK(saved_minor >= 0), note TEXT NOT NULL DEFAULT "")');
    await d.execute('CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT NOT NULL, updated TEXT NOT NULL)');
    await d.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  }
  static Future<void> checkAccounts(DatabaseExecutor d) async {
    final p=Portfolio(holdings:await d.query('holdings'),movements:await d.query('account_movements'),transactions:await d.query('transactions',columns:['account_id','type','amount_minor']));
    final ids=p.holdings.where(isAccount).map((r)=>r['id']).toSet();
    if(p.transactions.any((t)=>t['account_id']!=null && !ids.contains(t['account_id']))) throw const FormatException('অ্যাকাউন্ট পাওয়া যায়নি।');
    if(p.holdings.where(isAccount).any((a)=>p.balance(a)<0 || p.balance(a)>maxMinor)) throw const FormatException('অ্যাকাউন্টে যথেষ্ট টাকা নেই অথবা ব্যালেন্স সীমা ছাড়িয়েছে।');
  }
  static Future<void> writeTransaction(DatabaseExecutor d,Txn t) async {
    if(t.amountMinor<=0 || t.amountMinor>maxMinor) throw const FormatException('সঠিক পরিমাণ দিন।');
    if(t.id==null) {await d.insert('transactions',t.toMap()..remove('id'));}
    else {final changed=await d.update('transactions',t.toMap()..remove('id'),where:'id=?',whereArgs:[t.id]);if(changed!=1)throw const FormatException('লেনদেনটি আর পাওয়া যাচ্ছে না।');}
    await checkAccounts(d);
  }
  Future<void> saveTransaction(Txn t) async => (await db).transaction((d)=>writeTransaction(d,t));
  Future<List<Txn>> getTransactions({DateTime? month}) async {
    final rows = await (await db).query('transactions', columns:['id','amount_minor','category','note','date','type','account_id'], where:month == null ? null : 'date >= ? AND date < ?', whereArgs:month == null ? null : [DateTime(month.year,month.month).toIso8601String(),DateTime(month.year,month.month+1).toIso8601String()], orderBy:'date DESC, id DESC');
    return rows.map(Txn.fromMap).toList();
  }
  Future<void> deleteTransaction(int id) async { await (await db).transaction((d) async {await d.delete('transactions',where:'id = ?',whereArgs:[id]);await checkAccounts(d);}); }
  Future<List<String>> getCategories(TxnType type) async => (await (await db).query('categories',where:'type = ?',whereArgs:[type.name],orderBy:'id')).map((m) => m['name'] as String).toList();
  Future<void> addCategory(String name, TxnType type) async {
    final d = await db;
    if ((await d.query('categories',where:'name = ? AND type = ?',whereArgs:[name,type.name])).isEmpty) { await d.insert('categories',{'name':name,'type':type.name}); }
  }
  Future<int?> budget(DateTime month) async {
    final rows = await (await db).query('budgets',where:'month = ?',whereArgs:[monthKey(month)]);
    return rows.isEmpty ? null : rows.first['amount_minor'] as int;
  }
  Future<void> setBudget(DateTime month,int minor) async { await (await db).insert('budgets',{'month':monthKey(month),'amount_minor':minor},conflictAlgorithm:ConflictAlgorithm.replace); }
  Future<List<Map<String,Object?>>> items(String table) async {
    if (!['goals','notes'].contains(table)) throw ArgumentError('Invalid table');
    return (await db).query(table,orderBy:'id DESC');
  }
  Future<void> saveItem(String table,Map<String,Object?> values,{int? id}) async {
    if (!['goals','notes'].contains(table)) throw ArgumentError('Invalid table');
    final d = await db;
    if (id == null) { await d.insert(table,values); } else { await d.update(table,values,where:'id = ?',whereArgs:[id]); }
  }
  Future<void> deleteItem(String table,int id) async {
    if (!['goals','notes'].contains(table)) throw ArgumentError('Invalid table');
    await (await db).delete(table,where:'id = ?',whereArgs:[id]);
  }
  Future<String?> setting(String key) async {
    final rows = await (await db).query('settings',where:'key = ?',whereArgs:[key]);
    return rows.isEmpty ? null : rows.first['value'] as String;
  }
  Future<void> setSetting(String key,String value) async { await (await db).insert('settings',{'key':key,'value':value},conflictAlgorithm:ConflictAlgorithm.replace); }
}
