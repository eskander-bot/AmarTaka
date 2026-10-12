import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:amartaka/database/db_helper.dart';
import 'package:amartaka/finance/portfolio.dart';
import 'package:amartaka/services/backup.dart';

Record holding(String kind,{int amount=100000,int value=0,int paid=0,int rate=1000})=>{'kind':kind,'title':'Test $kind','institution':'Bank','reference':'','subtype':'','note':'','amount_minor':amount,'value_minor':value,'rate_bps':rate,'months_paid':paid,'active':1,'start':'2026-01-01T00:00:00.000','end':'2027-01-01T00:00:00.000'};
Record movement(int source,{String type='transfer',int? target,int amount=25000})=>{'account_id':source,'target_id':target,'type':type,'amount_minor':amount,'date':'2026-06-01T00:00:00.000','note':''};
void main(){
  sqfliteFfiInit();
  late Database db;late PortfolioStore store;
  setUp(()async{db=await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);await DbHelper.create(db,3);store=PortfolioStore(db);});
  tearDown(()async=>db.close());
  test('Transfers conserve net worth and failed withdrawals change neither account',()async{
    final a=await store.save(holding('cash')),b=await store.save(holding('bank',amount:50000));
    await store.move(movement(a,target:b));final p=await store.read();
    expect(p.total('cash'),75000);expect(p.total('bank'),75000);expect(p.netWorth,150000);
    await expectLater(store.move(movement(a,type:'withdraw',amount:80000)),throwsFormatException);
    await expectLater(store.move(movement(a,target:a)),throwsFormatException);
    expect((await store.read()).movements.length,1);expect(await db.query('transactions'),isEmpty);
    await expectLater(store.delete(a),throwsFormatException);
  });
  test('Loans repay partially then fully, cannot overpay, debt reduces net worth',()async{
    final id=await store.save(holding('borrowed'));await store.repay(id,30000);
    expect((await store.read()).netWorth,-70000);
    await expectLater(store.repay(id,70001),throwsFormatException);
    await store.repay(id,70000);expect((await store.read()).liabilities,0);
  });
  test('DPS only counts recorded installments and prevents an extra installment',()async{
    final id=await store.save(holding('dps',paid:11,rate:0));
    expect((await store.read()).total('dps'),1100000);
    await store.payInstallment(id);expect((await store.read()).total('dps'),1200000);
    await expectLater(store.payInstallment(id),throwsFormatException);
    expect(FinanceMath.dpsEstimate(100000,0,12),1200000);
    expect(FinanceMath.dpsEstimate(100000,1200,1),101000);
  });
  test('Interest is bounded by start and maturity, invalid dates and rates rejected',(){
    final r=holding('fdr');expect(FinanceMath.accrued(r,DateTime(2025)),100000);
    expect(FinanceMath.accrued(r,DateTime(2030)),110000);
    expect(FinanceMath.maturity(r),110000);
    expect(()=>FinanceValidation.holding({...r,'end':r['start']}),throwsFormatException);
    expect(()=>FinanceValidation.holding({...r,'rate_bps':10001}),throwsFormatException);
    expect(()=>FinanceValidation.holding({...r,'start':'2026-02-31T00:00:00.000'}),throwsFormatException);
    expect(FinanceMath.roi(holding('investment',value:120000)),20);
  });
  test('Schema 2 migrates without losing transactions and old backups stay readable',()async{
    await db.close();db=await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);await DbHelper.create(db,2);
    await db.insert('transactions',{'amount_minor':12345,'category':'Bazar','note':'keep','date':'2026-06-01T00:00:00.000','type':'expense'});
    await DbHelper.upgrade(db,2,3);expect((await db.query('transactions')).single['amount_minor'],12345);
    expect(await db.query('holdings'),isEmpty);
    final root=jsonDecode(await Backup.exportJson(database:db)) as Map;root['schema']=2;root.remove('holdings');root.remove('account_movements');root.remove('category_budgets');
    expect(Backup.validate(jsonEncode(root))['holdings'],isEmpty);
  });
  test('Full backup round trip retains portfolio, movements and category budgets atomically',()async{
    final a=await store.save(holding('bank')),b=await store.save(holding('cash',amount:0));
    await store.move(movement(a,target:b));await store.save(holding('investment',value:150000));
    await store.saveBudget({'month':'2026-10','category':'Bazar','amount_minor':20000});
    final backup=await Backup.exportJson(database:db);final before=(await store.read()).netWorth;
    await db.delete('account_movements');await db.delete('holdings');await Backup.restore(backup,database:db);
    expect((await store.read()).netWorth,before);expect((await store.budgets(DateTime(2026,10))).single['amount_minor'],20000);
    final bad=jsonDecode(backup) as Map;(bad['account_movements'] as List).first['target_id']=9999;
    await expectLater(Backup.restore(jsonEncode(bad),database:db),throwsFormatException);
    expect((await store.read()).netWorth,before);
  });
}
