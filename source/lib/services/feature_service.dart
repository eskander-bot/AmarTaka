import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../finance/portfolio.dart';
import '../utils/formatters.dart';

class FeatureService {
  static DateTime nextMonth(DateTime current,int anchor) {
    final first=DateTime(current.year,current.month+1);
    return DateTime(first.year,first.month,math.min(anchor,DateTime(first.year,first.month+1,0).day));
  }
  // Atomic next_date advancement prevents duplicate posting on reopen/crash.
  static Future<List<String>> postDue(Database db,{DateTime? now}) async {
    final today=now??DateTime.now(),errors=<String>[];
    final rules=await db.query('recurring',where:'enabled=1',orderBy:'id');
    for(final r in rules) {
      try {
        await db.transaction((d) async {
          final current=await d.query('recurring',where:'id=? AND enabled=1',whereArgs:[r['id']]);
          if(current.isEmpty)return;
          final rule=current.first;
          var next=DateTime.parse(rule['next_date'] as String);
          final anchor=DateTime.parse(rule['start'] as String).day;
          var count=0;
          while(!next.isAfter(today) && count<120) {
            await DbHelper.writeTransaction(d,Txn(amountMinor:rule['amount_minor'] as int,category:rule['category'] as String,note:rule['note'] as String,date:next,type:TxnType.values.byName(rule['type'] as String),accountId:rule['account_id'] as int?));
            next=nextMonth(next,anchor);count++;
          }
          await d.update('recurring',{'next_date':next.toIso8601String()},where:'id=?',whereArgs:[r['id']]);
        });
      } on FormatException catch(e) { errors.add('${r['title']}: ${e.message}'); }
    }
    return errors;
  }
  static Future<void> saveTemplate(Txn t,String title,{DateTime? start}) async {
    final d=await DbHelper.instance.db;
    final values=<String,Object?>{'title':FinanceValidation.text(title,max:100),'amount_minor':FinanceValidation.integer(t.amountMinor,min:1),'category':t.category,'type':t.type.name,'note':t.note,'account_id':t.accountId};
    if(start!=null)values.addAll({'start':start.toIso8601String(),'next_date':start.toIso8601String(),'enabled':1});
    await d.transaction((tx)async{
      if(t.accountId!=null && (await tx.query('holdings',where:'id=? AND kind IN (?,?)',whereArgs:[t.accountId,'cash','bank'])).isEmpty)throw const FormatException('অ্যাকাউন্ট পাওয়া যায়নি।');
      await tx.insert(start==null?'quick_entries':'recurring',values);
    });
  }
  static String goalPlan(Record g,{DateTime? now}) {
    if(field(g,'deadline').isEmpty)return 'পরিকল্পনার জন্য লক্ষ্য সম্পাদনায় শেষ তারিখ দিন।';
    final current=now??DateTime.now();
    final today=DateTime(current.year,current.month,current.day),end=DateTime.parse(field(g,'deadline')),start=DateTime.parse(field(g,'plan_start'));
    final remaining=math.max(0,number(g,'target_minor')-number(g,'saved_minor'));
    if(remaining==0)return 'লক্ষ্য পূরণ হয়েছে!';
    if(today.isAfter(end))return 'সময়সীমা শেষ • বাকি ${formatMinor(remaining)}';
    final months=math.max(1,(end.year-today.year)*12+end.month-today.month+(end.day>=today.day?1:0));
    final duration=end.difference(start).inSeconds;
    final elapsed=today.difference(start).inSeconds.clamp(0,math.max(1,duration));
    final planned=number(g,'plan_saved')+((number(g,'target_minor')-number(g,'plan_saved'))*elapsed/math.max(1,duration)).round();
    return 'মাসে প্রায় ${formatMinor((remaining/months).ceil())} • ${formatDate(end)} পর্যন্ত\n${number(g,'saved_minor')>=planned?'পরিকল্পনা অনুযায়ী এগোচ্ছেন':'পরিকল্পনার চেয়ে ${formatMinor(planned-number(g,'saved_minor'))} পিছিয়ে'}';
  }
}
