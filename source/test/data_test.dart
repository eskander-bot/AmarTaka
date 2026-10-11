import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:amartaka/database/db_helper.dart';
import 'package:amartaka/services/backup.dart';
Map<String,Object?> fixture() => {'app':'amar-taka','schema':2,'transactions':[{'id':1,'amount_minor':12550,'category':'Bazar','note':'পরীক্ষা','date':'2026-10-11T00:00:00.000','type':'expense'}],'categories':[{'id':1,'name':'Bazar','type':'expense'},{'id':2,'name':'Salary','type':'income'}],'budgets':[{'month':'2026-10','amount_minor':200000}],'goals':[],'notes':[]};
void main() {
  sqfliteFfiInit();
  test('Version 1 migration preserves IDs and converts to paisa',() async {
    final d = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await d.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY, amount REAL, category TEXT, note TEXT, date TEXT, type TEXT)');
    await d.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY, name TEXT, type TEXT)');
    await d.insert('transactions',{'id':42,'amount':125.50,'category':'Bazar','note':null,'date':'2026-10-11','type':'expense'});
    await DbHelper.upgrade(d,1,2);
    final row = (await d.query('transactions')).single;
    expect(row['id'],42); expect(row['amount_minor'],12550); expect(row['note'],'');
    expect(await d.query('budgets'),isEmpty);
    await d.close();
  });
  test('Backup validates before restore and strips unknown fields',() {
    final data = fixture(); (data['transactions'] as List).first['sql'] = 'DROP TABLE transactions';
    final rows = Backup.validate(jsonEncode(data));
    expect(rows['transactions']!.single['amount_minor'],12550);
    expect(rows['transactions']!.single.containsKey('sql'),false);
  });
  test('Reject invalid backup schema, amounts, duplicates and missing categories',() {
    for (final modify in <void Function(Map<String,Object?>)>[
      (d) => d['schema'] = 99,
      (d) => (d['transactions'] as List).first['amount_minor'] = 1.25,
      (d) => (d['transactions'] as List).first['amount_minor'] = -1,
      (d) => (d['transactions'] as List).add((d['transactions'] as List).first),
      (d) => d['categories'] = [],
      (d) => (d['transactions'] as List).first['category'] = 'Missing',
    ]) {
      final d = fixture(); modify(d);
      expect(() => Backup.validate(jsonEncode(d)),throwsFormatException);
    }
  });
  test('CSV quotes and neutralizes spreadsheet formulas',() {
    expect(Backup.csvCell('=1+1'),'"\'=1+1"');
    expect(Backup.csvCell('a,"b"'),'"a,""b"""');
  });
}
