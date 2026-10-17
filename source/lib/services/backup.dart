import 'dart:convert';
import '../database/db_helper.dart';
import '../finance/portfolio.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/formatters.dart';

class Backup {
  static const tables = ['transactions','categories','budgets','goals','notes','holdings','account_movements','category_budgets','loan_payments','quick_entries','recurring'];
  static Future<String> exportJson({Database? database}) async {
    final d = database ?? await DbHelper.instance.db;
    final data = await d.transaction((txn) async {
      final result = <String,Object?>{'app':'amar-taka','schema':4,'exported_at':DateTime.now().toIso8601String()};
      for (final table in tables) { result[table] = await txn.query(table); }
      return result;
    });
    final text=const JsonEncoder.withIndent('  ').convert(data);
    validate(text); // Never export a backup this version cannot restore.
    return text;
  }
  // Only allow known fields. Validate the entire backup before touching the DB.
  static Map<String,List<Map<String,Object?>>> validate(String text) {
    if (utf8.encode(text).length > 64 * 1024 * 1024) throw const FormatException('Backup সর্বোচ্চ ৬৪ MB হতে পারে। বড় রসিদের ছবি ছোট করে আবার চেষ্টা করুন।');
    final root = jsonDecode(text);
    if (root is! Map || root['app'] != 'amar-taka' || ![2,3,4].contains(root['schema'])) throw const FormatException('Unsupported backup');
    final result = <String,List<Map<String,Object?>>>{};
    for (final table in tables) {
      final rows = (root['schema']==2 && ['holdings','account_movements','category_budgets'].contains(table)) || (root['schema']!=4 && ['loan_payments','quick_entries','recurring'].contains(table)) ? <Object?>[] : root[table];
      if (rows is! List || rows.length > 50000) throw const FormatException('Invalid rows');
      final ids = <int>{};
      final keys = <String>{};
      result[table] = rows.map<Map<String,Object?>>((row) {
        if (row is! Map) throw const FormatException('Invalid record');
        final m = Map<String,Object?>.from(row);
        String str(String k,{int max = 200, bool empty = false}) {
          final v = m[k];
          if (v is! String || v.length > max || (!empty && v.trim().isEmpty)) throw FormatException('Invalid $k');
          return v;
        }
        int number(String k,{bool zero = false}) {
          final v = m[k];
          if (v is! int || v < (zero ? 0 : 1) || v > maxMinor) throw FormatException('Invalid $k');
          return v;
        }
        String date(String k) {
          final v = str(k,max:40);
          final parsed = DateTime.tryParse(v);
          if (parsed == null || parsed.year < 1900 || parsed.year > 2200 || parsed.isUtc || !RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(v) || !parsed.toIso8601String().startsWith(v.substring(0,10))) throw const FormatException('Invalid date');
          // Canonicalize so SQLite text ordering remains chronological.
          return parsed.toIso8601String();
        }
        String type() {
          final v = str('type');
          if (!['income','expense'].contains(v)) throw const FormatException('Invalid type');
          return v;
        }
        final out = <String,Object?>{};
        if (table != 'budgets') {
          final id = number('id');
          if (!ids.add(id)) throw const FormatException('Duplicate id');
          out['id'] = id;
        }
        switch (table) {
          case 'holdings':
            out.addAll(FinanceValidation.holding(m,withId:true));
          case 'account_movements':
            out.addAll(FinanceValidation.movement(m,withId:true));
          case 'category_budgets':
            final b=FinanceValidation.budget(m,withId:true);
            if(!keys.add('${b['month']}:${b['category']}'))throw const FormatException('Duplicate category budget');
            out.addAll(b);
          case 'loan_payments':
            out.addAll({'loan_id':number('loan_id'),'amount_minor':number('amount_minor'),'date':date('date'),'note':str('note',max:2000,empty:true)});
          case 'quick_entries':
          case 'recurring':
            out.addAll({'title':str('title',max:100),'amount_minor':number('amount_minor'),'category':str('category',max:60),'type':type(),'note':str('note',max:2000,empty:true),'account_id':m['account_id']==null?null:number('account_id')});
            if(table=='recurring') {
              final enabled=number('enabled',zero:true);
              if(enabled>1) throw const FormatException('Invalid enabled');
              out.addAll({'start':date('start'),'next_date':date('next_date'),'enabled':enabled});
              if(DateTime.parse(out['next_date'] as String).isBefore(DateTime.parse(out['start'] as String))) throw const FormatException('Invalid recurrence');
            }
          case 'transactions':
            out.addAll({'amount_minor':number('amount_minor'),'category':str('category',max:60),'note':str('note',max:2000,empty:true),'date':date('date'),'type':type()});
            out['account_id']=m['account_id']==null?null:number('account_id');
            final receipt=m['receipt'] ?? '';
            if(receipt is! String || receipt.length>2800000) throw const FormatException('Invalid receipt');
            if(receipt.isNotEmpty) { final bytes=base64Decode(receipt); if(bytes.length>2*1024*1024 || bytes.length<12 || !((bytes[0]==255 && bytes[1]==216) || (bytes[0]==137 && bytes[1]==80) || (bytes[0]==82 && bytes[1]==73))) throw const FormatException('Invalid receipt image'); }
            out['receipt']=receipt;
          case 'categories':
            final name = str('name',max:60); final kind = type();
            if (!keys.add('$kind:$name')) throw const FormatException('Duplicate category');
            out.addAll({'name':name,'type':kind});
          case 'budgets':
            final month = str('month');
            if (!RegExp(r'^\d{4}-(0[1-9]|1[0-2])$').hasMatch(month) || !keys.add(month)) throw const FormatException('Invalid month');
            out.addAll({'month':month,'amount_minor':number('amount_minor')});
          case 'goals':
            out.addAll({'title':str('title',max:100),'target_minor':number('target_minor'),'saved_minor':number('saved_minor',zero:true),'note':str('note',max:2000,empty:true)});
            if(root['schema']==4) {
              out.addAll({'deadline':m['deadline']==''?'':date('deadline'),'plan_start':m['plan_start']==''?'':date('plan_start'),'plan_saved':number('plan_saved',zero:true)});
              if(out['deadline']!='' && (out['plan_start']=='' || !DateTime.parse(out['deadline'] as String).isAfter(DateTime.parse(out['plan_start'] as String)))) throw const FormatException('Invalid goal plan');
            }
          case 'notes':
            out.addAll({'title':str('title',max:100),'body':str('body',max:10000,empty:true),'updated':date('updated')});
        }
        return out;
      }).toList();
    }
    for (final type in ['income','expense']) {
      if (!result['categories']!.any((c) => c['type'] == type)) throw const FormatException('Missing categories');
    }
    final categoryKeys = result['categories']!.map((c) => '${c['type']}:${c['name']}').toSet();
    if (result['transactions']!.any((t) => !categoryKeys.contains('${t['type']}:${t['category']}'))) throw const FormatException('Missing transaction category');
    final accounts=result['holdings']!.where(isAccount).map((r)=>r['id']).toSet();
    for(final m in result['account_movements']!) {
      if(!accounts.contains(m['account_id']) || (m['type']=='transfer' && !accounts.contains(m['target_id'])))throw const FormatException('Missing movement account');
    }
    for(final table in ['transactions','quick_entries','recurring']) {
      for(final t in result[table]!) {
        if(t['account_id']!=null && !accounts.contains(t['account_id'])) throw const FormatException('Missing transaction account');
        if(!categoryKeys.contains('${t['type']}:${t['category']}')) throw const FormatException('Missing category');
      }
    }
    final loans={for(final h in result['holdings']!.where(isLoan)) h['id']:h};
    final paid=<Object?,int>{};
    for(final p in result['loan_payments']!) {
      if(!loans.containsKey(p['loan_id'])) throw const FormatException('Missing loan');
      paid[p['loan_id']]=(paid[p['loan_id']]??0)+(p['amount_minor'] as int);
    }
    for(final id in paid.keys) { if(paid[id]! > (loans[id]!['value_minor'] as int)) throw const FormatException('Invalid repayment history'); }
    final portfolio=Portfolio(holdings:result['holdings']!,movements:result['account_movements']!,transactions:result['transactions']!);
    if(portfolio.holdings.where(isAccount).any((a)=>portfolio.balance(a)<0 || portfolio.balance(a)>maxMinor))throw const FormatException('Invalid account balance');
    if(result['category_budgets']!.any((b)=>!categoryKeys.contains('expense:${b['category']}')))throw const FormatException('Missing budget category');
    return result;
  }
  static Future<void> restore(String text,{Database? database}) async {
    final data = validate(text);
    await (database ?? await DbHelper.instance.db).transaction((txn) async {
      for (final table in tables) {
        await txn.delete(table);
        for (final row in data[table]!) { await txn.insert(table,row); }
      }
    });
  }
  static String csvCell(Object? value) {
    var s = '$value';
    if (RegExp(r'^[\s]*[=+@\-]').hasMatch(s)) s = "'$s";
    return '"${s.replaceAll('"', '""')}"';
  }
  static Future<String> exportCsv() async {
    final rows = await DbHelper.instance.getTransactions();
    return '\uFEFFdate,type,category,amount_taka,note\r\n${rows.map((t) => [t.date.toIso8601String(),t.type.name,categoryLabel(t.category),moneyInput(t.amountMinor),t.note].map(csvCell).join(',')).join('\r\n')}';
  }
}
