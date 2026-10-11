import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import 'add_transaction_screen.dart';
import 'item_editor.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; DateTime _month = DateTime(DateTime.now().year,DateTime.now().month);
  List<Txn> _all = []; List<Map<String,Object?>> _goals = [];
  int? _budget; String _search = ''; TxnType? _kind;
  bool _loading = true,_busy = false; String? _error;
  int _request = 0;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final request = ++_request;
    try {
      final all = await DbHelper.instance.getTransactions();
      final goals = await DbHelper.instance.items('goals');
      final budget = await DbHelper.instance.budget(_month);
      if (!mounted || request != _request) return;
      setState(() { _all = all; _goals = goals; _budget = budget; _loading = false; _error = null; });
    } catch (_) { if (mounted && request == _request) setState(() { _loading = false; _error = 'হিসাব পড়া যায়নি। আবার চেষ্টা করুন।'; }); }
  }
  List<Txn> get _monthly => _all.where((t) => t.date.year == _month.year && t.date.month == _month.month).toList();
  int _sum(Iterable<Txn> rows,TxnType type) => rows.where((t) => t.type == type).fold(0,(n,t) => n+t.amountMinor);
  void _message(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s))); }
  Future<void> _editTransaction([Txn? t]) async { await Navigator.push(context,MaterialPageRoute(builder:(_) => AddTransactionScreen(transaction:t))); if (mounted) await _load(); }
  Future<void> _editGoal([Map<String,Object?>? m]) async { await Navigator.push(context,MaterialPageRoute(builder:(_) => ItemEditor(goal:true,item:m))); if (mounted) await _load(); }
  Future<bool> _confirm(String text) async => await showDialog<bool>(context:context,builder:(ctx) => AlertDialog(title:const Text('মুছে ফেলবেন?'),content:Text(text),actions:[TextButton(onPressed:() => Navigator.pop(ctx,false),child:const Text('না')),FilledButton(onPressed:() => Navigator.pop(ctx,true),child:const Text('মুছুন'))])) ?? false;
  Future<void> _delete(Txn t) async {
    if (_busy || !await _confirm('এই লেনদেনটি স্থায়ীভাবে মুছে যাবে।')) return;
    _busy = true;
    try { await DbHelper.instance.deleteTransaction(t.id!); await _load(); } catch (_) { _message('মুছে ফেলা যায়নি।'); } finally { _busy = false; }
  }
  Future<void> _setBudget() async {
    final c = TextEditingController(text:_budget == null ? '' : moneyInput(_budget!));
    final form = GlobalKey<FormState>();
    final amount = await showDialog<int>(context:context,builder:(ctx) => AlertDialog(title:Text('${monthLabel(_month)}-এর বাজেট'),content:Form(key:form,child:TextFormField(controller:c,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'মোট ব্যয়সীমা (টাকা)'),validator:(v) => parseMoney(v ?? '') == null ? 'সঠিক পরিমাণ দিন' : null)),actions:[TextButton(onPressed:() => Navigator.pop(ctx),child:const Text('বাদ দিন')),FilledButton(onPressed:() { if (form.currentState!.validate()) Navigator.pop(ctx,parseMoney(c.text)); },child:const Text('সংরক্ষণ'))]));
    if (amount == null) return;
    try { await DbHelper.instance.setBudget(_month,amount); await _load(); } catch (_) { _message('বাজেট সংরক্ষণ হয়নি।'); }
  }
  Widget _monthPicker() => Row(mainAxisAlignment:MainAxisAlignment.center,children:[IconButton(tooltip:'আগের মাস',onPressed:() { setState(() => _month = DateTime(_month.year,_month.month-1)); _load(); },icon:const Icon(Icons.chevron_left)),Expanded(child:Text(monthLabel(_month),textAlign:TextAlign.center,style:const TextStyle(fontWeight:FontWeight.w600))),IconButton(tooltip:'পরের মাস',onPressed:() { setState(() => _month = DateTime(_month.year,_month.month+1)); _load(); },icon:const Icon(Icons.chevron_right))]);
  Widget _empty(String text,IconData icon) => Padding(padding:const EdgeInsets.symmetric(vertical:40,horizontal:20),child:Column(children:[Icon(icon,size:40,color:Theme.of(context).colorScheme.outline),const SizedBox(height:14),Text(text,textAlign:TextAlign.center)]));
  Widget _heading(String title,{Widget? action}) => Padding(padding:const EdgeInsets.only(top:22,bottom:12),child:Row(children:[Expanded(child:Text(title,style:Theme.of(context).textTheme.titleLarge)),if (action != null) action]));
  Widget _transaction(Txn t) {
    final income = t.type == TxnType.income;
    final color = income ? AppColors.income : AppColors.expense;
    return Card(child:InkWell(borderRadius:BorderRadius.circular(22),onTap:() => _editTransaction(t),child:Padding(padding:const EdgeInsets.fromLTRB(14,14,4,14),child:Row(children:[
      CircleAvatar(backgroundColor:color.withValues(alpha:0.12),child:Icon(income ? Icons.south_west : Icons.north_east,color:color)),const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(categoryLabel(t.category),style:const TextStyle(fontWeight:FontWeight.w600)),Text('${formatDate(t.date)}${t.note.isEmpty ? '' : ' • ${t.note}'}',maxLines:2,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall),const SizedBox(height:4),Text('${income ? '+' : '−'} ${formatMinor(t.amountMinor)}',style:TextStyle(color:color,fontWeight:FontWeight.bold))])),
      PopupMenuButton<String>(tooltip:'লেনদেনের অপশন',onSelected:(v) { if (v == 'edit') { _editTransaction(t); } else { _delete(t); } },itemBuilder:(_) => const [PopupMenuItem(value:'edit',child:Text('সম্পাদনা')),PopupMenuItem(value:'delete',child:Text('মুছুন'))]),
    ]))));
  }
  Widget _budgetCard() {
    final spent = _sum(_monthly,TxnType.expense);
    return Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[const Expanded(child:Text('মাসের বাজেট',style:TextStyle(fontWeight:FontWeight.bold))),TextButton(onPressed:_setBudget,child:Text(_budget == null ? 'নির্ধারণ' : 'বদলান'))]),
      if (_budget == null) const Text('ব্যয়ের একটি সীমা ঠিক করে শুরু করুন।') else ...[
        Text('${formatMinor(spent)} / ${formatMinor(_budget!)}'),const SizedBox(height:12),LinearProgressIndicator(value:(spent/_budget!).clamp(0.0,1.0),minHeight:8,borderRadius:BorderRadius.circular(4),color:spent > _budget! ? AppColors.expense : null),const SizedBox(height:12),Text(spent > _budget! ? 'সীমা ছাড়িয়েছে ${formatMinor(spent-_budget!)}' : 'বাকি আছে ${formatMinor(_budget!-spent)}'),
      ],
    ])));
  }
  List<Widget> _dashboard() {
    final income = _sum(_monthly,TxnType.income),expense = _sum(_monthly,TxnType.expense);
    final balance = _sum(_all,TxnType.income)-_sum(_all,TxnType.expense);
    return [
      const SizedBox(height:10),Text('হিসাব থাকুক নিজের হাতে',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:6),const Text('আপনার ফোনে, আপনার হিসাব।'),const SizedBox(height:22),
      Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:const Color(0xFF244E40),borderRadius:BorderRadius.circular(26)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('সব লেনদেনের মোট ব্যালেন্স',style:TextStyle(color:Color(0xFFCEE0D7))),const SizedBox(height:8),FittedBox(fit:BoxFit.scaleDown,child:Text(formatMinor(balance),style:const TextStyle(color:Colors.white,fontSize:34,fontWeight:FontWeight.bold))),const SizedBox(height:14),const Row(children:[Icon(Icons.offline_pin_outlined,color:Color(0xFFCEE0D7),size:16),SizedBox(width:6),Text('অফলাইনে সংরক্ষিত',style:TextStyle(color:Color(0xFFCEE0D7)))] )])),
      _monthPicker(),Wrap(spacing:12,runSpacing:12,children:[_total('মাসের আয়',income,AppColors.income),_total('মাসের ব্যয়',expense,AppColors.expense)]),const SizedBox(height:10),_budgetCard(),
      _heading('সাম্প্রতিক লেনদেন',action:TextButton(onPressed:() => setState(() => _tab = 1),child:const Text('সব দেখুন'))),
      if (_monthly.isEmpty) _empty('এই মাসে হিসাব নেই।\n+ বাটনে প্রথম লেনদেন যোগ করুন।',Icons.receipt_long_outlined),..._monthly.take(8).map(_transaction),
    ];
  }
  Widget _total(String title,int n,Color color) => Container(constraints:const BoxConstraints(minWidth:140),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(color:color)),const SizedBox(height:6),Text(formatMinor(n),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18))]));
  List<Widget> _history() {
    final query = _search.toLowerCase();
    final rows = _monthly.where((t) => (_kind == null || t.type == _kind) && '${categoryLabel(t.category)} ${t.category} ${t.note} ${moneyInput(t.amountMinor)}'.toLowerCase().contains(toEnglish(query))).toList();
    return [_monthPicker(),TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ক্যাটাগরি, বিবরণ বা টাকা খুঁজুন'),onChanged:(v) => setState(() => _search = v)),const SizedBox(height:12),Wrap(spacing:8,children:[ChoiceChip(label:const Text('সব'),selected:_kind == null,onSelected:(_) => setState(() => _kind = null)),...TxnType.values.map((t) => ChoiceChip(label:Text(t == TxnType.income ? 'আয়' : 'ব্যয়'),selected:_kind == t,onSelected:(_) => setState(() => _kind = t)))]),const SizedBox(height:10),Text('${toBangla('${rows.length}')}টি লেনদেন'),if (rows.isEmpty) _empty('কোনো লেনদেন পাওয়া যায়নি।',Icons.search_off),...rows.map(_transaction)];
  }
  List<Widget> _plans() => [_monthPicker(),_budgetCard(),_heading('ইচ্ছা ও সঞ্চয়',action:IconButton(tooltip:'নতুন লক্ষ্য',onPressed:() => _editGoal(),icon:const Icon(Icons.add))),if (_goals.isEmpty) _empty('আপনার প্রথম সঞ্চয়ের লক্ষ্য যোগ করুন।',Icons.savings_outlined),..._goals.map((g) {
    final target = g['target_minor'] as int,saved = g['saved_minor'] as int;
    return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(g['title'] as String,style:Theme.of(context).textTheme.titleMedium)),IconButton(tooltip:'লক্ষ্য সম্পাদনা',onPressed:() => _editGoal(g),icon:const Icon(Icons.edit_outlined)),IconButton(tooltip:'লক্ষ্য মুছুন',onPressed:() async { if (!await _confirm('এই সঞ্চয়ের লক্ষ্য মুছে যাবে।')) return; try { await DbHelper.instance.deleteItem('goals',g['id'] as int); await _load(); } catch (_) { _message('মুছে ফেলা যায়নি।'); } },icon:const Icon(Icons.delete_outline))]),Text('${formatMinor(saved)} / ${formatMinor(target)}'),const SizedBox(height:12),LinearProgressIndicator(value:(saved/target).clamp(0.0,1.0),minHeight:7,borderRadius:BorderRadius.circular(5)),const SizedBox(height:10),Text(saved >= target ? 'লক্ষ্য পূরণ হয়েছে!' : 'আরও ${formatMinor(target-saved)} প্রয়োজন'),if ((g['note'] as String).isNotEmpty) Text(g['note'] as String)])));
  })];
  List<Widget> _reports() {
    final categories = <String,int>{}; final rows = _monthly;
    for (final t in rows.where((t) => t.type == TxnType.expense)) { categories.update(t.category,(v) => v+t.amountMinor,ifAbsent:() => t.amountMinor); }
    final entries = categories.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final expense = _sum(rows,TxnType.expense),income = _sum(rows,TxnType.income);
    return [_monthPicker(),_total('মাসের নিট আয়–ব্যয়',income-expense,AppColors.primary),_heading('কোথায় কত ব্যয়'),if (entries.isEmpty) _empty('ব্যয় যোগ করলে এখানে রিপোর্ট দেখাবে।',Icons.bar_chart),...entries.map((e) => Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${categoryLabel(e.key)} • ${formatMinor(e.value)}'),const SizedBox(height:10),LinearProgressIndicator(value:e.value/expense,minHeight:9,borderRadius:BorderRadius.circular(6)),const SizedBox(height:5),Text('${toBangla((100*e.value/expense).toStringAsFixed(1))}%')])))),
      _heading('গত ৬ মাস'),...List.generate(6,(i) { final d = DateTime(_month.year,_month.month-5+i); final list = _all.where((t) => t.date.year == d.year && t.date.month == d.month); return Card(child:ListTile(title:Text(monthLabel(d)),subtitle:Text('আয় ${formatMinor(_sum(list,TxnType.income))}\nব্যয় ${formatMinor(_sum(list,TxnType.expense))}'),isThreeLine:true)); }),
      _heading('গত ৭ দিনের ব্যয়'),...List.generate(7,(i) { final now = DateTime.now(); final d = DateTime(now.year,now.month,now.day-6+i); final list = _all.where((t) => t.date.year == d.year && t.date.month == d.month && t.date.day == d.day); return ListTile(title:Text(formatDate(d)),trailing:Text(formatMinor(_sum(list,TxnType.expense)))); }),
    ];
  }
  @override Widget build(BuildContext context) {
    const labels = ['হোম','লেনদেন','পরিকল্পনা','রিপোর্ট','আরও'];
    return Scaffold(appBar:AppBar(title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(_tab == 0 ? 'Amar Taka' : labels[_tab]),if (_tab == 0) const Text('by MEskander',style:TextStyle(fontSize:11))]),actions:[IconButton(tooltip:'রিফ্রেশ',onPressed:_load,icon:const Icon(Icons.refresh))]),
      bottomNavigationBar:NavigationBar(selectedIndex:_tab,onDestinationSelected:(i) => setState(() => _tab = i),destinations:const [NavigationDestination(icon:Icon(Icons.home_outlined),label:'হোম'),NavigationDestination(icon:Icon(Icons.receipt_long_outlined),label:'লেনদেন'),NavigationDestination(icon:Icon(Icons.savings_outlined),label:'পরিকল্পনা'),NavigationDestination(icon:Icon(Icons.bar_chart),label:'রিপোর্ট'),NavigationDestination(icon:Icon(Icons.tune),label:'আরও')]),
      floatingActionButton:_tab <= 1 ? FloatingActionButton.extended(onPressed:() => _editTransaction(),icon:const Icon(Icons.add),label:const Text('লেনদেন')) : null,
      body:_loading ? const Center(child:CircularProgressIndicator()) : _error != null ? Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error!),TextButton(onPressed:_load,child:const Text('আবার চেষ্টা'))])) : _tab == 4 ? SettingsScreen(onDataChanged:_load) : RefreshIndicator(onRefresh:_load,child:ListView(padding:const EdgeInsets.fromLTRB(18,4,18,100),children:switch (_tab) { 0 => _dashboard(),1 => _history(),2 => _plans(),_ => _reports() })),
    );
  }
}
