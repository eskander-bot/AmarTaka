import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'portfolio.dart';

class CategoryBudgetsScreen extends StatefulWidget {
  final DateTime month;
  const CategoryBudgetsScreen({super.key,required this.month});
  @override State<CategoryBudgetsScreen> createState()=>_CategoryBudgetsScreenState();
}
class _CategoryBudgetsScreenState extends State<CategoryBudgetsScreen> {
  late DateTime _month;List<Record> _budgets=[];List<Txn> _transactions=[];List<String> _categories=[];String? _error;bool _loading=true;
  @override void initState(){super.initState();_month=widget.month;_load();}
  Future<void> _load() async {
    try{final store=await PortfolioStore.open();final budgets=await store.budgets(_month),rows=await DbHelper.instance.getTransactions(month:_month),cats=await DbHelper.instance.getCategories(TxnType.expense);if(mounted)setState((){_budgets=budgets;_transactions=rows;_categories=cats;_loading=false;_error=null;});}
    catch(_){if(mounted)setState((){_loading=false;_error='বাজেট পড়া যায়নি।';});}
  }
  int _spent(String category)=>_transactions.where((t)=>t.type==TxnType.expense&&t.category==category).fold(0,(s,t)=>s+t.amountMinor);
  Future<void> _edit([Record? row]) async {
    if(_categories.isEmpty)return;
    var category=row==null?_categories.first:field(row,'category');final amount=TextEditingController(text:row==null?'':moneyInput(number(row,'amount_minor')));final form=GlobalKey<FormState>();
    final result=await showDialog<Record>(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,update)=>AlertDialog(title:const Text('ক্যাটাগরির বাজেট'),content:SingleChildScrollView(child:Form(key:form,child:Column(mainAxisSize:MainAxisSize.min,children:[DropdownButtonFormField<String>(isExpanded:true,initialValue:category,items:_categories.map((c)=>DropdownMenuItem(value:c,child:Text(categoryLabel(c)))).toList(),onChanged:row==null?(v)=>update(()=>category=v!):null),const SizedBox(height:16),TextFormField(controller:amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'ব্যয়সীমা (টাকা)'),validator:(v)=>parseMoney(v??'')==null?'সঠিক পরিমাণ দিন':null)]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('বাদ দিন')),FilledButton(onPressed:(){if(form.currentState!.validate())Navigator.pop(ctx,<String,Object?>{'month':monthKey(_month),'category':category,'amount_minor':parseMoney(amount.text)});},child:const Text('সংরক্ষণ'))])));
    if(result==null)return;try{await (await PortfolioStore.open()).saveBudget(result);await _load();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('সংরক্ষণ হয়নি।')));}
  }
  Future<void> _delete(Record r) async {
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('এই বাজেট মুছবেন?'),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('না')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('মুছুন'))]));
    if(ok!=true)return;try{await (await DbHelper.instance.db).delete('category_budgets',where:'id=?',whereArgs:[r['id']]);await _load();}catch(_){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('মুছে ফেলা যায়নি।')));}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('ক্যাটাগরি বাজেট')),floatingActionButton:FloatingActionButton(onPressed:_loading?null:()=>_edit(),child:const Icon(Icons.add)),body:_loading?const Center(child:CircularProgressIndicator()):_error!=null?Center(child:TextButton(onPressed:_load,child:Text(_error!))):ListView(padding:const EdgeInsets.fromLTRB(20,8,20,100),children:[
    Row(children:[IconButton(onPressed:(){setState((){_month=DateTime(_month.year,_month.month-1);_loading=true;});_load();},icon:const Icon(Icons.chevron_left)),Expanded(child:Text(monthLabel(_month),textAlign:TextAlign.center)),IconButton(onPressed:(){setState((){_month=DateTime(_month.year,_month.month+1);_loading=true;});_load();},icon:const Icon(Icons.chevron_right))]),
    const Text('লেনদেন থেকে খরচ নিজে হিসাব হবে। একই মাস ও ক্যাটাগরিতে নতুন বাজেট দিলে আগের সীমা বদলাবে। মোট মাসিক বাজেট আলাদাভাবে থাকবে।'),
    if(_budgets.isEmpty)const Padding(padding:EdgeInsets.all(32),child:Text('এই মাসে ক্যাটাগরি বাজেট নেই। + চাপুন।')),
    ..._budgets.map((r){final spent=_spent(field(r,'category')),limit=number(r,'amount_minor'),over=spent>limit;return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(categoryLabel(field(r,'category')),style:Theme.of(context).textTheme.titleMedium)),IconButton(tooltip:'বাজেট সম্পাদনা',onPressed:()=>_edit(r),icon:const Icon(Icons.edit_outlined)),IconButton(tooltip:'বাজেট মুছুন',onPressed:()=>_delete(r),icon:const Icon(Icons.delete_outline))]),Text('${formatMinor(spent)} / ${formatMinor(limit)}'),const SizedBox(height:12),LinearProgressIndicator(value:(spent/limit).clamp(0.0,1.0),color:over?Theme.of(context).colorScheme.error:null),const SizedBox(height:10),Text(over?'সীমার বেশি ${formatMinor(spent-limit)}':'বাকি ${formatMinor(limit-spent)}',style:TextStyle(color:over?Theme.of(context).colorScheme.error:null))])));}),
  ]));
}
