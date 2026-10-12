import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../utils/formatters.dart';

typedef Record = Map<String,Object?>;
const financeKinds = ['cash','bank','dps','fdr','certificate','investment','lent','borrowed'];
const financeLabels = {'cash':'ক্যাশ ও ওয়ালেট','bank':'ব্যাংক অ্যাকাউন্ট','dps':'DPS','fdr':'FDR','certificate':'সঞ্চয়পত্র','investment':'বিনিয়োগ','lent':'ধার দিয়েছি','borrowed':'ধার নিয়েছি'};
int number(Record r,String key) => (r[key] as int?) ?? 0;
String field(Record r,String key) => (r[key] as String?) ?? '';
bool isAccount(Record r) => ['cash','bank'].contains(r['kind']);
bool isLoan(Record r) => ['lent','borrowed'].contains(r['kind']);
bool isSaving(Record r) => ['dps','fdr','certificate'].contains(r['kind']);

class FinanceValidation {
  static int integer(Object? value,{int min=0,int max=maxMinor}) {
    if (value is! int || value<min || value>max) throw const FormatException('সংখ্যা বা টাকার পরিমাণ সঠিক নয়।');
    return value;
  }
  static String text(Object? value,{int max=200,bool empty=false}) {
    if (value is! String || value.length>max || (!empty && value.trim().isEmpty)) throw const FormatException('লেখা সঠিক নয়।');
    return value.trim();
  }
  static String date(Object? value) {
    final s=text(value,max:40),d=DateTime.tryParse(s);
    if (d==null || d.isUtc || d.year<1900 || d.year>2200 || !RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(s) || !d.toIso8601String().startsWith(s.substring(0,10))) throw const FormatException('তারিখ সঠিক নয়।');
    return d.toIso8601String();
  }
  static Record holding(Record r,{bool withId=false}) {
    final kind=text(r['kind']);
    if (!financeKinds.contains(kind)) throw const FormatException('অজানা হিসাব।');
    final out=<String,Object?>{
      if(withId) 'id':integer(r['id'],min:1),
      'kind':kind,'title':text(r['title'],max:100),
      'institution':text(r['institution'],max:100,empty:true),'reference':text(r['reference'],max:100,empty:true),
      'subtype':text(r['subtype'],max:100,empty:true),'note':text(r['note'],max:2000,empty:true),
      'amount_minor':integer(r['amount_minor'],min:['cash','bank'].contains(kind)?0:1),
      'value_minor':integer(r['value_minor']),'rate_bps':integer(r['rate_bps'],max:10000),
      'months_paid':integer(r['months_paid'],max:600),'active':integer(r['active'],max:1),
      'start':date(r['start']),'end':date(r['end']),
    };
    if (isSaving(out) && !DateTime.parse(field(out,'end')).isAfter(DateTime.parse(field(out,'start')))) throw const FormatException('মেয়াদ শেষের তারিখ শুরুর পরে দিন।');
    if (isLoan(out) && number(out,'value_minor')>number(out,'amount_minor')) throw const FormatException('মূল টাকার বেশি পরিশোধ হতে পারে না।');
    if (kind=='dps' && (FinanceMath.termMonths(out)<1 || FinanceMath.termMonths(out)>600 || number(out,'months_paid')>FinanceMath.termMonths(out))) throw const FormatException('DPS-এর মেয়াদ বা কিস্তির সংখ্যা সঠিক নয়।');
    return out;
  }
  static Record movement(Record r,{bool withId=false}) {
    final type=text(r['type']);
    if (!['deposit','withdraw','transfer'].contains(type)) throw const FormatException('অজানা লেনদেন।');
    final source=integer(r['account_id'],min:1);
    final target=type=='transfer'?integer(r['target_id'],min:1):null;
    if (source==target) throw const FormatException('দুটি আলাদা অ্যাকাউন্ট দিন।');
    return {if(withId)'id':integer(r['id'],min:1),'account_id':source,'target_id':target,'type':type,'amount_minor':integer(r['amount_minor'],min:1),'date':date(r['date']),'note':text(r['note'],max:2000,empty:true)};
  }
  static Record budget(Record r,{bool withId=false}) {
    final month=text(r['month']);
    if(!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month)) throw const FormatException('মাস সঠিক নয়।');
    return {if(withId)'id':integer(r['id'],min:1),'month':month,'category':text(r['category'],max:60),'amount_minor':integer(r['amount_minor'],min:1)};
  }
}

class FinanceMath {
  static int termMonths(Record r) {
    final a=DateTime.parse(field(r,'start')),b=DateTime.parse(field(r,'end'));
    return (b.year-a.year)*12+b.month-a.month;
  }
  static int principal(Record r) => r['kind']=='dps'?number(r,'amount_minor')*number(r,'months_paid'):number(r,'amount_minor');
  // Estimate only: monthly deposits at the beginning of each month.
  static int dpsEstimate(int deposit,int rateBps,int months) {
    if(months<=0)return 0;
    if(rateBps==0)return deposit*months;
    final rate=rateBps/120000;
    return (deposit*((math.pow(1+rate,months)-1)/rate)*(1+rate)).round();
  }
  static int maturity(Record r) => r['kind']=='dps'?dpsEstimate(number(r,'amount_minor'),number(r,'rate_bps'),termMonths(r)):accrued(r,DateTime.parse(field(r,'end')));
  static int accrued(Record r,DateTime asOf) {
    final start=DateTime.parse(field(r,'start')),end=DateTime.parse(field(r,'end'));
    final date=asOf.isAfter(end)?end:asOf;
    final days=math.max(0,DateTime.utc(date.year,date.month,date.day).difference(DateTime.utc(start.year,start.month,start.day)).inDays);
    return number(r,'amount_minor')+(number(r,'amount_minor')*number(r,'rate_bps')*days/3650000).round();
  }
  static double roi(Record r) => number(r,'amount_minor')==0?0:100*(number(r,'value_minor')-number(r,'amount_minor'))/number(r,'amount_minor');
  static double savingsRate(int income,int expense) => income==0?0:100*(income-expense)/income;
  static int health({required int income,required int expense,required int liquid,required int debt,required int assets}) {
    final savings=income<=0?0.0:((income-expense)/income).clamp(0.0,1.0);
    final buffer=expense<=0?0.0:(liquid/(expense*6)).clamp(0.0,1.0);
    final solvency=assets<=0?0.0:(1-debt/assets).clamp(0.0,1.0);
    return (40*savings+35*buffer+25*solvency).round();
  }
}

class Portfolio {
  final List<Record> holdings,movements;
  const Portfolio({this.holdings=const [],this.movements=const []});
  List<Record> ofKind(String kind)=>holdings.where((r)=>r['kind']==kind).toList();
  int balance(Record account) {
    var total=number(account,'amount_minor');
    for(final m in movements) {
      if(m['account_id']==account['id']) total+=m['type']=='deposit'?number(m,'amount_minor'):-number(m,'amount_minor');
      if(m['target_id']==account['id']) total+=number(m,'amount_minor');
    }
    return total;
  }
  int value(Record r) {
    if(isAccount(r))return balance(r);
    if(isLoan(r))return number(r,'amount_minor')-number(r,'value_minor');
    if(r['kind']=='investment')return number(r,'value_minor');
    return number(r,'active')==0?0:FinanceMath.principal(r);
  }
  int total(String kind)=>ofKind(kind).fold(0,(s,r)=>s+value(r));
  int get assets=>holdings.where((r)=>r['kind']!='borrowed').fold(0,(s,r)=>s+value(r));
  int get liabilities=>total('borrowed');
  int get netWorth=>assets-liabilities;
}

class PortfolioStore {
  final Database database;
  PortfolioStore(this.database);
  static Future<PortfolioStore> open() async=>PortfolioStore(await DbHelper.instance.db);
  Future<Portfolio> read() async=>Portfolio(holdings:await database.query('holdings',orderBy:'id DESC'),movements:await database.query('account_movements',orderBy:'date DESC, id DESC'));
  Future<int> save(Record record,{int? id}) async {
    final clean=FinanceValidation.holding(record);
    return database.transaction((txn) async {
      if(id==null)return txn.insert('holdings',clean);
      final old=await txn.query('holdings',where:'id=?',whereArgs:[id]);
      if(old.isEmpty || old.first['kind']!=clean['kind'])throw const FormatException('হিসাবটি পাওয়া যায়নি।');
      if(isAccount(clean)) {
        final moves=await txn.query('account_movements',where:'account_id=? OR target_id=?',whereArgs:[id,id]);
        if(Portfolio(movements:moves).balance({...clean,'id':id})<0)throw const FormatException('ব্যালেন্স শূন্যের নিচে হতে পারে না।');
      }
      await txn.update('holdings',clean,where:'id=?',whereArgs:[id]);return id;
    });
  }
  Future<void> delete(int id) async=>database.transaction((txn) async {
    if((await txn.query('account_movements',where:'account_id=? OR target_id=?',whereArgs:[id,id],limit:1)).isNotEmpty)throw const FormatException('এই অ্যাকাউন্টে লেনদেন আছে। ইতিহাসসহ অ্যাকাউন্ট রাখুন।');
    await txn.delete('holdings',where:'id=?',whereArgs:[id]);
  });
  Future<void> move(Record record) async {
    final m=FinanceValidation.movement(record);
    await database.transaction((txn) async {
      final accounts=await txn.query('holdings',where:'kind IN (?,?)',whereArgs:['cash','bank']);
      if(!accounts.any((a)=>a['id']==m['account_id']) || (m['type']=='transfer' && !accounts.any((a)=>a['id']==m['target_id'])))throw const FormatException('অ্যাকাউন্ট পাওয়া যায়নি।');
      final portfolio=Portfolio(holdings:accounts,movements:await txn.query('account_movements'));
      final source=accounts.firstWhere((a)=>a['id']==m['account_id']);
      if(m['type']!='deposit' && portfolio.balance(source)<number(m,'amount_minor'))throw const FormatException('অ্যাকাউন্টে যথেষ্ট টাকা নেই।');
      if(m['type']=='deposit' && portfolio.balance(source)+number(m,'amount_minor')>maxMinor)throw const FormatException('ব্যালেন্স সীমা ছাড়িয়েছে।');
      if(m['type']=='transfer' && portfolio.balance(accounts.firstWhere((a)=>a['id']==m['target_id']))+number(m,'amount_minor')>maxMinor)throw const FormatException('ব্যালেন্স সীমা ছাড়িয়েছে।');
      await txn.insert('account_movements',m);
    });
  }
  Future<void> repay(int id,int amount) async {
    FinanceValidation.integer(amount,min:1);
    await database.transaction((txn) async {
      final rows=await txn.query('holdings',where:'id=? AND kind IN (?,?)',whereArgs:[id,'lent','borrowed']);
      if(rows.isEmpty)throw const FormatException('ধারের হিসাব পাওয়া যায়নি।');
      final r=rows.first,paid=number(r,'value_minor')+amount;
      if(paid>number(r,'amount_minor'))throw const FormatException('বকেয়ার বেশি টাকা দেওয়া হয়েছে।');
      await txn.update('holdings',{'value_minor':paid},where:'id=?',whereArgs:[id]);
    });
  }
  Future<void> payInstallment(int id) async=>database.transaction((txn) async {
    final rows=await txn.query('holdings',where:'id=? AND kind=?',whereArgs:[id,'dps']);
    if(rows.isEmpty)throw const FormatException('DPS পাওয়া যায়নি।');
    final r=rows.first,count=number(r,'months_paid')+1;
    if(number(r,'active')==0 || count>FinanceMath.termMonths(r))throw const FormatException('আর কিস্তি যোগ করা যাবে না।');
    await txn.update('holdings',{'months_paid':count},where:'id=?',whereArgs:[id]);
  });
  Future<List<Record>> budgets(DateTime month)=>database.query('category_budgets',where:'month=?',whereArgs:[monthKey(month)],orderBy:'category');
  Future<void> saveBudget(Record r) async {
    final clean=FinanceValidation.budget(r);
    await database.insert('category_budgets',clean,conflictAlgorithm:ConflictAlgorithm.replace);
  }
}
