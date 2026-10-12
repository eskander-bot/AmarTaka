import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import 'portfolio.dart';
import 'holding_editor.dart';

const financeIcons={'cash':Icons.wallet_outlined,'bank':Icons.account_balance_outlined,'dps':Icons.savings_outlined,'fdr':Icons.lock_clock_outlined,'certificate':Icons.description_outlined,'investment':Icons.trending_up,'lent':Icons.call_made,'borrowed':Icons.call_received};

class FinanceScreen extends StatefulWidget {
  final Future<Portfolio> Function()? loader;
  const FinanceScreen({super.key,this.loader});
  @override State<FinanceScreen> createState()=>_FinanceScreenState();
}
class _FinanceScreenState extends State<FinanceScreen> {
  Portfolio _data=const Portfolio();bool _loading=true;String? _error;String? _kind;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {
    try {final data=widget.loader!=null?await widget.loader!():await (await PortfolioStore.open()).read();if(mounted)setState((){_data=data;_loading=false;_error=null;});}
    catch(_){if(mounted)setState((){_error='হিসাব পড়া যায়নি।';_loading=false;});}
  }
  Future<void> _run(Future<void> Function() action) async {try{await action();await _load();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e is FormatException?e.message:'কাজটি সম্পন্ন হয়নি। আবার চেষ্টা করুন।')));}}
  Future<void> _edit(String kind,[Record? record]) async {await Navigator.push(context,MaterialPageRoute(builder:(_)=>HoldingEditor(kind:kind,record:record)));if(mounted)await _load();}
  Future<void> _add() async {
    final kind=_kind??await showModalBottomSheet<String>(context:context,isScrollControlled:true,builder:(ctx)=>SafeArea(child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[const Padding(padding:EdgeInsets.all(18),child:Text('কোন হিসাব যোগ করবেন?',style:TextStyle(fontSize:20,fontWeight:FontWeight.w600))),...financeKinds.map((k)=>ListTile(leading:Icon(financeIcons[k]),title:Text(financeLabels[k]!),onTap:()=>Navigator.pop(ctx,k)))]))));
    if(kind!=null && mounted)await _edit(kind);
  }
  Future<bool> _confirm(String text) async=>await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('নিশ্চিত করুন'),content:Text(text),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('বাদ দিন')),FilledButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('নিশ্চিত'))]))??false;
  Future<void> _action(Record r,String action) async {
    final id=number(r,'id');
    if(action=='edit'){await _edit(field(r,'kind'),r);return;}
    if(action=='delete' && await _confirm('এই রেকর্ড মুছে যাবে।'))await _run(() async=>(await PortfolioStore.open()).delete(id));
    if(action=='installment' && await _confirm('একটি মাসের কিস্তি জমা হয়েছে হিসেবে রাখবেন? ব্যাংক/ক্যাশ ব্যালেন্স নিজে আপডেট করবেন।'))await _run(() async=>(await PortfolioStore.open()).payInstallment(id));
    if(action=='repay') {
      final amount=await askAmount(context,'পরিশোধের পরিমাণ','বকেয়া ${formatMinor(_data.value(r))}');
      if(amount!=null)await _run(() async=>(await PortfolioStore.open()).repay(id,amount));
    }
    if(action=='movement' && mounted){await Navigator.push(context,MaterialPageRoute(builder:(_)=>MovementEditor(portfolio:_data,accountId:id)));if(mounted)await _load();}
    if(action=='history' && mounted)await Navigator.push(context,MaterialPageRoute(builder:(_)=>AccountHistory(portfolio:_data,account:r)));
  }
  Widget _metric(String title,int amount,{bool primary=false})=>Card(color:primary?Theme.of(context).colorScheme.primaryContainer:null,child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title),const SizedBox(height:6),Text(formatMinor(amount),style:Theme.of(context).textTheme.headlineSmall)])));
  Widget _card(Record r){
    final kind=field(r,'kind'),amount=_data.value(r);
    final subtitle=[field(r,'institution'),field(r,'subtype')].where((s)=>s.isNotEmpty).join(' • ');
    return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(financeIcons[kind],color:Theme.of(context).colorScheme.primary),const SizedBox(width:10),Expanded(child:Text(field(r,'title'),style:Theme.of(context).textTheme.titleMedium)),PopupMenuButton<String>(tooltip:'হিসাবের অপশন',onSelected:(a)=>_action(r,a),itemBuilder:(_)=>[
        const PopupMenuItem(value:'edit',child:Text('সম্পাদনা')),
        if(isAccount(r))...const [PopupMenuItem(value:'movement',child:Text('জমা / উত্তোলন / ট্রান্সফার')),PopupMenuItem(value:'history',child:Text('লেনদেনের ইতিহাস'))],
        if(kind=='dps' && number(r,'active')==1 && number(r,'months_paid')<FinanceMath.termMonths(r))const PopupMenuItem(value:'installment',child:Text('এক কিস্তি জমা হয়েছে')),
        if(isLoan(r) && amount>0)const PopupMenuItem(value:'repay',child:Text('পরিশোধ যোগ করুন')),
        const PopupMenuItem(value:'delete',child:Text('মুছুন')),
      ])]),
      if(subtitle.isNotEmpty)Text(subtitle,style:Theme.of(context).textTheme.bodySmall),const SizedBox(height:10),
      Text('${isLoan(r)?'বকেয়া: ':''}${formatMinor(amount)}',style:Theme.of(context).textTheme.headlineSmall),
      if(isLoan(r))Text(amount==0?'সম্পূর্ণ পরিশোধিত':'মোট ${formatMinor(number(r,'amount_minor'))} • পরিশোধ ${formatMinor(number(r,'value_minor'))}'),
      if(kind=='investment')...[
        Text('মূল বিনিয়োগ ${formatMinor(number(r,'amount_minor'))}'),
        Text('লাভ/ক্ষতি ${formatMinor(number(r,'value_minor')-number(r,'amount_minor'))} (${toBangla(FinanceMath.roi(r).toStringAsFixed(1))}%)'),
      ],
      if(isSaving(r))...[
        Text(number(r,'active')==1?'সক্রিয় • বার্ষিক হার ${toBangla((number(r,'rate_bps')/100).toStringAsFixed(2))}%':'বন্ধ / মেয়াদ শেষ করা হিসাব'),
        Text('মেয়াদ শেষ: ${formatDate(DateTime.parse(field(r,'end')))}'),
        if(kind=='dps')...[
          const SizedBox(height:8),LinearProgressIndicator(value:(number(r,'months_paid')/FinanceMath.termMonths(r)).clamp(0.0,1.0)),
          Text('${toBangla('${number(r,'months_paid')}')} / ${toBangla('${FinanceMath.termMonths(r)}')} কিস্তি • মাসে ${formatMinor(number(r,'amount_minor'))}'),
        ],
        if(kind!='dps')Text('আজ পর্যন্ত আনুমানিক মূল্য ${formatMinor(FinanceMath.accrued(r,DateTime.now()))}'),
        Text('মেয়াদে আনুমানিক ${formatMinor(FinanceMath.maturity(r))}'),
        const Text('অনুমান: কর/ফি বাদ দেওয়া হয়নি। প্রকৃত ব্যাংক/স্কিমের হিসাব আলাদা হতে পারে।',style:TextStyle(fontSize:11)),
      ],
      if(field(r,'note').isNotEmpty)Padding(padding:const EdgeInsets.only(top:8),child:Text(field(r,'note'))),
      const SizedBox(height:6),Wrap(spacing:8,children:[
        if(isAccount(r))TextButton.icon(onPressed:()=>_action(r,'movement'),icon:const Icon(Icons.swap_horiz),label:const Text('লেনদেন')),
        if(kind=='dps' && number(r,'active')==1 && number(r,'months_paid')<FinanceMath.termMonths(r))TextButton(onPressed:()=>_action(r,'installment'),child:const Text('কিস্তি যোগ')),
        if(isLoan(r) && amount>0)TextButton(onPressed:()=>_action(r,'repay'),child:const Text('পরিশোধ যোগ')),
        TextButton(onPressed:()=>_edit(kind,r),child:const Text('বিস্তারিত / সম্পাদনা')),
      ]),
    ])));
  }
  @override Widget build(BuildContext context){
    final rows=_kind==null?_data.holdings:_data.ofKind(_kind!);
    return Scaffold(appBar:AppBar(title:const Text('সম্পদ ও দায়')),floatingActionButton:FloatingActionButton.extended(onPressed:_add,icon:const Icon(Icons.add),label:const Text('হিসাব যোগ')),body:_loading?const Center(child:CircularProgressIndicator()):_error!=null?Center(child:TextButton(onPressed:_load,child:Text('$_error আবার চেষ্টা করুন'))):RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(18,10,18,110),children:[
      _metric('নিট সম্পদ',_data.netWorth,primary:true),
      Wrap(spacing:8,runSpacing:4,children:[Text('সম্পদ ${formatMinor(_data.assets)}'),Text('দায় ${formatMinor(_data.liabilities)}')]),
      const ExpansionTile(tilePadding:EdgeInsets.zero,title:Text('হিসাব কীভাবে হয়',style:TextStyle(fontSize:13)),children:[Padding(padding:EdgeInsets.only(bottom:16),child:Text('এখানে আপনার রাখা অ্যাকাউন্ট ও সম্পদের বর্তমান হিসাব। আয়–ব্যয়ের মোট ব্যালেন্স আবার যোগ হয় না। জমা/ট্রান্সফার ও ধার পরিশোধ দৈনিক আয়–ব্যয় বদলায় না। সঞ্চয়ে জমা মূলধন গণনা হয়; অনুমান করা লাভ নয়।',style:TextStyle(fontSize:12)))]),
      Wrap(spacing:7,runSpacing:4,children:[ChoiceChip(label:const Text('সব'),selected:_kind==null,onSelected:(_)=>setState(()=>_kind=null)),...financeKinds.map((k)=>ChoiceChip(label:Text(financeLabels[k]!),selected:_kind==k,onSelected:(_)=>setState(()=>_kind=k)))]),
      if(_kind!=null)_metric('${financeLabels[_kind]} মোট',_data.total(_kind!)),
      if(rows.isEmpty)const Padding(padding:EdgeInsets.symmetric(vertical:44),child:Text('এখনও হিসাব নেই। নিচে “হিসাব যোগ” চাপুন।',textAlign:TextAlign.center)),
      ...rows.map(_card),
    ])));
  }
}

Future<int?> askAmount(BuildContext context,String title,String hint) async {
  final controller=TextEditingController();final form=GlobalKey<FormState>();
  final value=await showDialog<int>(context:context,builder:(ctx)=>AlertDialog(title:Text(title),content:Form(key:form,child:TextFormField(controller:controller,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'টাকা',helperText:hint),validator:(s)=>parseMoney(s??'')==null?'সঠিক পরিমাণ দিন':null)),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('বাদ দিন')),FilledButton(onPressed:(){if(form.currentState!.validate())Navigator.pop(ctx,parseMoney(controller.text));},child:const Text('সংরক্ষণ'))]));
  return value;
}

class MovementEditor extends StatefulWidget {
  final Portfolio portfolio;final int accountId;
  const MovementEditor({super.key,required this.portfolio,required this.accountId});
  @override State<MovementEditor> createState()=>_MovementEditorState();
}
class _MovementEditorState extends State<MovementEditor> {
  final _amount=TextEditingController(),_note=TextEditingController();final _form=GlobalKey<FormState>();
  String _type='deposit';int? _target;bool _busy=false;DateTime _date=DateTime.now();
  @override void dispose(){_amount.dispose();_note.dispose();super.dispose();}
  Future<void> _save() async {
    if(_busy || !_form.currentState!.validate())return;setState(()=>_busy=true);
    try {await (await PortfolioStore.open()).move({'account_id':widget.accountId,'target_id':_target,'type':_type,'amount_minor':parseMoney(_amount.text),'date':_date.toIso8601String(),'note':_note.text.trim()});if(mounted)Navigator.pop(context);}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e is FormatException?e.message:'সংরক্ষণ হয়নি।')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('অ্যাকাউন্ট লেনদেন')),body:Form(key:_form,child:ListView(padding:const EdgeInsets.all(20),children:[
    const Text('এটি অ্যাকাউন্টের ব্যালেন্স বদলায়। আয় বা ব্যয়ের রেকর্ড প্রয়োজন হলে লেনদেন ট্যাবে আলাদা করে লিখুন।'),const SizedBox(height:20),
    DropdownButtonFormField<String>(initialValue:_type,decoration:const InputDecoration(labelText:'লেনদেনের ধরন'),items:const [DropdownMenuItem(value:'deposit',child:Text('জমা')),DropdownMenuItem(value:'withdraw',child:Text('উত্তোলন')),DropdownMenuItem(value:'transfer',child:Text('অন্য অ্যাকাউন্টে ট্রান্সফার'))],onChanged:(v)=>setState(()=>_type=v!)),const SizedBox(height:16),
    if(_type=='transfer')DropdownButtonFormField<int>(isExpanded:true,initialValue:_target,decoration:const InputDecoration(labelText:'যে অ্যাকাউন্টে যাবে'),items:widget.portfolio.holdings.where((a)=>isAccount(a)&&a['id']!=widget.accountId).map((a)=>DropdownMenuItem(value:number(a,'id'),child:Text(field(a,'title')))).toList(),validator:(v)=>v==null?'একটি অ্যাকাউন্ট দিন':null,onChanged:(v)=>setState(()=>_target=v)),
    const SizedBox(height:16),TextFormField(controller:_amount,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'পরিমাণ (টাকা)'),validator:(v)=>parseMoney(v??'')==null?'সঠিক পরিমাণ দিন':null),
    ListTile(contentPadding:EdgeInsets.zero,title:Text(formatDate(_date)),trailing:const Icon(Icons.calendar_month),onTap:()async{final d=await showDatePicker(context:context,initialDate:_date,firstDate:DateTime(1900),lastDate:DateTime.now());if(d!=null)setState(()=>_date=d);}),
    TextFormField(controller:_note,maxLength:2000,maxLines:2,decoration:const InputDecoration(labelText:'নোট')),const SizedBox(height:20),FilledButton(onPressed:_busy?null:_save,child:Text(_busy?'সংরক্ষণ হচ্ছে…':'সংরক্ষণ')),
  ])));
}
class AccountHistory extends StatelessWidget {
  final Portfolio portfolio;final Record account;
  const AccountHistory({super.key,required this.portfolio,required this.account});
  @override Widget build(BuildContext context){
    final rows=portfolio.movements.where((m)=>m['account_id']==account['id']||m['target_id']==account['id']);
    return Scaffold(appBar:AppBar(title:Text(field(account,'title'))),body:ListView(padding:const EdgeInsets.all(18),children:[Text('বর্তমান ব্যালেন্স ${formatMinor(portfolio.balance(account))}',style:Theme.of(context).textTheme.titleLarge),Text('শুরুর ব্যালেন্স ${formatMinor(number(account,'amount_minor'))}'),const Text('ভুল লেনদেন সংশোধন করতে বিপরীত জমা/উত্তোলন বা ট্রান্সফার লিখুন।'),if(rows.isEmpty)const Padding(padding:EdgeInsets.all(24),child:Text('কোনো লেনদেন নেই।')),...rows.map((m){
      final incoming=m['target_id']==account['id']||m['type']=='deposit';
      return Card(child:ListTile(leading:Icon(incoming?Icons.south_west:Icons.north_east),title:Text('${incoming?'+':'−'} ${formatMinor(number(m,'amount_minor'))}'),subtitle:Text('${m['type']=='transfer'?'ট্রান্সফার':incoming?'জমা':'উত্তোলন'} • ${formatDate(DateTime.parse(field(m,'date')))}\n${field(m,'note')}')));
    })]));
  }
}
