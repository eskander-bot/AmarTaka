import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:amartaka/database/db_helper.dart';
import 'package:amartaka/models/transaction.dart';
import 'package:amartaka/finance/portfolio.dart';
import 'package:amartaka/services/feature_service.dart';
import 'package:amartaka/services/backup.dart';
import 'portfolio_test.dart' show holding;
void main(){
  sqfliteFfiInit();late Database db;late PortfolioStore store;
  setUp(()async{db=await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);await DbHelper.create(db,4);store=PortfolioStore(db);});
  tearDown(()async=>db.close());
  test('v3 migration preserves records and leaves old transactions unassigned',()async{
    await db.close();db=await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);await DbHelper.create(db,3);
    await db.insert('transactions',{'id':8,'amount_minor':500,'category':'Bazar','note':'old','date':'2026-01-01T00:00:00.000','type':'expense'});
    await DbHelper.upgrade(db,3,4);final row=(await db.query('transactions')).single;expect(row['id'],8);expect(row['account_id'],null);expect(row['receipt'],'');
  });
  test('Linked transaction edits and failed debits are atomic',()async{
    final id=await store.save(holding('cash',amount:10000));
    Txn expense(int amount,{int? tid})=>Txn(id:tid,amountMinor:amount,category:'Bazar',date:DateTime(2026),type:TxnType.expense,accountId:id);
    await db.transaction((d)=>DbHelper.writeTransaction(d,expense(3000)));expect((await store.read()).total('cash'),7000);
    final tid=(await db.query('transactions')).single['id'] as int;
    await db.transaction((d)=>DbHelper.writeTransaction(d,expense(5000,tid:tid)));expect((await store.read()).total('cash'),5000);
    await expectLater(db.transaction((d)=>DbHelper.writeTransaction(d,expense(11000,tid:tid))),throwsFormatException);
    expect((await store.read()).total('cash'),5000);await expectLater(store.delete(id),throwsFormatException);
  });
  test('Deleting funding income cannot leave account negative',()async{
    final id=await store.save(holding('bank',amount:0));
    await db.transaction((d)=>DbHelper.writeTransaction(d,Txn(amountMinor:1000,category:'Salary',date:DateTime(2026),type:TxnType.income,accountId:id)));
    await db.transaction((d)=>DbHelper.writeTransaction(d,Txn(amountMinor:900,category:'Bazar',date:DateTime(2026),type:TxnType.expense,accountId:id)));
    await expectLater(db.transaction((d)async{await d.delete('transactions',where:'type=?',whereArgs:['income']);await DbHelper.checkAccounts(d);}),throwsFormatException);
    expect((await db.query('transactions')).length,2);
  });
  test('Monthly recurrence is idempotent and retains month-end anchor in leap year',()async{
    await db.insert('recurring',{'title':'salary','amount_minor':100,'category':'Salary','type':'income','note':'','account_id':null,'start':'2024-01-31T00:00:00.000','next_date':'2024-01-31T00:00:00.000','enabled':1});
    await FeatureService.postDue(db,now:DateTime(2024,3,31));final rows=await db.query('transactions');
    expect(rows.length,3);expect(rows[1]['date'],'2024-02-29T00:00:00.000');expect(rows[2]['date'],'2024-03-31T00:00:00.000');
    await FeatureService.postDue(db,now:DateTime(2024,3,31));expect((await db.query('transactions')).length,3);
  });
  test('Failed recurring debit keeps cursor and rolls back whole batch',()async{
    final id=await store.save(holding('cash',amount:150));
    await db.insert('recurring',{'title':'bill','amount_minor':100,'category':'Bills','type':'expense','note':'','account_id':id,'start':'2026-01-01T00:00:00.000','next_date':'2026-01-01T00:00:00.000','enabled':1});
    expect(await FeatureService.postDue(db,now:DateTime(2026,2,1)),isNotEmpty);expect(await db.query('transactions'),isEmpty);expect((await store.read()).total('cash'),150);
    expect((await db.query('recurring')).single['next_date'],'2026-01-01T00:00:00.000');
  });
  test('v4 backup retains receipts, templates, plans, repayment history',()async{
    final id=await store.save(holding('borrowed'));await store.repay(id,500,date:DateTime(2026,2,3),note:'partial');
    await db.insert('goals',{'title':'Trip','target_minor':1000,'saved_minor':100,'note':'','deadline':'2027-01-01T00:00:00.000','plan_start':'2026-01-01T00:00:00.000','plan_saved':100});
    await db.insert('quick_entries',{'title':'bus','amount_minor':100,'category':'Transport','type':'expense','note':'','account_id':null});
    await db.insert('recurring',{'title':'salary','amount_minor':100,'category':'Salary','type':'income','note':'','account_id':null,'start':'2027-01-31T00:00:00.000','next_date':'2027-01-31T00:00:00.000','enabled':1});
    const png='iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a1ioAAAAASUVORK5CYII=';
    await db.transaction((d)=>DbHelper.writeTransaction(d,Txn(amountMinor:100,category:'Bazar',date:DateTime(2026),type:TxnType.expense,receipt:png)));
    final backup=await Backup.exportJson(database:db);await Backup.restore(backup,database:db);
    expect((await db.query('transactions')).single['receipt'],png);expect((await db.query('goals')).single['plan_saved'],100);expect((await db.query('quick_entries')).length,1);expect((await db.query('recurring')).length,1);
    final broken=jsonDecode(backup) as Map;broken['loan_payments'][0]['loan_id']=999;
    await expectLater(Backup.restore(jsonEncode(broken),database:db),throwsFormatException);expect((await db.query('loan_payments')).length,1);
    final bad=jsonDecode(backup) as Map;bad['loan_payments'][0]['amount_minor']=501;expect(()=>Backup.validate(jsonEncode(bad)),throwsFormatException);
  });
  test('Savings plans handle completed and overdue goals',(){
    final g=<String,Object?>{'target_minor':10000,'saved_minor':5000,'plan_saved':0,'plan_start':'2026-01-01T00:00:00.000','deadline':'2026-12-31T00:00:00.000'};
    expect(FeatureService.goalPlan(g,now:DateTime(2027)),contains('সময়সীমা শেষ'));
    expect(FeatureService.goalPlan({...g,'saved_minor':10000},now:DateTime(2026,6)),contains('লক্ষ্য পূরণ'));
  });
}
