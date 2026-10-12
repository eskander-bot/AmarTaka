import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import 'portfolio.dart';

class HoldingEditor extends StatefulWidget {
  final String kind;final Record? record;
  const HoldingEditor({super.key,required this.kind,this.record});
  @override State<HoldingEditor> createState()=>_HoldingEditorState();
}
class _HoldingEditorState extends State<HoldingEditor> {
  final _form=GlobalKey<FormState>();final _controllers=<String,TextEditingController>{};
  late DateTime _start,_end;bool _active=true,_busy=false;
  String get _kind=>widget.kind;
  bool get _account=>['bank','cash'].contains(_kind);
  bool get _saving=>['dps','fdr','certificate'].contains(_kind);
  bool get _loan=>['lent','borrowed'].contains(_kind);
  @override void initState(){super.initState();final r=widget.record;
    for(final k in ['title','institution','reference','subtype','note','amount','value','rate','paid']){_controllers[k]=TextEditingController();}
    if(r!=null){for(final k in ['title','institution','reference','subtype','note']){_controllers[k]!.text=field(r,k);}_controllers['amount']!.text=moneyInput(number(r,'amount_minor'));_controllers['value']!.text=moneyInput(number(r,'value_minor'));_controllers['rate']!.text=(number(r,'rate_bps')/100).toStringAsFixed(2);_controllers['paid']!.text='${number(r,'months_paid')}';}
    else{_controllers['value']!.text='0';_controllers['paid']!.text='0';}
    _start=r==null?DateTime.now():DateTime.parse(field(r,'start'));_end=r==null?DateTime(_start.year+1,_start.month,_start.day):DateTime.parse(field(r,'end'));_active=r==null||number(r,'active')==1;
  }
  @override void dispose(){for(final c in _controllers.values){c.dispose();}super.dispose();}
  int? _money(String s,{bool zero=false})=>parseMoney(s,allowZero:zero);
  Widget _text(String key,String label,{bool required=false,int max=100})=>Padding(padding:const EdgeInsets.only(bottom:16),child:TextFormField(controller:_controllers[key],maxLength:max,maxLines:key=='note'?3:1,decoration:InputDecoration(labelText:label,counterText:''),validator:(s)=>required && (s??'').trim().isEmpty?'এই ঘরটি পূরণ করুন':null));
  Widget _amount(String key,String label,{bool zero=false})=>Padding(padding:const EdgeInsets.only(bottom:16),child:TextFormField(controller:_controllers[key],keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:label),validator:(s)=>_money(s??'',zero:zero)==null?'সঠিক টাকার পরিমাণ দিন':null));
  Widget _date(bool end)=>ListTile(contentPadding:EdgeInsets.zero,title:Text(end?'মেয়াদ শেষ':'শুরুর / কেনার তারিখ'),subtitle:Text(formatDate(end?_end:_start)),trailing:const Icon(Icons.calendar_month_outlined),onTap:()async{final d=await showDatePicker(context:context,initialDate:end?_end:_start,firstDate:DateTime(1900),lastDate:DateTime(2200));if(d!=null)setState((){if(end){_end=d;}else{_start=d;}});});
  Future<void> _save() async {
    if(_busy || !_form.currentState!.validate())return;setState(()=>_busy=true);
    try {
      final r=<String,Object?>{'kind':_kind,for(final k in ['title','institution','reference','subtype','note']) k:_controllers[k]!.text.trim(),'amount_minor':_money(_controllers['amount']!.text,zero:_account),'value_minor':_loan||_kind=='investment'?_money(_controllers['value']!.text,zero:true):0,'rate_bps':_saving?_money(_controllers['rate']!.text,zero:true):0,'months_paid':_kind=='dps'?int.tryParse(toEnglish(_controllers['paid']!.text)):0,'active':_active?1:0,'start':_start.toIso8601String(),'end':_end.toIso8601String()};
      await (await PortfolioStore.open()).save(r,id:widget.record?['id'] as int?);if(mounted)Navigator.pop(context);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e is FormatException?e.message:'সংরক্ষণ হয়নি। আবার চেষ্টা করুন।')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:Text('${financeLabels[_kind]} ${widget.record==null?'যোগ':'সম্পাদনা'}')),body:Form(key:_form,child:ListView(padding:const EdgeInsets.all(20),children:[
    _text('title',_loan?'ব্যক্তির নাম':'হিসাবের নাম',required:true),
    if(!_loan && _kind!='cash')_text('institution',_kind=='investment'?'প্রতিষ্ঠান / ব্রোকার':'ব্যাংক / প্রতিষ্ঠান'),
    if(_kind=='bank')...[_text('reference','অ্যাকাউন্ট নম্বর'),_text('subtype','শাখার নাম')],
    if(_kind=='cash')_text('subtype','ধরন: হাতে নগদ / ওয়ালেট / জরুরি তহবিল'),
    if(_kind=='investment')_text('subtype','ধরন: শেয়ার / ফান্ড / জমি / অন্যান্য'),
    if(_kind=='certificate')_text('subtype','স্কিম: পরিবার / পেনশনার / ৩-মাস / অন্যান্য',required:true),
    _amount('amount',_account?'শুরুর ব্যালেন্স (টাকা)':_kind=='dps'?'মাসিক কিস্তি (টাকা)':_loan?'মোট ধারের পরিমাণ (টাকা)':'মূলধন / বিনিয়োগ (টাকা)',zero:_account),
    if(_account)const Padding(padding:EdgeInsets.only(bottom:16),child:Text('শুরুর ব্যালেন্সের সঙ্গে অ্যাকাউন্টের জমা/উত্তোলন যোগ হবে। বর্তমান ব্যালেন্স লিখে ইতিহাসের টাকা আবার যোগ করবেন না।',style:TextStyle(fontSize:12))),
    if(_kind=='investment'||_loan)_amount('value',_loan?'ইতিমধ্যে পরিশোধ (টাকা)':'বর্তমান বাজারমূল্য (টাকা)',zero:true),
    if(_saving)...[
      TextFormField(controller:_controllers['rate'],keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'বার্ষিক লাভের হার (%)',helperText:'নিজের চুক্তি অনুযায়ী হার দিন; ০-ও দেওয়া যাবে।'),validator:(s){final v=_money(s??'',zero:true);return v==null||v>10000?'০ থেকে ১০০-এর মধ্যে হার দিন':null;}),const SizedBox(height:16),
    ],
    if(!_account)_date(false),if(_saving)_date(true),
    if(_kind=='dps')TextFormField(controller:_controllers['paid'],keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'ইতিমধ্যে জমা দেওয়া মাসের সংখ্যা'),validator:(s){final v=int.tryParse(toEnglish(s??''));return v==null||v<0||v>600?'০–৬০০-এর মধ্যে সংখ্যা দিন':null;}),
    if(_saving)...[SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('সক্রিয় হিসাবে রাখুন'),subtitle:const Text('বন্ধ করলে নিট সম্পদে গণনা হবে না।'),value:_active,onChanged:(v)=>setState(()=>_active=v)),const Text('DPS অনুমান: প্রতি মাসের শুরুতে কিস্তি ও মাসিক চক্রবৃদ্ধি। FDR/সঞ্চয়পত্র: বার্ষিক হার ÷ ৩৬৫ দিয়ে সরল লাভ। কর/ফি/নিয়মভেদে প্রকৃত প্রাপ্য আলাদা হতে পারে।',style:TextStyle(fontSize:12)),const SizedBox(height:16)],
    _text('note','নোট',max:2000),FilledButton(onPressed:_busy?null:_save,child:Text(_busy?'সংরক্ষণ হচ্ছে…':'সংরক্ষণ করুন')),
  ])));
}
