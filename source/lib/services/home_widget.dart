import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'app_lock.dart';

class LedgerWidget {
  static const channel=MethodChannel('com.meskander.amartaka/widget');
  static final changed=ValueNotifier<int>(0);
  static Future<void> refresh() async {
    try {
      final rows=await DbHelper.instance.getTransactions();final totals=<String,int>{};
      for(final t in rows.where((t)=>t.type==TxnType.expense)){
        final key='${t.date.year}-${t.date.month.toString().padLeft(2,'0')}-${t.date.day.toString().padLeft(2,'0')}';
        totals[key]=(totals[key]??0)+t.amountMinor;
      }
      final hidden=await AppLock.enabled();
      await channel.invokeMethod('update',{'totals':hidden?'{}':jsonEncode(totals.map((key,value)=>MapEntry(key,formatMinor(value)))),'zero':formatMinor(0),'hidden':hidden});
    } on MissingPluginException { /* Widget is Android-only. */ } on PlatformException { /* Ledger remains available. */ }
  }
  static Future<String?> takeAction() async {
    try{return await channel.invokeMethod<String>('takeAction');}on MissingPluginException{return null;}
  }
}
