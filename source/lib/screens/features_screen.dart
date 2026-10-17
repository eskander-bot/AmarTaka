import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../finance/portfolio.dart';
import '../finance/finance_screen.dart';
import '../models/transaction.dart';
import '../services/feature_service.dart';
import '../services/report_export.dart';
import '../utils/formatters.dart';
import '../widgets/jewel_icon.dart';
import 'add_transaction_screen.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});
  @override State<FeaturesScreen> createState()=>_FeaturesScreenState();
}
class _FeaturesScreenState extends State<FeaturesScreen> {
  List<Record> _quick=[],_rules=[],_loans=[],_payments=[];
  List<String> _pending=[];bool _busy=false;String? _error;
  @override void initState(){super.initState();_run(_load);}
  Future<void> _run(Future<void> Function() f) async {
    if(_busy)return;setState((){_busy=true;_error=null;});
    try{await f();}catch(e){if(mounted)setState(()=>_error=e is FormatException?e.message:'কাজটি হয়নি। আবার চেষ্টা করুন।');}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  Future<void> _load() async {
    final d=await DbHelper.instance.db;final pending=await FeatureService.postDue(d);
    final quick=await d.query('quick_entries',orderBy:'id DESC'),rules=await d.query('recurring',orderBy:'id DESC');
    final loans=await d.query('holdings',where:'kind IN (?,?)',whereArgs:['lent','borrowed'],orderBy:'title'),payments=await d.query('loan_payments',orderBy:'date DESC,id DESC');
    if(mounted)setState((){_quick=quick;_rules=rules;_loans=loans;_payments=payments;_pending=pending;});
  }
  Future<void> _add(bool recurring) async {await Navigator.push(context,MaterialPageRoute(builder:(_)=>AddTransactionScreen(template:true,recurring:recurring)));await _load();}
  Future<void> _remove(String table,int id) async {
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('মুছে ফেলবেন?'),content:const Text('আগে যোগ করা লেনদেন থাকবে। শুধু এই শর্টকাট / নিয়মটি মুছবে।'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('না')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('মুছুন'))]));
    if(ok==true){await (await DbHelper.instance.db).delete(table,where:'id=?',whereArgs:[id]);await _load();}
  }
  Widget _heading(String title,VoidCallback action)=>Row(children:[Expanded(child:Text(title,style:Theme.of(context).textTheme.titleLarge)),IconButton(onPressed:_busy?null:action,icon:const Icon(Icons.add_circle_outline),tooltip:'যোগ করুন')]);
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('আরও সুবিধা'),actions:[IconButton(onPressed:_busy?null:()=>_run(_load),icon:const Icon(Icons.refresh),tooltip:'আবার পড়ুন')]),body:ListView(padding:const EdgeInsets.all(18),children:[
    if(_busy)const LinearProgressIndicator(),if(_error!=null)Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
    Card(child:ListTile(leading:const JewelIcon(icon:Icons.picture_as_pdf_outlined,color:Color(0xFF8A63D2)),title:const Text('তারিখ অনুযায়ী রিপোর্ট'),subtitle:const Text('আয়–ব্যয় দেখুন ও বাংলা PDF শেয়ার করুন'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RangeReportScreen())))),
    _heading('দ্রুত এন্ট্রি',()=>_run(()=>_add(false))),
    if(_quick.isEmpty)const Text('বারবার করা খরচের শর্টকাট তৈরি করতে + চাপুন।'),
    ..._quick.map((q)=>Card(child:ListTile(leading:const JewelIcon(icon:Icons.bolt_rounded,color:Color(0xFFE6A52C)),title:Text(field(q,'title')),subtitle:Text('${categoryLabel(field(q,'category'))} • ${formatMinor(number(q,'amount_minor'))}'),onTap:_busy?null:()=>_run(()async {await Navigator.push(context,MaterialPageRoute(builder:(_)=>AddTransactionScreen(transaction:Txn(amountMinor:number(q,'amount_minor'),category:field(q,'category'),type:TxnType.values.byName(field(q,'type')),note:field(q,'note'),date:DateTime.now(),accountId:q['account_id'] as int?))));await _load();}),trailing:IconButton(tooltip:'শর্টকাট মুছুন',onPressed:_busy?null:()=>_run(()=>_remove('quick_entries',number(q,'id'))),icon:const Icon(Icons.delete_outline))))),
    const SizedBox(height:20),_heading('মাসিক আয়–ব্যয়',()=>_run(()=>_add(true))),
    const Text('অ্যাপ খোলার সময় বকেয়া মাসের এন্ট্রি হবে। মাসের ২৯–৩১ তারিখ না থাকলে শেষ দিনে হবে। বন্ধ করে আবার চালু করলে বকেয়া মাসও যোগ হবে। নিয়ম বদলাতে পুরোনোটি মুছে নতুনটি তৈরি করুন।'),
    if(_pending.isNotEmpty)Card(child:Padding(padding:const EdgeInsets.all(14),child:Text('অপেক্ষমাণ:\n${_pending.join('\n')}'))),
    ..._rules.map((r)=>Card(child:Column(children:[SwitchListTile(title:Text(field(r,'title')),subtitle:Text('${formatMinor(number(r,'amount_minor'))} • পরবর্তী ${formatDate(DateTime.parse(field(r,'next_date')))}'),value:r['enabled']==1,onChanged:_busy?null:(v)=>_run(()async{await (await DbHelper.instance.db).update('recurring',{'enabled':v?1:0},where:'id=?',whereArgs:[r['id']]);await _load();})),Align(alignment:Alignment.centerRight,child:TextButton(onPressed:_busy?null:()=>_run(()=>_remove('recurring',number(r,'id'))),child:const Text('নিয়মটি মুছুন')))]))),
    const SizedBox(height:20),_heading('ধার–দেনার ইতিহাস',()=>_run(()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>const FinanceScreen()));await _load();})),
    const Text('ব্যক্তির নামে ধার যোগ করুন। পরিশোধে অ্যাকাউন্ট থেকে স্বয়ংক্রিয় আয়–ব্যয় হবে না। আগের মোট পরিশোধ থাকবে; এই সংস্করণ থেকে আলাদা ইতিহাসও থাকবে।'),
    ..._loans.map((l){final payments=_payments.where((p)=>p['loan_id']==l['id']).toList();final recorded=payments.fold<int>(0,(s,p)=>s+number(p,'amount_minor'));return Card(child:ExpansionTile(title:Text('${field(l,'title')} • ${l['kind']=='lent'?'পাব':'দেব'}'),subtitle:Text('বাকি ${formatMinor(number(l,'amount_minor')-number(l,'value_minor'))} • শেষ তারিখ ${formatDate(DateTime.parse(field(l,'end')))}'),children:[
      if(number(l,'value_minor')>recorded)ListTile(title:const Text('আগের পরিশোধ / সমন্বয়'),trailing:Text(formatMinor(number(l,'value_minor')-recorded))),
      ...payments.map((p)=>ListTile(leading:const Icon(Icons.check_circle_outline),title:Text(formatMinor(number(p,'amount_minor'))),subtitle:Text('${formatDate(DateTime.parse(field(p,'date')))} ${field(p,'note')}'))),
      if(number(l,'value_minor')<number(l,'amount_minor'))TextButton.icon(onPressed:_busy?null:()=>_run(()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>LoanPaymentScreen(loan:l)));await _load();}),icon:const Icon(Icons.add),label:const Text('পরিশোধ যোগ করুন')),
    ]));}),
  ]));
}
class LoanPaymentScreen extends StatefulWidget {
  final Record loan;const LoanPaymentScreen({super.key,required this.loan});
  @override State<LoanPaymentScreen> createState()=>_LoanPaymentScreenState();
}
class _LoanPaymentScreenState extends State<LoanPaymentScreen>{
  final _amount=TextEditingController(),_note=TextEditingController();DateTime _date=DateTime.now();bool _busy=false;String? _error;
  @override void dispose(){_amount.dispose();_note.dispose();super.dispose();}
  Future<void> _save()async{final amount=parseMoney(_amount.text);if(amount==null){setState(()=>_error='সঠিক পরিমাণ দিন।');return;}setState(()=>_busy=true);try{await (await PortfolioStore.open()).repay(number(widget.loan,'id'),amount,date:_date,note:_note.text.trim());if(mounted)Navigator.pop(context,true);}catch(e){if(mounted)setState(()=>_error=e is FormatException?e.message:'সংরক্ষণ হয়নি।');}finally{if(mounted)setState(()=>_busy=false);}}
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text(field(widget.loan,'title'))),body:ListView(padding:const EdgeInsets.all(20),children:[TextField(controller:_amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'পরিশোধের টাকা')),const SizedBox(height:16),TextField(controller:_note,maxLength:2000,decoration:const InputDecoration(labelText:'বিবরণ')),OutlinedButton(onPressed:_busy?null:()async{final d=await showDatePicker(context:context,initialDate:_date,firstDate:DateTime(1900),lastDate:DateTime.now());if(d!=null && mounted)setState(()=>_date=d);},child:Text(formatDate(_date))),if(_error!=null)Text(_error!),FilledButton(onPressed:_busy?null:_save,child:Text(_busy?'সংরক্ষণ হচ্ছে…':'পরিশোধ যোগ করুন'))]));
}
class RangeReportScreen extends StatefulWidget {
  const RangeReportScreen({super.key});
  @override State<RangeReportScreen> createState()=>_RangeReportScreenState();
}
class _RangeReportScreenState extends State<RangeReportScreen> {
  DateTimeRange _range=DateTimeRange(start:DateTime(DateTime.now().year,DateTime.now().month),end:DateTime.now());
  List<Txn> _all=[];bool _busy=true;String? _error;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {try{final rows=await DbHelper.instance.getTransactions();if(mounted)setState(()=>_all=rows);}catch(_){if(mounted)setState(()=>_error='রিপোর্ট পড়া যায়নি।');}finally{if(mounted)setState(()=>_busy=false);}}
  List<Txn> get _rows {final end=DateTime(_range.end.year,_range.end.month,_range.end.day+1);return _all.where((t)=>!t.date.isBefore(_range.start)&&t.date.isBefore(end)).toList();}
  Future<void> _pdf({bool save=false}) async {setState(()=>_busy=true);try{if(save){final saved=await ReportExport.save(_rows,_range.start,_range.end);if(saved && mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('PDF সংরক্ষণ হয়েছে।')));}else{await ReportExport.share(_rows,_range.start,_range.end);}}catch(e){if(mounted)setState(()=>_error=e is FormatException?e.message:'PDF তৈরি হয়নি। ছোট সময়সীমা দিয়ে চেষ্টা করুন।');}finally{if(mounted)setState(()=>_busy=false);}}
  @override Widget build(BuildContext context){final rows=_rows;final income=rows.where((t)=>t.type==TxnType.income).fold<int>(0,(s,t)=>s+t.amountMinor),expense=rows.where((t)=>t.type==TxnType.expense).fold<int>(0,(s,t)=>s+t.amountMinor);return Scaffold(appBar:AppBar(title:const Text('তারিখ অনুযায়ী রিপোর্ট')),body:ListView(padding:const EdgeInsets.all(18),children:[
    OutlinedButton.icon(icon:const Icon(Icons.date_range),label:Text('${formatDate(_range.start)} — ${formatDate(_range.end)}'),onPressed:_busy?null:() async{final picked=await showDateRangePicker(context:context,firstDate:DateTime(1900),lastDate:DateTime(2200),initialDateRange:_range);if(picked!=null && mounted)setState(()=>_range=picked);}),
    if(_busy)const LinearProgressIndicator(),if(_error!=null)Text(_error!),
    Card(child:Padding(padding:const EdgeInsets.all(18),child:Text('আয়: ${formatMinor(income)}\nব্যয়: ${formatMinor(expense)}\nনিট: ${formatMinor(income-expense)}\n${toBangla('${rows.length}')}টি লেনদেন',style:Theme.of(context).textTheme.titleMedium))),
    FilledButton.icon(onPressed:_busy?null:_pdf,icon:const Icon(Icons.ios_share),label:const Text('বাংলা PDF শেয়ার')),
    OutlinedButton.icon(onPressed:_busy?null:()=>_pdf(save:true),icon:const Icon(Icons.download_outlined),label:const Text('PDF ডাউনলোড / সংরক্ষণ')),
    const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('PDF-এ বাংলা ঠিক রাখতে পৃষ্ঠাগুলো ছবি হিসেবে থাকবে। লম্বা বিবরণের প্রথম অংশ দেখাবে; সম্পূর্ণ বিবরণের জন্য CSV নিন।')),
    ...rows.take(200).map((t)=>Card(child:ListTile(title:Text(categoryLabel(t.category)),subtitle:Text('${formatDate(t.date)} • ${t.note}',maxLines:2,overflow:TextOverflow.ellipsis),trailing:Text('${t.type==TxnType.income?'+':'−'}${formatMinor(t.amountMinor)}')))),
    if(rows.length>200)const Text('এখানে প্রথম ২০০টি দেখানো হচ্ছে; PDF-এ নির্বাচিত সব এন্ট্রি থাকবে (সর্বোচ্চ ২০০০)।'),
  ]));}
}
