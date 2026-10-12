import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'portfolio.dart';
import '../widgets/wealth_cards.dart';
import '../theme/app_theme.dart';

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
    Padding(padding:const EdgeInsets.only(bottom:12),child:Text('${formatMinor(_budgets.fold<int>(0,(sum,r)=>sum+number(r,'amount_minor')))} পরিকল্পিত',style:Theme.of(context).textTheme.bodySmall)),
    if(_budgets.any((r)=>_spent(field(r,'category'))>=number(r,'amount_minor')*.8))
      Container(margin:const EdgeInsets.only(bottom:14),padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:WealthStyle.amber.withValues(alpha:.10),borderRadius:BorderRadius.circular(16),border:Border.all(color:WealthStyle.amber.withValues(alpha:.25))),child:Row(children:[Icon(Icons.warning_amber_rounded,size:18,color:WealthStyle.accent(context,'cash')),const SizedBox(width:10),Expanded(child:Text('কিছু ক্যাটাগরিতে বাজেটের ৮০% বা বেশি খরচ হয়েছে।',style:TextStyle(color:WealthStyle.accent(context,'cash'),fontSize:12)))])),
    if(_budgets.isEmpty)const Padding(padding:EdgeInsets.all(32),child:Text('এই মাসে ক্যাটাগরি বাজেট নেই। + চাপুন।')),
    ..._budgets.map((r){
      final category=field(r,'category'),spent=_spent(category),limit=number(r,'amount_minor');
      final ratio=spent/limit;
      final color=ratio>=1?AppColors.expenseFor(context):ratio>=.8?WealthStyle.accent(context,'cash'):AppColors.incomeFor(context);
      return Card(child:InkWell(borderRadius:BorderRadius.circular(20),onTap:()=>_edit(r),child:Padding(padding:const EdgeInsets.fromLTRB(16,12,12,16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(WealthStyle.categoryIcon(category),size:19),const SizedBox(width:8),Expanded(child:Text(categoryLabel(category),style:Theme.of(context).textTheme.titleMedium)),PopupMenuButton<String>(tooltip:'বাজেটের অপশন',onSelected:(v){if(v=='edit'){_edit(r);}else{_delete(r);}},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('সম্পাদনা')),PopupMenuItem(value:'delete',child:Text('মুছুন'))])]),
        Text('${formatMinor(spent)} / ${formatMinor(limit)}',style:Theme.of(context).textTheme.bodySmall),const SizedBox(height:10),
        LinearProgressIndicator(value:ratio.clamp(0.0,1.0),minHeight:6,borderRadius:BorderRadius.circular(8),color:color),
        const SizedBox(height:8),Text(spent>limit?'সীমার বেশি ${formatMinor(spent-limit)}':'বাকি ${formatMinor(limit-spent)}',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:color)),
      ]))));
    }),
  ]));
}
