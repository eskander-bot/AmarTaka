import 'dart:convert';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../finance/portfolio.dart';
import '../services/feature_service.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
class AddTransactionScreen extends StatefulWidget {
  final Txn? transaction;
  final TxnType initialType;
  final bool template,recurring;
  const AddTransactionScreen({super.key,this.transaction,this.template=false,this.recurring=false,this.initialType = TxnType.expense});
  @override State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}
class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(), _note = TextEditingController();
  late TxnType _type; late DateTime _date;
  List<String> _categories = [];
  String? _category,_error;
  int? _account; String _receipt=''; List<Record> _accounts=[];
  final _title=TextEditingController();
  bool _loading = true,_saving = false,_receiptLoaded=false;
  @override void initState() {
    super.initState(); final t = widget.transaction;
    _type = t?.type ?? widget.initialType; _date = t?.date ?? DateTime.now(); _category = t?.category;
    _account=t?.accountId; _receipt=t?.receipt??'';
    _amount.text = t == null ? '' : moneyInput(t.amountMinor); _note.text = t?.note ?? ''; _loadCategories();
  }
  Future<void> _loadCategories() async {
    final kind = _type;
    setState(() { _loading = true; _error = null; });
    try {
      if(!_receiptLoaded && widget.transaction?.id!=null){
        final rows=await (await DbHelper.instance.db).query('transactions',columns:['receipt'],where:'id=?',whereArgs:[widget.transaction!.id]);
        if(rows.isEmpty)throw const FormatException('লেনদেন পাওয়া যায়নি।');
        _receipt=rows.first['receipt'] as String? ?? '';_receiptLoaded=true;
      }
      final cats = await DbHelper.instance.getCategories(kind);
      final accounts=(await (await PortfolioStore.open()).read()).holdings.where(isAccount).toList();
      if (!mounted || kind != _type) return;
      setState(() { _accounts=accounts; _categories = cats; if (!cats.contains(_category)) _category = cats.isEmpty ? null : cats.first; _loading = false; });
    } catch (_) { if (mounted && kind == _type) setState(() { _loading = false; _error = 'ক্যাটাগরি পড়া যায়নি।'; }); }
  }
  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate() || _category == null) return;
    setState(() => _saving = true);
    try {
      final t=Txn(id:widget.transaction?.id,amountMinor:parseMoney(_amount.text)!,category:_category!,note:_note.text.trim(),date:_date,type:_type,accountId:_account,receipt:_receipt);
      if(widget.template) {await FeatureService.saveTemplate(t,_title.text.trim(),start:widget.recurring?DateTime(_date.year,_date.month,_date.day):null);} else {await DbHelper.instance.saveTransaction(t);}
      if (mounted) Navigator.pop(context,true);
    } catch (e) { if (mounted) setState(() => _error = e is FormatException ? e.message : 'সংরক্ষণ হয়নি। আবার চেষ্টা করুন।'); }
    finally { if (mounted) setState(() => _saving = false); }
  }
  Future<void> _pickReceipt() async {
    try {
      final file=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['jpg','jpeg','png','webp'],withData:true);
      if(file==null)return;
      final bytes=file.files.single.bytes;
      if(bytes==null || bytes.length>2*1024*1024) throw const FormatException('ছবিটি সর্বোচ্চ ২ MB হতে হবে।');
      final codec=await ui.instantiateImageCodec(bytes,targetWidth:1200);
      final frame=await codec.getNextFrame();
      final png=await frame.image.toByteData(format:ui.ImageByteFormat.png);
      frame.image.dispose();codec.dispose();
      if(png==null || png.lengthInBytes>2*1024*1024) throw const FormatException('ছবিটি ছোট করে আবার দিন (সর্বোচ্চ ২ MB)।');
      if(mounted)setState(()=>_receipt=base64Encode(png.buffer.asUint8List()));
    } catch(e) {if(mounted)setState(()=>_error=e is FormatException?e.message:'ছবিটি পড়া যায়নি।');}
  }
  Future<void> _addCategory() async {
    final c = TextEditingController();
    final name = await showDialog<String>(context:context,builder:(ctx) => AlertDialog(title:const Text('নতুন ক্যাটাগরি'),content:TextField(controller:c,maxLength:60,decoration:const InputDecoration(labelText:'নাম')),actions:[TextButton(onPressed:() => Navigator.pop(ctx),child:const Text('বাদ দিন')),FilledButton(onPressed:() { if (c.text.trim().isNotEmpty) Navigator.pop(ctx,c.text.trim()); },child:const Text('যোগ করুন'))]));
    if (name == null || !mounted) return;
    try { await DbHelper.instance.addCategory(name,_type); _category = name; await _loadCategories(); }
    catch (_) { if (mounted) setState(() => _error = 'ক্যাটাগরি যোগ হয়নি।'); }
  }
  @override void dispose() { _amount.dispose(); _note.dispose(); _title.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => PopScope(canPop:!_saving,child:Scaffold(appBar:AppBar(title:Text(widget.template ? (widget.recurring?'মাসিক আয়–ব্যয়':'দ্রুত এন্ট্রি শর্টকাট') : widget.transaction?.id == null ? 'নতুন লেনদেন' : 'লেনদেন সম্পাদনা')),body:Form(key:_form,child:ListView(padding:const EdgeInsets.all(20),children:[
    if(widget.template) TextFormField(controller:_title,maxLength:100,decoration:const InputDecoration(labelText:'শর্টকাট / নিয়মের নাম'),validator:(v)=>(v??'').trim().isEmpty?'নাম দিন':null),
    if(widget.recurring) const Padding(padding:EdgeInsets.only(bottom:16),child:Text('নির্ধারিত দিন থেকে প্রতি মাসে অ্যাপ খুললে এন্ট্রি হবে। বন্ধ অ্যাপে এন্ট্রি হবে না। টাকা কম থাকলে নিয়মটি অপেক্ষা করবে।')),
    SegmentedButton<TxnType>(segments:const [ButtonSegment(value:TxnType.expense,label:Text('ব্যয়')),ButtonSegment(value:TxnType.income,label:Text('আয়'))],selected:{_type},onSelectionChanged:_saving ? null : (s) { setState(() { _type = s.first; _category = null; }); _loadCategories(); }),const SizedBox(height:24),
    TextFormField(controller:_amount,enabled:!_saving,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'টাকার পরিমাণ',prefixText:'৳ ',hintText:'যেমন: ১২৫.৫০'),validator:(s) => parseMoney(s ?? '') == null ? 'সঠিক পরিমাণ দিন (সর্বোচ্চ ২ ঘর পয়সা)।' : null),const SizedBox(height:18),
    if (_loading) const LinearProgressIndicator() else DropdownButtonFormField<String>(key:ValueKey('${_type.name}:$_category'),initialValue:_category,isExpanded:true,items:_categories.map((c) => DropdownMenuItem(value:c,child:Text(categoryLabel(c)))).toList(),onChanged:_saving ? null : (c) => setState(() => _category = c),decoration:const InputDecoration(labelText:'ক্যাটাগরি'),validator:(v) => v == null ? 'ক্যাটাগরি বাছুন' : null),
    Align(alignment:Alignment.centerRight,child:TextButton.icon(onPressed:_saving || _loading ? null : _addCategory,icon:const Icon(Icons.add),label:const Text('নিজের ক্যাটাগরি'))),
    if(!_loading) Padding(padding:const EdgeInsets.only(bottom:18),child:DropdownButtonFormField<int>(key:ValueKey(_account),initialValue:_account??0,isExpanded:true,decoration:const InputDecoration(labelText:'অ্যাকাউন্ট'),items:[const DropdownMenuItem<int>(value:0,child:Text('কোনো অ্যাকাউন্ট নয়')), ..._accounts.map((a)=>DropdownMenuItem<int>(value:a['id'] as int,child:Text(a['title'] as String)))],onChanged:_saving?null:(v)=>setState(()=>_account=v==0?null:v))),
    const Text('Cash, bKash, Nagad ও Bank অ্যাকাউন্ট তৈরি করুন: সেটিংস → সম্পদ ও দায়। পুরোনো লেনদেন অ্যাকাউন্টে যুক্ত করলে তার ব্যালেন্স বদলাবে।'),const SizedBox(height:12),
    TextFormField(controller:_note,enabled:!_saving,maxLength:2000,maxLines:3,decoration:const InputDecoration(labelText:'বিবরণ (ঐচ্ছিক)')),const SizedBox(height:14),
    OutlinedButton.icon(icon:const Icon(Icons.calendar_today_outlined),label:Text(formatDate(_date)),onPressed:_saving ? null : () async { final date = await showDatePicker(context:context,initialDate:_date,firstDate:DateTime(1900),lastDate:DateTime(2200)); if (date != null && mounted) setState(() => _date = date); }),
    if(!widget.template) ...[
      OutlinedButton.icon(onPressed:_saving||_loading?null:_pickReceipt,icon:const Icon(Icons.receipt_long_outlined),label:Text(_receipt.isEmpty?'রসিদের ছবি (অফলাইন)':'রসিদের ছবি বদলান')),
      if(_receipt.isNotEmpty) ...[GestureDetector(onTap:()=>showDialog<void>(context:context,builder:(c)=>Dialog(child:Column(mainAxisSize:MainAxisSize.min,children:[Flexible(child:InteractiveViewer(child:Image.memory(base64Decode(_receipt),errorBuilder:(_,e,s)=>const Text('ছবি পড়া যায়নি')))),TextButton(onPressed:()=>Navigator.pop(c),child:const Text('বন্ধ করুন'))]))),child:Image.memory(base64Decode(_receipt),height:160,fit:BoxFit.contain,errorBuilder:(_,e,s)=>const Text('ছবি পড়া যায়নি'))),TextButton(onPressed:_saving||_loading?null:()=>setState(()=>_receipt=''),child:const Text('ছবিটি সরান'))],
    ],
    if (_error != null) Padding(padding:const EdgeInsets.all(12),child:Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error))),
    const SizedBox(height:20),FilledButton(onPressed:_saving || _loading ? null : _save,child:Text(_saving ? 'সংরক্ষণ হচ্ছে…' : 'সংরক্ষণ করুন')),
  ]))));
}
