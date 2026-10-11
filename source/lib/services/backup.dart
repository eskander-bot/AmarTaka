import 'dart:convert';
import '../database/db_helper.dart';
import '../utils/formatters.dart';

class Backup {
  static const tables = ['transactions','categories','budgets','goals','notes'];
  static Future<String> exportJson() async {
    final d = await DbHelper.instance.db;
    final data = await d.transaction((txn) async {
      final result = <String,Object?>{'app':'amar-taka','schema':2,'exported_at':DateTime.now().toIso8601String()};
      for (final table in tables) { result[table] = await txn.query(table); }
      return result;
    });
    return const JsonEncoder.withIndent('  ').convert(data);
  }
  // Only allow known fields. Validate the entire backup before touching the DB.
  static Map<String,List<Map<String,Object?>>> validate(String text) {
    if (utf8.encode(text).length > 10 * 1024 * 1024) throw const FormatException('Backup too large');
    final root = jsonDecode(text);
    if (root is! Map || root['app'] != 'amar-taka' || root['schema'] != 2) throw const FormatException('Unsupported backup');
    final result = <String,List<Map<String,Object?>>>{};
    for (final table in tables) {
      final rows = root[table];
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
          case 'transactions':
            out.addAll({'amount_minor':number('amount_minor'),'category':str('category',max:60),'note':str('note',max:2000,empty:true),'date':date('date'),'type':type()});
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
    return result;
  }
  static Future<void> restore(String text) async {
    final data = validate(text);
    await (await DbHelper.instance.db).transaction((txn) async {
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
