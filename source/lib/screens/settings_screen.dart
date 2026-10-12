import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../main.dart';
import '../database/db_helper.dart';
import '../services/backup.dart';
import '../services/app_lock.dart';
import '../services/biometrics.dart';
import '../finance/finance_screen.dart';
import '../services/reminders.dart';
import '../utils/formatters.dart';
import 'item_editor.dart';

class SettingsScreen extends StatefulWidget {
  final Future<void> Function() onDataChanged;
  const SettingsScreen({super.key,required this.onDataChanged});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;
  String _reminder = 'বন্ধ';
  bool _biometric=false;
  @override void initState() { super.initState(); _loadReminder(); _loadBiometric(); }
  Future<void> _loadBiometric() async {try{final v=await Biometrics.enabled();if(mounted)setState(()=>_biometric=v);}catch(_){}}
  Future<void> _biometricToggle() async {
    if(!preferences.pinEnabled){_message('আগে PIN চালু করুন; biometric না হলে PIN ব্যবহার করবেন।');return;}
    await Biometrics.setEnabled(!_biometric);await _loadBiometric();
  }
  Future<void> _profile() async {
    final current=await DbHelper.instance.setting('profile_name')??'';
    if(!mounted)return;final c=TextEditingController(text:current);
    final name=await showDialog<String>(context:context,builder:(ctx)=>AlertDialog(title:const Text('আপনার নাম'),content:TextField(controller:c,maxLength:60,decoration:const InputDecoration(labelText:'নাম (ঐচ্ছিক)')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('বাদ দিন')),FilledButton(onPressed:()=>Navigator.pop(ctx,c.text.trim()),child:const Text('সংরক্ষণ'))]));
    if(name!=null){await DbHelper.instance.setSetting('profile_name',name);await widget.onDataChanged();}
  }
  Future<void> _clearData() async {
    final c=TextEditingController();
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(title:const Text('সব হিসাব মুছবেন?'),content:Column(mainAxisSize:MainAxisSize.min,children:[const Text('আগে JSON backup রাখুন। সব লেনদেন, সম্পদ, ধার, বাজেট, লক্ষ্য ও নোট মুছে যাবে। নিশ্চিত করতে DELETE লিখুন।'),TextField(controller:c,decoration:const InputDecoration(labelText:'DELETE'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('বাদ দিন')),FilledButton(onPressed:(){if(c.text=='DELETE')Navigator.pop(ctx,true);},child:const Text('সব হিসাব মুছুন'))]));
    if(ok!=true)return;
    if(preferences.pinEnabled){if(!mounted)return;final pin=await Navigator.push<String>(context,MaterialPageRoute(builder:(_)=>const PinEditor(removing:true)));if(pin==null || !await AppLock.verify(pin))return;}
    await (await DbHelper.instance.db).transaction((txn) async {for(final table in Backup.tables.where((t)=>t!='categories')){await txn.delete(table);}});
    await widget.onDataChanged();_message('সব হিসাব মুছে দেওয়া হয়েছে। PIN ও পছন্দের সেটিং রাখা হয়েছে।');
  }
  Future<void> _loadReminder() async {
    try { final s = await DbHelper.instance.setting('reminder'); if (mounted) setState(() => _reminder = s ?? 'বন্ধ'); } catch (_) { /* Existing setting can be retried. */ }
  }
  void _message(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s))); }
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try { await action(); } catch (_) { _message('কাজটি সম্পন্ন হয়নি। ফাইল, permission বা PIN যাচাই করে আবার চেষ্টা করুন।'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _export(bool csv) async {
    final content = csv ? await Backup.exportCsv() : await Backup.exportJson();
    final result = await FilePicker.platform.saveFile(dialogTitle:'Backup সংরক্ষণ করুন',fileName:'amar-taka-${DateTime.now().millisecondsSinceEpoch}.${csv ? 'csv' : 'json'}',bytes:Uint8List.fromList(utf8.encode(content)));
    if (result != null) _message('ফাইল সংরক্ষণ হয়েছে।');
  }
  Future<void> _restore() async {
    final result = await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['json'],withData:true);
    if (result == null || !mounted) return;
    final bytes = result.files.single.bytes;
    if (bytes == null || bytes.length > 10 * 1024 * 1024) throw const FormatException('Invalid size');
    final text = utf8.decode(bytes); final data = Backup.validate(text);
    if (!mounted) return;
    final ok = await showDialog<bool>(context:context,builder:(ctx) => AlertDialog(title:const Text('বর্তমান হিসাব প্রতিস্থাপন করবেন?'),content:Text('এই ফাইলে ${toBangla('${data['transactions']!.length}')}টি লেনদেন আছে।\n\nবর্তমান লেনদেন, সম্পদ, অ্যাকাউন্ট, ধার, বাজেট, লক্ষ্য ও নোটের জায়গায় ফাইলের হিসাব আসবে। পুরোনো backup-এ নতুন হিসাবগুলো না থাকলে সেগুলো খালি হবে। আগে নিজের বর্তমান JSON backup রাখুন। PIN বদলাবে না।'),actions:[TextButton(onPressed:() => Navigator.pop(ctx,false),child:const Text('বাদ দিন')),FilledButton(onPressed:() => Navigator.pop(ctx,true),child:const Text('প্রতিস্থাপন করুন'))]));
    if (ok != true) return;
    await Backup.restore(text); await widget.onDataChanged(); _message('হিসাব ফিরিয়ে আনা হয়েছে।');
  }
  Future<void> _pin() async {
    final enabled = preferences.pinEnabled;
    final input = await Navigator.push<String>(context,MaterialPageRoute(builder:(_) => PinEditor(removing:enabled)));
    if (input == null) return;
    if (enabled) { await AppLock.remove(input); } else { await AppLock.set(input); }
    await preferences.refreshPin(); await _loadBiometric(); if (mounted) setState(() {});
    _message(enabled ? 'PIN বন্ধ হয়েছে।' : 'PIN চালু হয়েছে।');
  }
  Future<void> _remind() async {
    final choice = await showDialog<String>(context:context,builder:(ctx) => SimpleDialog(title:const Text('রিমাইন্ডার'),children:[for (final e in {'daily':'প্রতিদিন','monthly':'প্রতি মাসের ১ তারিখ','off':'বন্ধ করুন'}.entries) SimpleDialogOption(onPressed:() => Navigator.pop(ctx,e.key),child:Text(e.value))]));
    if (choice == null || !mounted) return;
    await Reminders.init();
    if (choice == 'off') { await Reminders.cancel(); await DbHelper.instance.setSetting('reminder','বন্ধ'); }
    else {
      final time = await showTimePicker(context:context,initialTime:const TimeOfDay(hour:21,minute:0),helpText:'বাংলাদেশ সময় (UTC+6)');
      if (time == null) return;
      await Reminders.schedule(time.hour,time.minute,day:choice == 'monthly' ? 1 : null);
      await DbHelper.instance.setSetting('reminder','${choice == 'daily' ? 'প্রতিদিন' : 'মাসের ১ তারিখ'} ${toBangla('${time.hour.toString().padLeft(2,'0')}:${time.minute.toString().padLeft(2,'0')}')} • বাংলাদেশ সময়');
    }
    await _loadReminder();
  }
  @override Widget build(BuildContext context) => AbsorbPointer(absorbing:_busy,child:ListView(padding:const EdgeInsets.all(18),children:[
    if (_busy) const LinearProgressIndicator(),
    Card(child:ListTile(leading:const Icon(Icons.account_balance_wallet_outlined),title:const Text('সম্পদ ও দায়'),subtitle:const Text('ব্যাংক, ক্যাশ, DPS, FDR, বিনিয়োগ, ধার–দেনা'),trailing:const Icon(Icons.chevron_right),onTap:()async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>const FinanceScreen()));await widget.onDataChanged();})),
    Card(child:ListTile(leading:const Icon(Icons.person_outline),title:const Text('আপনার নাম'),onTap:()=>_run(_profile))),
    SwitchListTile(title:const Text('Fingerprint / Face lock'),subtitle:const Text('PIN চালু থাকতে হবে; ফোনের biometric ব্যবহার হবে।'),value:_biometric,onChanged:(_)=>_run(_biometricToggle)),
    Card(child:ListTile(leading:const Icon(Icons.menu_book_outlined),title:const Text('নোটবুক'),subtitle:const Text('মনে রাখার কথা ও দরকারি হিসাব'),trailing:const Icon(Icons.chevron_right),onTap:() => Navigator.push(context,MaterialPageRoute(builder:(_) => const NotebookScreen())))),
    const SizedBox(height:18),const Text('আপনার পছন্দ',style:TextStyle(fontSize:20,fontWeight:FontWeight.w600)),const SizedBox(height:12),
    DropdownButtonFormField<String>(initialValue:preferences.theme,decoration:const InputDecoration(labelText:'থিম'),items:const [DropdownMenuItem(value:'system',child:Text('ফোনের সেটিং অনুসারে')),DropdownMenuItem(value:'light',child:Text('হালকা')),DropdownMenuItem(value:'dark',child:Text('ডার্ক')),DropdownMenuItem(value:'amoled',child:Text('AMOLED কালো'))],onChanged:(v) { if (v != null) _run(() => preferences.setTheme(v)); }),
    Card(child:ListTile(leading:const Icon(Icons.lock_outline),title:Text(preferences.pinEnabled ? 'PIN বন্ধ করুন' : '৬ সংখ্যার PIN চালু করুন'),subtitle:const Text('ফোনে ফিরে এলে আবার PIN লাগবে'),onTap:() => _run(_pin))),
    Card(child:ListTile(leading:const Icon(Icons.notifications_none),title:const Text('হিসাব লেখার রিমাইন্ডার'),subtitle:Text('$_reminder\nসময় কিছুটা এদিক-ওদিক হতে পারে।'),onTap:() => _run(_remind))),
    const SizedBox(height:20),const Text('আপনার ডেটা',style:TextStyle(fontSize:20,fontWeight:FontWeight.w600)),
    const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('JSON-এ সম্পূর্ণ backup; CSV-তে শুধু লেনদেনের রিপোর্ট। Export করা ফাইলে PIN বা encryption থাকে না—নিজের নিরাপদ জায়গায় রাখুন।')),
    Card(child:Column(children:[ListTile(leading:const Icon(Icons.save_alt),title:const Text('JSON backup রাখুন'),onTap:() => _run(() => _export(false))),ListTile(leading:const Icon(Icons.table_view_outlined),title:const Text('CSV রিপোর্ট নিন'),onTap:() => _run(() => _export(true))),ListTile(leading:const Icon(Icons.restore),title:const Text('JSON backup ফিরিয়ে আনুন'),onTap:() => _run(_restore))])),
    TextButton.icon(onPressed:()=>_run(_clearData),icon:const Icon(Icons.delete_forever_outlined),label:const Text('সব হিসাব মুছুন')),
    const SizedBox(height:24),const Text('Amar Taka',style:TextStyle(fontSize:24,fontWeight:FontWeight.bold)),const Text('by MEskander • 0.4.0'),const SizedBox(height:12),
    const Text('কোনো লগইন, ব্যাংক সংযোগ বা server লাগে না। হিসাব ফোনের app storage-এ থাকে। PIN অ্যাপ খোলা নিয়ন্ত্রণ করে; database নিজে encrypt করা নয়। অ্যাপ uninstall করলে local data মুছে যাবে।'),
    TextButton(onPressed:() => showLicensePage(context:context,applicationName:'Amar Taka',applicationVersion:'0.4.0',applicationLegalese:'by MEskander'),child:const Text('ওপেন সোর্স লাইসেন্স')),
  ]));
}
class PinEditor extends StatefulWidget {
  final bool removing;
  const PinEditor({super.key,required this.removing});
  @override State<PinEditor> createState() => _PinEditorState();
}
class _PinEditorState extends State<PinEditor> {
  final _pin = TextEditingController(),_confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  @override void dispose() { _pin.dispose(); _confirm.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:Text(widget.removing ? 'বর্তমান PIN দিন' : 'নতুন PIN তৈরি করুন')),body:Form(key:_form,child:ListView(padding:const EdgeInsets.all(24),children:[
    const Text('PIN ভুলে গেলে এই অ্যাপের মাধ্যমে recover করা যাবে না। নিয়মিত JSON backup রাখুন।'),const SizedBox(height:24),
    TextFormField(controller:_pin,obscureText:true,keyboardType:TextInputType.number,maxLength:6,decoration:const InputDecoration(labelText:'৬ সংখ্যার PIN'),validator:(v) => RegExp(r'^\d{6}$').hasMatch(toEnglish(v ?? '')) ? null : 'ঠিক ৬টি সংখ্যা দিন'),
    if (!widget.removing) TextFormField(controller:_confirm,obscureText:true,keyboardType:TextInputType.number,maxLength:6,decoration:const InputDecoration(labelText:'আবার PIN দিন'),validator:(v) => toEnglish(v ?? '') == toEnglish(_pin.text) ? null : 'দুইবার একই PIN দিন'),
    const SizedBox(height:20),FilledButton(onPressed:() { if (_form.currentState!.validate()) Navigator.pop(context,toEnglish(_pin.text)); },child:const Text('নিশ্চিত করুন')),
  ])));
}
class NotebookScreen extends StatefulWidget {
  const NotebookScreen({super.key});
  @override State<NotebookScreen> createState() => _NotebookScreenState();
}
class _NotebookScreenState extends State<NotebookScreen> {
  late Future<List<Map<String,Object?>>> _future;
  @override void initState() { super.initState(); _future = DbHelper.instance.items('notes'); }
  void _reload() => setState(() => _future = DbHelper.instance.items('notes'));
  Future<void> _edit([Map<String,Object?>? item]) async { await Navigator.push(context,MaterialPageRoute(builder:(_) => ItemEditor(goal:false,item:item))); if (mounted) _reload(); }
  @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text('নোটবুক')),floatingActionButton:FloatingActionButton(onPressed:() => _edit(),child:const Icon(Icons.add)),body:FutureBuilder<List<Map<String,Object?>>>(future:_future,builder:(context,snapshot) {
    if (snapshot.hasError) return Center(child:TextButton(onPressed:_reload,child:const Text('আবার চেষ্টা করুন')));
    if (!snapshot.hasData) return const Center(child:CircularProgressIndicator());
    if (snapshot.data!.isEmpty) return const Center(child:Text('প্রথম নোট লিখতে + চাপুন।'));
    return ListView(padding:const EdgeInsets.fromLTRB(18,18,18,100),children:snapshot.data!.map((m) => Card(child:ListTile(onTap:() => _edit(m),title:Text(m['title'] as String),subtitle:Text(m['body'] as String,maxLines:3,overflow:TextOverflow.ellipsis),trailing:IconButton(tooltip:'নোট মুছুন',icon:const Icon(Icons.delete_outline),onPressed:() async {
      final ok = await showDialog<bool>(context:context,builder:(ctx) => AlertDialog(title:const Text('নোটটি মুছে ফেলবেন?'),actions:[TextButton(onPressed:() => Navigator.pop(ctx,false),child:const Text('না')),FilledButton(onPressed:() => Navigator.pop(ctx,true),child:const Text('মুছুন'))]));
      if (ok != true) return;
      try { await DbHelper.instance.deleteItem('notes',m['id'] as int); if (mounted) _reload(); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('মুছে ফেলা যায়নি।'))); }
    })))).toList());
  }));
}
