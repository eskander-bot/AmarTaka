import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../widgets/finance_cards.dart';
import '../widgets/wealth_cards.dart';
import '../finance/portfolio.dart';
import '../finance/finance_screen.dart';
import '../finance/category_budgets.dart';
import '../finance/finance_charts.dart';
import 'add_transaction_screen.dart';
import 'item_editor.dart';
import 'settings_screen.dart';

class LedgerOverview {
  final List<Txn> transactions;
  final List<Map<String,Object?>> goals;
  final Portfolio portfolio;
  final String profileName;
  final int? budget;
  const LedgerOverview({required this.transactions,this.goals = const [],this.budget,this.portfolio=const Portfolio(),this.profileName=''});
}
class HomeScreen extends StatefulWidget {
  final Future<LedgerOverview> Function(DateTime month)? loadData;
  const HomeScreen({super.key,this.loadData});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; DateTime _month = DateTime(DateTime.now().year,DateTime.now().month);
  List<Txn> _all = []; List<Map<String,Object?>> _goals = [];
  Portfolio _portfolio=const Portfolio(); String _profileName='';
  int? _budget; String _search = ''; TxnType? _kind;
  bool _loading = true,_busy = false; String? _error;
  int _request = 0;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final request = ++_request;
    try {
      final data = widget.loadData == null ? LedgerOverview(transactions:await DbHelper.instance.getTransactions(),goals:await DbHelper.instance.items('goals'),budget:await DbHelper.instance.budget(_month),portfolio:await (await PortfolioStore.open()).read(),profileName:await DbHelper.instance.setting('profile_name')??'') : await widget.loadData!(_month);
      final all = data.transactions; final goals = data.goals; final budget = data.budget;
      if (!mounted || request != _request) return;
      setState(() { _all = all; _portfolio=data.portfolio; _profileName=data.profileName; _goals = goals; _budget = budget; _loading = false; _error = null; });
    } catch (_) { if (mounted && request == _request) setState(() { _loading = false; _error = 'হিসাব পড়া যায়নি। আবার চেষ্টা করুন।'; }); }
  }
  List<Txn> get _monthly => _all.where((t) => t.date.year == _month.year && t.date.month == _month.month).toList();
  int _sum(Iterable<Txn> rows,TxnType type) => rows.where((t) => t.type == type).fold(0,(n,t) => n+t.amountMinor);
  void _message(String s) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(s))); }
  Future<void> _editTransaction([Txn? t,TxnType? initialType]) async { await Navigator.push(context,MaterialPageRoute(builder:(_) => AddTransactionScreen(transaction:t,initialType:initialType ?? TxnType.expense))); if (mounted) await _load(); }
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
  Widget _monthPicker() => Padding(padding:const EdgeInsets.only(top:18,bottom:8),child:Row(children:[
    const Icon(Icons.calendar_month_outlined,size:17),const SizedBox(width:7),Expanded(child:Text(monthLabel(_month),style:Theme.of(context).textTheme.titleMedium)),
    IconButton(tooltip:'আগের মাস',visualDensity:VisualDensity.compact,onPressed:() { setState(() => _month = DateTime(_month.year,_month.month-1)); _load(); },icon:const Icon(Icons.chevron_left,size:21)),
    IconButton(tooltip:'পরের মাস',visualDensity:VisualDensity.compact,onPressed:() { setState(() => _month = DateTime(_month.year,_month.month+1)); _load(); },icon:const Icon(Icons.chevron_right,size:21)),
  ]));
  Widget _empty(String text,IconData icon) => Padding(padding:const EdgeInsets.symmetric(vertical:40,horizontal:20),child:Column(children:[Icon(icon,size:40,color:Theme.of(context).colorScheme.outline),const SizedBox(height:14),Text(text,textAlign:TextAlign.center)]));
  Widget _heading(String title,{Widget? action}) => Padding(padding:const EdgeInsets.only(top:14,bottom:4),child:Row(children:[Expanded(child:Text(title,style:Theme.of(context).textTheme.titleLarge)),if (action != null) action]));
  Widget _transaction(Txn t) {
    final income = t.type == TxnType.income;
    final color = income ? AppColors.incomeFor(context) : AppColors.expenseFor(context);
    final icons = <String,IconData>{'Bazar':Icons.shopping_bag_outlined,'Transport':Icons.directions_bus_outlined,'Bills':Icons.receipt_outlined,'Health':Icons.favorite_border,'Education':Icons.school_outlined,'Salary':Icons.work_outline,'Freelance':Icons.laptop_mac_outlined,'Gift':Icons.card_giftcard_outlined};
    final amount = Text('${income ? '+' : '−'} ${formatMinor(t.amountMinor)}',style:TextStyle(color:color,fontSize:14,fontWeight:FontWeight.w600));
    return Card(child:InkWell(borderRadius:BorderRadius.circular(20),onTap:() => _editTransaction(t),child:Padding(padding:const EdgeInsets.fromLTRB(14,13,0,13),child:LayoutBuilder(builder:(context,box) {
      final wide = box.maxWidth > 330 && MediaQuery.textScalerOf(context).scale(14) < 19;
      return Row(children:[
        Container(width:42,height:42,decoration:BoxDecoration(color:color.withValues(alpha:0.10),borderRadius:BorderRadius.circular(13)),child:Icon(icons[t.category] ?? (income ? Icons.south_west_rounded : Icons.north_east_rounded),color:color,size:21)),const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(categoryLabel(t.category),style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:3),Text('${formatDate(t.date)}${t.note.isEmpty ? '' : ' • ${t.note}'}',maxLines:1,overflow:TextOverflow.ellipsis,style:Theme.of(context).textTheme.bodySmall),if (!wide) ...[const SizedBox(height:5),amount]])),
        if (wide) ...[const SizedBox(width:8),amount],
        PopupMenuButton<String>(tooltip:'লেনদেনের অপশন',icon:Icon(Icons.more_vert,size:19,color:Theme.of(context).colorScheme.onSurfaceVariant),onSelected:(v) { if (v == 'edit') { _editTransaction(t); } else { _delete(t); } },itemBuilder:(_) => const [PopupMenuItem(value:'edit',child:Text('সম্পাদনা')),PopupMenuItem(value:'delete',child:Text('মুছুন'))]),
      ]);
    }))));
  }
  Widget _budgetCard() => BudgetCard(spent:_sum(_monthly,TxnType.expense),budget:_budget,onEdit:_setBudget);
  Future<void> _finance() async { await Navigator.push(context,MaterialPageRoute(builder:(_)=>const FinanceScreen())); if(mounted)await _load(); }
  Future<void> _categoryBudgets() async { await Navigator.push(context,MaterialPageRoute(builder:(_)=>CategoryBudgetsScreen(month:_month))); if(mounted)await _load(); }
  Widget _financeLink()=>Card(child:ListTile(leading:const Icon(Icons.account_balance_wallet_outlined),title:const Text('সম্পদ ও দায়'),subtitle:Text('নিট সম্পদ ${formatMinor(_portfolio.netWorth)}'),trailing:const Icon(Icons.chevron_right),onTap:_finance));
  List<Widget> _dashboard() {
    final income = _sum(_monthly,TxnType.income),expense = _sum(_monthly,TxnType.expense);
    final balance = _sum(_all,TxnType.income)-_sum(_all,TxnType.expense);
    return [
      if(_profileName.isNotEmpty)Padding(padding:const EdgeInsets.only(top:10),child:Text('স্বাগতম, $_profileName')),
      Padding(padding:const EdgeInsets.only(top:8,bottom:14),child:Text(DateTime.now().hour<12?'শুভ সকাল':DateTime.now().hour<17?'শুভ অপরাহ্ণ':'শুভ সন্ধ্যা',style:Theme.of(context).textTheme.bodySmall)),
      BalanceCard(balance:_portfolio.netWorth,label:'নিট সম্পদ',caption:'আপনার সম্পদ থেকে দায় বাদ দিয়ে'),
      const SizedBox(height:8),HealthCard(income:income,expense:expense,portfolio:_portfolio),
      AllocationCard(portfolio:_portfolio,onOpen:_finance),
      Card(child:ListTile(leading:const Icon(Icons.savings_outlined),title:const Text('সঞ্চয়'),subtitle:const Text('DPS, FDR ও সঞ্চয়পত্র'),trailing:const Icon(Icons.chevron_right),onTap:() async {await Navigator.push(context,MaterialPageRoute(builder:(_)=>const FinanceScreen(savingsOnly:true)));if(mounted)await _load();})),
      Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text('আয়–ব্যয়ের ব্যালেন্স ${formatMinor(balance)}',style:Theme.of(context).textTheme.titleMedium)),
      QuickActions(onIncome:() => _editTransaction(null,TxnType.income),onExpense:() => _editTransaction(null,TxnType.expense)),
      _monthPicker(),LayoutBuilder(builder:(context,box) {
        final cards = [SummaryCard(label:'মাসের আয়',amount:income,income:true),SummaryCard(label:'মাসের ব্যয়',amount:expense,income:false)];
        if (MediaQuery.textScalerOf(context).scale(14) > 22) return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:cards);
        return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:cards[0]),const SizedBox(width:12),Expanded(child:cards[1])]);
      }),const SizedBox(height:10),_budgetCard(),
      _financeLink(),
      _heading('সাম্প্রতিক লেনদেন',action:TextButton(onPressed:() => setState(() => _tab = 1),child:const Text('সব দেখুন'))),
      if (_monthly.isEmpty) _empty('এখনও কোনো লেনদেন নেই।\nউপরে আয় বা ব্যয় যোগ করুন।',Icons.receipt_long_outlined),..._monthly.take(8).map(_transaction),
    ];
  }
  Widget _total(String title,int n,Color color) => Container(constraints:const BoxConstraints(minWidth:140),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(color:color)),const SizedBox(height:6),Text(formatMinor(n),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18))]));
  List<Widget> _history() {
    final query = _search.toLowerCase();
    final rows = _monthly.where((t) => (_kind == null || t.type == _kind) && '${categoryLabel(t.category)} ${t.category} ${t.note} ${moneyInput(t.amountMinor)}'.toLowerCase().contains(toEnglish(query))).toList();
    return [_monthPicker(),TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ক্যাটাগরি, বিবরণ বা টাকা খুঁজুন'),onChanged:(v) => setState(() => _search = v)),const SizedBox(height:12),Wrap(spacing:8,children:[ChoiceChip(label:const Text('সব'),selected:_kind == null,onSelected:(_) => setState(() => _kind = null)),...TxnType.values.map((t) => ChoiceChip(label:Text(t == TxnType.income ? 'আয়' : 'ব্যয়'),selected:_kind == t,onSelected:(_) => setState(() => _kind = t)))]),const SizedBox(height:10),Text('${toBangla('${rows.length}')}টি লেনদেন'),if (rows.isEmpty) _empty('কোনো লেনদেন পাওয়া যায়নি।',Icons.search_off),...List.generate(rows.length,(i)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[if(i==0 || formatDate(rows[i-1].date)!=formatDate(rows[i].date))Padding(padding:const EdgeInsets.only(top:14,bottom:5),child:Text(formatDate(rows[i].date),style:Theme.of(context).textTheme.titleSmall)),_transaction(rows[i])]))];
  }
  List<Widget> _plans() => [_financeLink(),Card(child:ListTile(leading:const Icon(Icons.pie_chart_outline),title:const Text('ক্যাটাগরি অনুযায়ী বাজেট'),trailing:const Icon(Icons.chevron_right),onTap:_categoryBudgets)),_monthPicker(),_budgetCard(),_heading('ইচ্ছা ও সঞ্চয়',action:IconButton(tooltip:'নতুন লক্ষ্য',onPressed:() => _editGoal(),icon:const Icon(Icons.add))),if (_goals.isEmpty) _empty('আপনার প্রথম সঞ্চয়ের লক্ষ্য যোগ করুন।',Icons.savings_outlined),..._goals.map((g) {
    final target = g['target_minor'] as int,saved = g['saved_minor'] as int;
    return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(g['title'] as String,style:Theme.of(context).textTheme.titleMedium)),IconButton(tooltip:'লক্ষ্য সম্পাদনা',onPressed:() => _editGoal(g),icon:const Icon(Icons.edit_outlined)),IconButton(tooltip:'লক্ষ্য মুছুন',onPressed:() async { if (!await _confirm('এই সঞ্চয়ের লক্ষ্য মুছে যাবে।')) return; try { await DbHelper.instance.deleteItem('goals',g['id'] as int); await _load(); } catch (_) { _message('মুছে ফেলা যায়নি।'); } },icon:const Icon(Icons.delete_outline))]),Text('${formatMinor(saved)} / ${formatMinor(target)}'),const SizedBox(height:12),LinearProgressIndicator(value:(saved/target).clamp(0.0,1.0),minHeight:7,borderRadius:BorderRadius.circular(5)),const SizedBox(height:10),Text(saved >= target ? 'লক্ষ্য পূরণ হয়েছে!' : 'আরও ${formatMinor(target-saved)} প্রয়োজন'),if ((g['note'] as String).isNotEmpty) Text(g['note'] as String)])));
  })];
  List<Widget> _reports() {
    final categories = <String,int>{}; final rows = _monthly;
    for (final t in rows.where((t) => t.type == TxnType.expense)) { categories.update(t.category,(v) => v+t.amountMinor,ifAbsent:() => t.amountMinor); }
    final entries = categories.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final expense = _sum(rows,TxnType.expense),income = _sum(rows,TxnType.income);
    return [_monthPicker(),FinanceCharts(transactions:_all,month:_month),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('সঞ্চয়ের হার: ${toBangla(FinanceMath.savingsRate(income,expense).toStringAsFixed(1))}%'),Text('হিসাবের স্কোর: ${toBangla("${FinanceMath.health(income:income,expense:expense,liquid:_portfolio.total('cash')+_portfolio.total('bank'),debt:_portfolio.liabilities,assets:_portfolio.assets)}")}/১০০'),const Text('নিজস্ব সূচক: সঞ্চয়ের হার ৪০, ৬ মাসের নগদ সুরক্ষা ৩৫, সম্পদের তুলনায় দায় ২৫। এটি কোনো ব্যাংকের credit score নয়।',style:TextStyle(fontSize:11))]))),_total('মাসের নিট আয়–ব্যয়',income-expense,AppColors.primary),_heading('কোথায় কত ব্যয়'),if (entries.isEmpty) _empty('ব্যয় যোগ করলে এখানে রিপোর্ট দেখাবে।',Icons.bar_chart),...entries.map((e) => Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${categoryLabel(e.key)} • ${formatMinor(e.value)}'),const SizedBox(height:10),LinearProgressIndicator(value:e.value/expense,minHeight:9,borderRadius:BorderRadius.circular(6)),const SizedBox(height:5),Text('${toBangla((100*e.value/expense).toStringAsFixed(1))}%')])))),
      _heading('গত ৬ মাস'),...List.generate(6,(i) { final d = DateTime(_month.year,_month.month-5+i); final list = _all.where((t) => t.date.year == d.year && t.date.month == d.month); return Card(child:ListTile(title:Text(monthLabel(d)),subtitle:Text('আয় ${formatMinor(_sum(list,TxnType.income))}\nব্যয় ${formatMinor(_sum(list,TxnType.expense))}'),isThreeLine:true)); }),
      _heading('গত ৭ দিনের ব্যয়'),...List.generate(7,(i) { final now = DateTime.now(); final d = DateTime(now.year,now.month,now.day-6+i); final list = _all.where((t) => t.date.year == d.year && t.date.month == d.month && t.date.day == d.day); return ListTile(title:Text(formatDate(d)),trailing:Text(formatMinor(_sum(list,TxnType.expense)))); }),
    ];
  }
  @override Widget build(BuildContext context) {
    const labels = ['হোম','লেনদেন','পরিকল্পনা','রিপোর্ট','আরও'];
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar:AppBar(toolbarHeight:68,title:_tab == 0 ? Row(children:[
        Container(width:38,height:38,decoration:BoxDecoration(color:cs.primaryContainer,borderRadius:BorderRadius.circular(12)),child:Icon(Icons.account_balance_wallet_rounded,color:cs.primary,size:21)),const SizedBox(width:11),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Amar Taka',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontSize:21,height:1.15)),Text('by MEskander',style:Theme.of(context).textTheme.bodySmall?.copyWith(fontSize:10))])),
      ]) : Text(labels[_tab]),actions:[
        Padding(padding:const EdgeInsets.only(right:12),child:IconButton.filledTonal(tooltip:'রিফ্রেশ',style:IconButton.styleFrom(backgroundColor:cs.surface,side:BorderSide(color:cs.outlineVariant)),onPressed:_load,icon:const Icon(Icons.refresh_rounded,size:20))),
      ]),
      bottomNavigationBar:DecoratedBox(decoration:BoxDecoration(border:Border(top:BorderSide(color:cs.outlineVariant))),child:NavigationBar(selectedIndex:_tab,onDestinationSelected:(i) => setState(() => _tab = i),destinations:const [
        NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home_rounded),label:'হোম'),
        NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long_rounded),label:'লেনদেন'),
        NavigationDestination(icon:Icon(Icons.savings_outlined),selectedIcon:Icon(Icons.savings_rounded),label:'পরিকল্পনা'),
        NavigationDestination(icon:Icon(Icons.bar_chart_rounded),label:'রিপোর্ট'),
        NavigationDestination(icon:Icon(Icons.tune_rounded),label:'আরও'),
      ])),
      floatingActionButton:_tab == 1 ? FloatingActionButton(onPressed:() => _editTransaction(),tooltip:'নতুন লেনদেন',child:const Icon(Icons.add)) : null,
      body:_loading ? const Center(child:CircularProgressIndicator()) : _error != null ? Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error!),TextButton(onPressed:_load,child:const Text('আবার চেষ্টা'))])) : _tab == 4 ? SettingsScreen(onDataChanged:_load) : RefreshIndicator(onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:EdgeInsets.fromLTRB(20,0,20,_tab == 1 ? 90 : 28),children:switch (_tab) { 0 => _dashboard(),1 => _history(),2 => _plans(),_ => _reports() })),
    );
  }
}
