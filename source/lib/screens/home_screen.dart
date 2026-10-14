import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/db_helper.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';
import '../widgets/finance_cards.dart';
import '../widgets/home_cards.dart';
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
  final List<Map<String,Object?>> notes;
  const LedgerOverview({required this.transactions,this.goals = const [],this.notes = const [],this.budget,this.portfolio=const Portfolio(),this.profileName=''});
}
class HomeScreen extends StatefulWidget {
  final Future<LedgerOverview> Function(DateTime month)? loadData;
  const HomeScreen({super.key,this.loadData});
  @override State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0; DateTime _month = DateTime(DateTime.now().year,DateTime.now().month);
  List<Txn> _all = []; List<Map<String,Object?>> _goals = []; List<Map<String,Object?>> _notes = [];
  int _quote = DateTime.now().day+DateTime.now().month*31;
  final _searchCtl = TextEditingController();
  @override void dispose() { _searchCtl.dispose(); super.dispose(); }
  Portfolio _portfolio=const Portfolio(); String _profileName='';
  int? _budget; String _search = ''; TxnType? _kind;
  bool _loading = true,_busy = false; String? _error;
  int _request = 0;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    final request = ++_request;
    try {
      final data = widget.loadData == null ? LedgerOverview(transactions:await DbHelper.instance.getTransactions(),goals:await DbHelper.instance.items('goals'),notes:await DbHelper.instance.items('notes'),budget:await DbHelper.instance.budget(_month),portfolio:await (await PortfolioStore.open()).read(),profileName:await DbHelper.instance.setting('profile_name')??'') : await widget.loadData!(_month);
      final all = data.transactions; final goals = data.goals; final budget = data.budget;
      if (!mounted || request != _request) return;
      setState(() { _all = all; _notes = data.notes; _portfolio=data.portfolio; _profileName=data.profileName; _goals = goals; _budget = budget; _loading = false; _error = null; });
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
  Widget _monthPicker() {
    final cs = Theme.of(context).colorScheme;
    Widget arrow(String tip,IconData icon,int step) => IconButton.filledTonal(tooltip:tip,style:IconButton.styleFrom(backgroundColor:cs.surface,side:BorderSide(color:cs.outlineVariant)),onPressed:() { setState(() => _month = DateTime(_month.year,_month.month+step)); _load(); },icon:Icon(icon,size:20));
    return Padding(padding:const EdgeInsets.symmetric(vertical:14),child:Row(children:[arrow('আগের মাস',Icons.chevron_left,-1),Expanded(child:Text(monthLabel(_month),textAlign:TextAlign.center,style:Theme.of(context).textTheme.titleMedium)),arrow('পরের মাস',Icons.chevron_right,1)]));
  }
  static const _quotes = [
    'ছোট ছোট সঞ্চয়ই একদিন বড় সুরক্ষা হয়ে ওঠে।',
    'আজ কত খরচ হলো লিখে রাখুন, কাল কত বাঁচবে বুঝতে পারবেন।',
    'আয় হাতে এলেই আগে সঞ্চয়ের অংশটা আলাদা করে রাখুন।',
    'প্রয়োজন আর শখের তফাত বুঝলেই বাজেট সহজ হয়।',
    'ধৈর্য ধরে জমানো টাকাই সবচেয়ে নির্ভরযোগ্য বন্ধু।',
    'প্রতিদিনের হিসাব রাখা মানে নিজের টাকার নিয়ন্ত্রণ নিজের হাতে রাখা।',
    'বড় লক্ষ্যকে ভেঙে ছোট ছোট মাসিক ধাপে ভাগ করে নিন।',
  ];
  static const _weekdays = ['সোমবার','মঙ্গলবার','বুধবার','বৃহস্পতিবার','শুক্রবার','শনিবার','রবিবার'];
  static const _weekdayShort = ['সোম','মঙ্গল','বুধ','বৃহ','শুক্র','শনি','রবি'];
  String get _greeting { final h = DateTime.now().hour; return h < 5 ? 'শুভ রাত্রি' : h < 12 ? 'সুপ্রভাত' : h < 16 ? 'শুভ দুপুর' : h < 19 ? 'শুভ বিকাল' : 'শুভ সন্ধ্যা'; }
  String get _today { final d = DateTime.now(); return '${_weekdays[d.weekday-1]}, ${toBangla('${d.day}')} ${monthNames[d.month-1]} ${toBangla('${d.year}')}'; }
  Future<void> _openSettings() async { await Navigator.push(context,MaterialPageRoute(builder:(_) => Scaffold(appBar:AppBar(title:const Text('সেটিংস')),body:SettingsScreen(onDataChanged:_load)))); if (mounted) await _load(); }
  Future<void> _editNote([Map<String,Object?>? m]) async { await Navigator.push(context,MaterialPageRoute(builder:(_) => ItemEditor(goal:false,item:m))); if (mounted) await _load(); }
  Widget _title(String text) => Padding(padding:const EdgeInsets.only(top:14,bottom:4),child:Row(children:[Container(width:5,height:24,decoration:BoxDecoration(color:Theme.of(context).colorScheme.primary,borderRadius:BorderRadius.circular(4))),const SizedBox(width:10),Expanded(child:GradientText(text,style:Theme.of(context).textTheme.headlineSmall))]));
  Widget _header() {
    final cs = Theme.of(context).colorScheme;
    final initial = _profileName.isEmpty ? 'আ' : String.fromCharCode(_profileName.runes.first);
    return Padding(padding:const EdgeInsets.only(top:12),child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        GradientText(_profileName.isEmpty ? '$_greeting!' : '$_greeting, $_profileName!',maxLines:2,style:Theme.of(context).textTheme.headlineSmall),
        Text(_today,style:Theme.of(context).textTheme.bodySmall),
      ])),
      const SizedBox(width:12),
      Tooltip(message:'সেটিংস',child:InkWell(customBorder:const CircleBorder(),onTap:_openSettings,child:Container(width:44,height:44,alignment:Alignment.center,decoration:BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:[cs.primary,const Color(0xFF2DB6E8)])),child:Text(initial,style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.w600))))),
    ]));
  }
  Widget _empty(String text,IconData icon) => Padding(padding:const EdgeInsets.symmetric(vertical:40,horizontal:20),child:Column(children:[Icon(icon,size:40,color:Theme.of(context).colorScheme.outline),const SizedBox(height:14),Text(text,textAlign:TextAlign.center)]));
  Widget _heading(String title,{Widget? action}) => Padding(padding:const EdgeInsets.only(top:14,bottom:4),child:Row(children:[Expanded(child:Text(title,style:Theme.of(context).textTheme.titleLarge)),if (action != null) action]));
  Widget _transaction(Txn t) {
    final income = t.type == TxnType.income;
    final color = income ? AppColors.incomeFor(context) : AppColors.expenseFor(context);
    final style = CategoryStyle.of(t.category,income);
    final amount = Text('${income ? '+' : '−'} ${formatMinor(t.amountMinor)}',style:TextStyle(color:color,fontSize:14,fontWeight:FontWeight.w600));
    return Card(child:InkWell(borderRadius:BorderRadius.circular(20),onTap:() => _editTransaction(t),child:Padding(padding:const EdgeInsets.fromLTRB(14,13,0,13),child:LayoutBuilder(builder:(context,box) {
      final wide = box.maxWidth > 330 && MediaQuery.textScalerOf(context).scale(14) < 19;
      return Row(children:[
        Container(width:44,height:44,decoration:BoxDecoration(color:style.color.withValues(alpha:0.16),borderRadius:BorderRadius.circular(14)),child:Icon(style.icon,color:style.color,size:23)),const SizedBox(width:12),
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
    final now = DateTime.now();
    final todayExpense = _sum(_all.where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day),TxnType.expense);
    final isCurrent = _month.year == now.year && _month.month == now.month;
    final days = isCurrent ? now.day : _month.isAfter(now) ? 1 : DateTime(_month.year,_month.month+1,0).day;
    final cs = Theme.of(context).colorScheme;
    final tiles = [
      StatTile(icon:Icons.today_outlined,color:AppColors.expenseFor(context),value:formatMinor(todayExpense),label:'আজকের খরচ'),
      StatTile(icon:Icons.insights_outlined,color:cs.primary,value:formatMinor(expense ~/ days),label:'দৈনিক গড়'),
      StatTile(icon:Icons.receipt_long_outlined,color:const Color(0xFF6366F1),value:toBangla('${_monthly.length}'),label:'মোট লেনদেন'),
    ];
    final big = MediaQuery.textScalerOf(context).scale(14) > 22;
    final week = List.generate(7,(i) {
      final d = DateTime(now.year,now.month,now.day-6+i);
      final rows = _all.where((t) => t.date.year == d.year && t.date.month == d.month && t.date.day == d.day);
      return DayTotals(_weekdayShort[d.weekday-1],_sum(rows,TxnType.income),_sum(rows,TxnType.expense));
    });
    final tileRow = big
        ? Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[for (final t in tiles) Padding(padding:const EdgeInsets.only(bottom:8),child:t)])
        : Row(crossAxisAlignment:CrossAxisAlignment.start,children:[for (var i = 0; i < tiles.length; i++) ...[if (i > 0) const SizedBox(width:10),Expanded(child:tiles[i])]]);
    return [
      FadeSlideIn(index:0,child:_header()),const SizedBox(height:14),
      FadeSlideIn(index:1,child:QuoteCard(text:_quotes[_quote % _quotes.length],onRefresh:() => setState(() => _quote++))),
      _monthPicker(),
      FadeSlideIn(index:2,child:DashboardBalanceCard(balance:balance,income:income,expense:expense,savingsRate:FinanceMath.savingsRate(income,expense))),
      const SizedBox(height:12),
      FadeSlideIn(index:3,child:tileRow),
      const SizedBox(height:12),
      FadeSlideIn(index:4,child:QuickAddRow(onIncome:() => _editTransaction(null,TxnType.income),onExpense:() => _editTransaction(null,TxnType.expense))),
      const SizedBox(height:8),
      FadeSlideIn(index:5,child:WeekChartCard(title:'সাপ্তাহিক আয় বনাম ব্যয়',days:week)),
      FadeSlideIn(index:6,child:_budgetCard()),
      _heading('সাম্প্রতিক লেনদেন',action:TextButton(onPressed:() => setState(() => _tab = 1),child:const Text('সব দেখুন'))),
      if (_monthly.isEmpty) _empty('এখনও কোনো লেনদেন নেই।\nনিচের + চেপে আয় বা ব্যয় যোগ করুন।',Icons.receipt_long_outlined),..._monthly.take(8).map(_transaction),
    ];
  }
  Widget _total(String title,int n,Color color) => Container(constraints:const BoxConstraints(minWidth:140),padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(18)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:TextStyle(color:color)),const SizedBox(height:6),Text(formatMinor(n),style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18))]));
  List<Widget> _history() {
    final query = _search.toLowerCase();
    final rows = _monthly.where((t) => (_kind == null || t.type == _kind) && '${categoryLabel(t.category)} ${t.category} ${t.note} ${moneyInput(t.amountMinor)}'.toLowerCase().contains(toEnglish(query))).toList();
    return [_title('ইতিহাস'),_monthPicker(),TextField(controller:_searchCtl,decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'ক্যাটাগরি, বিবরণ বা টাকা খুঁজুন'),onChanged:(v) => setState(() => _search = v)),const SizedBox(height:12),Wrap(spacing:8,children:[ChoiceChip(label:const Text('সব'),selected:_kind == null,onSelected:(_) => setState(() => _kind = null)),...TxnType.values.map((t) => ChoiceChip(label:Text(t == TxnType.income ? 'আয়' : 'ব্যয়'),selected:_kind == t,onSelected:(_) => setState(() => _kind = t)))]),const SizedBox(height:10),Text('${toBangla('${rows.length}')}টি লেনদেন'),if (rows.isEmpty) _empty('কোনো লেনদেন পাওয়া যায়নি।',Icons.search_off),...List.generate(rows.length,(i)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[if(i==0 || formatDate(rows[i-1].date)!=formatDate(rows[i].date))Padding(padding:const EdgeInsets.only(top:14,bottom:5),child:Text(formatDate(rows[i].date),style:Theme.of(context).textTheme.titleSmall)),_transaction(rows[i])]))];
  }
  List<Widget> _budgetTab() => [
    _title('বাজেট'),
    BalanceCard(balance:_portfolio.netWorth,label:'নিট সম্পদ',caption:'আপনার সম্পদ থেকে দায় বাদ দিয়ে'),
    const SizedBox(height:8),HealthCard(income:_sum(_monthly,TxnType.income),expense:_sum(_monthly,TxnType.expense),portfolio:_portfolio),
    _monthPicker(),_budgetCard(),
    Card(child:ListTile(leading:const Icon(Icons.pie_chart_outline),title:const Text('ক্যাটাগরি অনুযায়ী বাজেট'),trailing:const Icon(Icons.chevron_right),onTap:_categoryBudgets)),
    _financeLink(),
    AllocationCard(portfolio:_portfolio,onOpen:_finance),
    Card(child:ListTile(leading:const Icon(Icons.savings_outlined),title:const Text('সঞ্চয়'),subtitle:const Text('DPS, FDR ও সঞ্চয়পত্র'),trailing:const Icon(Icons.chevron_right),onTap:() async {await Navigator.push(context,MaterialPageRoute(builder:(_)=>const FinanceScreen(savingsOnly:true)));if(mounted)await _load();})),
  ];
  List<Widget> _goalsTab() => [_title('ইচ্ছা ও সঞ্চয়'),if (_goals.isEmpty) _empty('আপনার প্রথম সঞ্চয়ের লক্ষ্য যোগ করতে নিচের + চাপুন।',Icons.star_outline_rounded),..._goals.map((g) {
    final target = g['target_minor'] as int,saved = g['saved_minor'] as int;
    return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(g['title'] as String,style:Theme.of(context).textTheme.titleMedium)),IconButton(tooltip:'লক্ষ্য সম্পাদনা',onPressed:() => _editGoal(g),icon:const Icon(Icons.edit_outlined)),IconButton(tooltip:'লক্ষ্য মুছুন',onPressed:() async { if (!await _confirm('এই সঞ্চয়ের লক্ষ্য মুছে যাবে।')) return; try { await DbHelper.instance.deleteItem('goals',g['id'] as int); await _load(); } catch (_) { _message('মুছে ফেলা যায়নি।'); } },icon:const Icon(Icons.delete_outline))]),Text('${formatMinor(saved)} / ${formatMinor(target)}'),const SizedBox(height:12),LinearProgressIndicator(value:(saved/target).clamp(0.0,1.0),minHeight:7,borderRadius:BorderRadius.circular(5)),const SizedBox(height:10),Text(saved >= target ? 'লক্ষ্য পূরণ হয়েছে!' : 'আরও ${formatMinor(target-saved)} প্রয়োজন'),if ((g['note'] as String).isNotEmpty) Text(g['note'] as String)])));
  })];
  List<Widget> _notesTab() => [_title('নোট'),if (_notes.isEmpty) _empty('প্রথম নোট লিখতে নিচের + চাপুন।',Icons.edit_note_outlined),..._notes.map((m) => Card(child:ListTile(onTap:() => _editNote(m),title:Text(m['title'] as String),subtitle:Text(m['body'] as String,maxLines:3,overflow:TextOverflow.ellipsis),trailing:IconButton(tooltip:'নোট মুছুন',icon:const Icon(Icons.delete_outline),onPressed:() async { if (!await _confirm('এই নোটটি মুছে যাবে।')) return; try { await DbHelper.instance.deleteItem('notes',m['id'] as int); await _load(); } catch (_) { _message('মুছে ফেলা যায়নি।'); } }))))];
  List<Widget> _reports() {
    final categories = <String,int>{}; final rows = _monthly;
    for (final t in rows.where((t) => t.type == TxnType.expense)) { categories.update(t.category,(v) => v+t.amountMinor,ifAbsent:() => t.amountMinor); }
    final entries = categories.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final expense = _sum(rows,TxnType.expense),income = _sum(rows,TxnType.income);
    return [_title('বিশ্লেষণ'),_monthPicker(),FinanceCharts(transactions:_all,month:_month),Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('সঞ্চয়ের হার: ${toBangla(FinanceMath.savingsRate(income,expense).toStringAsFixed(1))}%'),Text('হিসাবের স্কোর: ${toBangla("${FinanceMath.health(income:income,expense:expense,liquid:_portfolio.total('cash')+_portfolio.total('bank'),debt:_portfolio.liabilities,assets:_portfolio.assets)}")}/১০০'),const Text('নিজস্ব সূচক: সঞ্চয়ের হার ৪০, ৬ মাসের নগদ সুরক্ষা ৩৫, সম্পদের তুলনায় দায় ২৫। এটি কোনো ব্যাংকের credit score নয়।',style:TextStyle(fontSize:11))]))),_total('মাসের নিট আয়–ব্যয়',income-expense,AppColors.primary),_heading('কোথায় কত ব্যয়'),if (entries.isEmpty) _empty('ব্যয় যোগ করলে এখানে রিপোর্ট দেখাবে।',Icons.bar_chart),...entries.map((e) => Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${categoryLabel(e.key)} • ${formatMinor(e.value)}'),const SizedBox(height:10),LinearProgressIndicator(value:e.value/expense,minHeight:9,borderRadius:BorderRadius.circular(6)),const SizedBox(height:5),Text('${toBangla((100*e.value/expense).toStringAsFixed(1))}%')])))),
      _heading('গত ৬ মাস'),...List.generate(6,(i) { final d = DateTime(_month.year,_month.month-5+i); final list = _all.where((t) => t.date.year == d.year && t.date.month == d.month); return Card(child:ListTile(title:Text(monthLabel(d)),subtitle:Text('আয় ${formatMinor(_sum(list,TxnType.income))}\nব্যয় ${formatMinor(_sum(list,TxnType.expense))}'),isThreeLine:true)); }),
      _heading('গত ৭ দিনের ব্যয়'),...List.generate(7,(i) { final now = DateTime.now(); final d = DateTime(now.year,now.month,now.day-6+i); final list = _all.where((t) => t.date.year == d.year && t.date.month == d.month && t.date.day == d.day); return ListTile(title:Text(formatDate(d)),trailing:Text(formatMinor(_sum(list,TxnType.expense)))); }),
    ];
  }
  @override Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final Widget content = _loading
        ? const Center(key:ValueKey('loading'),child:CircularProgressIndicator())
        : _error != null
            ? Center(key:const ValueKey('error'),child:Column(mainAxisSize:MainAxisSize.min,children:[Text(_error!),TextButton(onPressed:_load,child:const Text('আবার চেষ্টা'))]))
            : KeyedSubtree(key:ValueKey('tab$_tab'),child:RefreshIndicator(onRefresh:_load,child:ListView(primary:false,physics:const BouncingScrollPhysics(parent:AlwaysScrollableScrollPhysics()),padding:const EdgeInsets.fromLTRB(20,0,20,96),children:switch (_tab) { 0 => _dashboard(),1 => _history(),2 => _reports(),3 => _budgetTab(),4 => _goalsTab(),_ => _notesTab() })));
    return AnnotatedRegion<SystemUiOverlayStyle>(value:dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,child:PopScope(canPop:_tab == 0,onPopInvokedWithResult:(didPop,_) { if (!didPop) setState(() => _tab = 0); },child:Scaffold(
      bottomNavigationBar:AppBottomBar(selected:_tab,onSelect:(i) => setState(() => _tab = i)),
      floatingActionButton:switch (_tab) {
        0 => null,
        4 => FloatingActionButton(heroTag:null,onPressed:() => _editGoal(),tooltip:'নতুন লক্ষ্য',child:const Icon(Icons.add)),
        5 => FloatingActionButton(heroTag:null,onPressed:() => _editNote(),tooltip:'নতুন নোট',child:const Icon(Icons.add)),
        _ => FloatingActionButton(heroTag:null,onPressed:() => _editTransaction(),tooltip:'নতুন লেনদেন',child:const Icon(Icons.add)),
      },
      body:SafeArea(bottom:false,child:AnimatedSwitcher(duration:const Duration(milliseconds:260),switchInCurve:Curves.easeOutCubic,transitionBuilder:(child,animation) => FadeTransition(opacity:animation,child:SlideTransition(position:Tween<Offset>(begin:const Offset(0.03,0),end:Offset.zero).animate(animation),child:child)),child:content)),
    )));
  }
}
