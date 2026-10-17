import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../utils/formatters.dart';
class ItemEditor extends StatefulWidget {
  final bool goal; final Map<String,Object?>? item;
  const ItemEditor({super.key,required this.goal,this.item});
  @override State<ItemEditor> createState() => _ItemEditorState();
}
class _ItemEditorState extends State<ItemEditor> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController(),_body = TextEditingController(),_target = TextEditingController(),_saved = TextEditingController();
  DateTime? _deadline;
  bool _busy = false; String? _error;
  @override void initState() {
    super.initState(); final m = widget.item;
    _deadline=DateTime.tryParse(m?['deadline'] as String? ?? '');
    _title.text = m?['title'] as String? ?? ''; _body.text = m?[widget.goal ? 'note' : 'body'] as String? ?? '';
    _target.text = m == null || !widget.goal ? '' : moneyInput(m['target_minor'] as int);
    _saved.text = m == null || !widget.goal ? '0' : moneyInput(m['saved_minor'] as int);
  }
  int? _savedValue() => RegExp(r'^0+(\.0{1,2})?$').hasMatch(toEnglish(_saved.text.trim())) ? 0 : parseMoney(_saved.text);
  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await DbHelper.instance.saveItem(widget.goal ? 'goals' : 'notes',widget.goal ? {'title':_title.text.trim(),'note':_body.text.trim(),'target_minor':parseMoney(_target.text)!,'saved_minor':_savedValue()!,'deadline':_deadline?.toIso8601String()??'','plan_start':_deadline==null?'':((widget.item?['deadline']==_deadline!.toIso8601String() && widget.item?['plan_start']!='')?widget.item!['plan_start']:DateTime.now().toIso8601String()),'plan_saved':widget.item?['deadline']==_deadline?.toIso8601String()?(widget.item?['plan_saved']??_savedValue()!):_savedValue()!} : {'title':_title.text.trim(),'body':_body.text.trim(),'updated':DateTime.now().toIso8601String()},id:widget.item?['id'] as int?);
      if (mounted) Navigator.pop(context,true);
    } catch (_) { if (mounted) setState(() => _error = 'সংরক্ষণ হয়নি। আবার চেষ্টা করুন।'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override void dispose() { for (final c in [_title,_body,_target,_saved]) { c.dispose(); } super.dispose(); }
  @override Widget build(BuildContext context) => PopScope(canPop:!_busy,child:Scaffold(appBar:AppBar(title:Text(widget.goal ? 'ইচ্ছা ও সঞ্চয়ের লক্ষ্য' : 'নোটবুক')),body:Form(key:_form,child:ListView(padding:const EdgeInsets.all(20),children:[
    TextFormField(controller:_title,enabled:!_busy,maxLength:100,decoration:const InputDecoration(labelText:'শিরোনাম'),validator:(v) => (v ?? '').trim().isEmpty ? 'একটি নাম দিন' : null),
    if (widget.goal) ...[
      const SizedBox(height:14),TextFormField(controller:_target,enabled:!_busy,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'লক্ষ্য (টাকা)'),validator:(v) => parseMoney(v ?? '') == null ? 'সঠিক পরিমাণ দিন' : null),
      const SizedBox(height:14),TextFormField(controller:_saved,enabled:!_busy,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'এখন পর্যন্ত জমা (টাকা)'),validator:(v) => _savedValue() == null ? 'শূন্য অথবা সঠিক পরিমাণ দিন' : null),
      OutlinedButton.icon(icon:const Icon(Icons.event),label:Text(_deadline==null?'লক্ষ্য পূরণের তারিখ দিন':formatDate(_deadline!)),onPressed:_busy?null:() async {final date=await showDatePicker(context:context,initialDate:_deadline??DateTime.now().add(const Duration(days:365)),firstDate:DateTime(1900),lastDate:DateTime(2200));if(date!=null && mounted){if(!date.isAfter(DateTime.now())){setState(()=>_error='ভবিষ্যতের তারিখ দিন।');return;}setState(()=>_deadline=date);}}),
      if(_deadline!=null) TextButton(onPressed:_busy?null:()=>setState(()=>_deadline=null),child:const Text('পরিকল্পনার তারিখ সরান')),
      const Padding(padding:EdgeInsets.symmetric(vertical:16),child:Text('এটি লক্ষ্যের অগ্রগতি। আয়–ব্যয়ের হিসাবে স্বয়ংক্রিয় লেনদেন যোগ হবে না।')),
    ],
    const SizedBox(height:14),TextFormField(controller:_body,enabled:!_busy,maxLines:widget.goal ? 3 : 10,maxLength:widget.goal ? 2000 : 10000,decoration:InputDecoration(labelText:widget.goal ? 'বিবরণ' : 'নোট লিখুন')),
    if (_error != null) Text(_error!),const SizedBox(height:16),FilledButton(onPressed:_busy ? null : _save,child:Text(_busy ? 'সংরক্ষণ হচ্ছে…' : 'সংরক্ষণ করুন')),
  ]))));
}
