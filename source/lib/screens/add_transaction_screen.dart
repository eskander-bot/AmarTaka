import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
class AddTransactionScreen extends StatefulWidget {
  final Txn? transaction;
  final TxnType initialType;
  const AddTransactionScreen({super.key,this.transaction,this.initialType = TxnType.expense});
  @override State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}
class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(), _note = TextEditingController();
  late TxnType _type; late DateTime _date;
  List<String> _categories = [];
  String? _category,_error;
  bool _loading = true,_saving = false;
  @override void initState() {
    super.initState(); final t = widget.transaction;
    _type = t?.type ?? widget.initialType; _date = t?.date ?? DateTime.now(); _category = t?.category;
    _amount.text = t == null ? '' : moneyInput(t.amountMinor); _note.text = t?.note ?? ''; _loadCategories();
  }
  Future<void> _loadCategories() async {
    final kind = _type;
    setState(() { _loading = true; _error = null; });
    try {
      final cats = await DbHelper.instance.getCategories(kind);
      if (!mounted || kind != _type) return;
      setState(() { _categories = cats; if (!cats.contains(_category)) _category = cats.isEmpty ? null : cats.first; _loading = false; });
    } catch (_) { if (mounted && kind == _type) setState(() { _loading = false; _error = 'ক্যাটাগরি পড়া যায়নি।'; }); }
  }
  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate() || _category == null) return;
    setState(() => _saving = true);
    try {
      await DbHelper.instance.saveTransaction(Txn(id:widget.transaction?.id,amountMinor:parseMoney(_amount.text)!,category:_category!,note:_note.text.trim(),date:_date,type:_type));
      if (mounted) Navigator.pop(context,true);
    } catch (_) { if (mounted) setState(() => _error = 'সংরক্ষণ হয়নি। আবার চেষ্টা করুন।'); }
    finally { if (mounted) setState(() => _saving = false); }
  }
  Future<void> _addCategory() async {
    final c = TextEditingController();
    final name = await showDialog<String>(context:context,builder:(ctx) => AlertDialog(title:const Text('নতুন ক্যাটাগরি'),content:TextField(controller:c,maxLength:60,decoration:const InputDecoration(labelText:'নাম')),actions:[TextButton(onPressed:() => Navigator.pop(ctx),child:const Text('বাদ দিন')),FilledButton(onPressed:() { if (c.text.trim().isNotEmpty) Navigator.pop(ctx,c.text.trim()); },child:const Text('যোগ করুন'))]));
    if (name == null || !mounted) return;
    try { await DbHelper.instance.addCategory(name,_type); _category = name; await _loadCategories(); }
    catch (_) { if (mounted) setState(() => _error = 'ক্যাটাগরি যোগ হয়নি।'); }
  }
  @override void dispose() { _amount.dispose(); _note.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => PopScope(canPop:!_saving,child:Scaffold(appBar:AppBar(title:Text(widget.transaction == null ? 'নতুন লেনদেন' : 'লেনদেন সম্পাদনা')),body:Form(key:_form,child:ListView(padding:const EdgeInsets.all(20),children:[
    SegmentedButton<TxnType>(segments:const [ButtonSegment(value:TxnType.expense,label:Text('ব্যয়')),ButtonSegment(value:TxnType.income,label:Text('আয়'))],selected:{_type},onSelectionChanged:_saving ? null : (s) { setState(() { _type = s.first; _category = null; }); _loadCategories(); }),const SizedBox(height:24),
    TextFormField(controller:_amount,enabled:!_saving,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'টাকার পরিমাণ',prefixText:'৳ ',hintText:'যেমন: ১২৫.৫০'),validator:(s) => parseMoney(s ?? '') == null ? 'সঠিক পরিমাণ দিন (সর্বোচ্চ ২ ঘর পয়সা)।' : null),const SizedBox(height:18),
    if (_loading) const LinearProgressIndicator() else DropdownButtonFormField<String>(key:ValueKey('${_type.name}:$_category'),initialValue:_category,isExpanded:true,items:_categories.map((c) => DropdownMenuItem(value:c,child:Text(categoryLabel(c)))).toList(),onChanged:_saving ? null : (c) => setState(() => _category = c),decoration:const InputDecoration(labelText:'ক্যাটাগরি'),validator:(v) => v == null ? 'ক্যাটাগরি বাছুন' : null),
    Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:_saving || _loading ? null : _addCategory,icon:const Icon(Icons.add),label:const Text('নিজের ক্যাটাগরি'))),
    TextFormField(controller:_note,enabled:!_saving,maxLength:2000,maxLines:3,decoration:const InputDecoration(labelText:'বিবরণ (ঐচ্ছিক)')),const SizedBox(height:14),
    OutlinedButton.icon(icon:const Icon(Icons.calendar_today_outlined),label:Text(formatDate(_date)),onPressed:_saving ? null : () async { final date = await showDatePicker(context:context,initialDate:_date,firstDate:DateTime(1900),lastDate:DateTime(2200)); if (date != null && mounted) setState(() => _date = date); }),
    if (_error != null) Padding(padding:const EdgeInsets.all(12),child:Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
    const SizedBox(height:20),FilledButton(onPressed:_saving || _loading ? null : _save,child:Text(_saving ? 'সংরক্ষণ হচ্ছে…' : 'সংরক্ষণ করুন')),
  ]))));
}
