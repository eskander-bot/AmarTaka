import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import '../theme/app_theme.dart';

class BalanceCard extends StatefulWidget {
  final int balance;
  const BalanceCard({super.key,required this.balance});
  @override State<BalanceCard> createState() => _BalanceCardState();
}
class _BalanceCardState extends State<BalanceCard> {
  bool _visible = true;
  @override Widget build(BuildContext context) => Container(
    clipBehavior:Clip.antiAlias,
    decoration:BoxDecoration(borderRadius:BorderRadius.circular(24),color:const Color(0xFF344ECC),boxShadow:[BoxShadow(color:const Color(0xFF344ECC).withValues(alpha:0.16),blurRadius:20,offset:const Offset(0,8))]),
    child:Stack(children:[
      Positioned(right:-30,top:-68,child:IgnorePointer(child:Container(width:210,height:210,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:Colors.white.withValues(alpha:0.06),width:28))))),
      Padding(padding:const EdgeInsets.fromLTRB(22,16,22,20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[const Icon(Icons.account_balance_wallet_outlined,color:Color(0xFFD0D9FF),size:18),const SizedBox(width:8),const Expanded(child:Text('মোট ব্যালেন্স',style:TextStyle(color:Color(0xFFDCE3FF),fontSize:14))),IconButton(tooltip:_visible ? 'ব্যালেন্স আড়াল করুন' : 'ব্যালেন্স দেখুন',onPressed:() => setState(() => _visible = !_visible),icon:Icon(_visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,color:const Color(0xFFDCE3FF),size:19))]),
        Semantics(label:_visible ? 'মোট ব্যালেন্স ${formatMinor(widget.balance)}' : 'ব্যালেন্স আড়াল করা আছে',excludeSemantics:true,child:FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(_visible ? formatMinor(widget.balance) : '৳ ••••••',maxLines:1,style:const TextStyle(color:Colors.white,fontSize:34,height:1.35,fontWeight:FontWeight.w600,letterSpacing:0.2)))),
        const SizedBox(height:14),Row(children:[Container(width:6,height:6,decoration:const BoxDecoration(color:Color(0xFF91E8CA),shape:BoxShape.circle)),const SizedBox(width:7),const Expanded(child:Text('সব সময়ের আয় ও ব্যয়ের হিসাব',style:TextStyle(color:Color(0xFFD0D9FF),fontSize:11))),const Icon(Icons.shield_outlined,size:16,color:Color(0xFFD0D9FF))]),
      ])),
    ]),
  );
}
class SummaryCard extends StatelessWidget {
  final String label; final int amount; final bool income;
  const SummaryCard({super.key,required this.label,required this.amount,required this.income});
  @override Widget build(BuildContext context) {
    final c = income ? AppColors.incomeFor(context) : AppColors.expenseFor(context);
    return Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Container(padding:const EdgeInsets.all(6),decoration:BoxDecoration(color:c.withValues(alpha:0.10),borderRadius:BorderRadius.circular(9)),child:Icon(income ? Icons.south_west_rounded : Icons.north_east_rounded,size:16,color:c)),const SizedBox(width:8),Expanded(child:Text(label,style:Theme.of(context).textTheme.bodySmall))]),
      const SizedBox(height:12),FittedBox(fit:BoxFit.scaleDown,alignment:Alignment.centerLeft,child:Text(formatMinor(amount),maxLines:1,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontSize:21,height:1.3))),
    ])));
  }
}
class BudgetCard extends StatelessWidget {
  final int spent; final int? budget; final VoidCallback onEdit;
  const BudgetCard({super.key,required this.spent,required this.budget,required this.onEdit});
  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final over = budget != null && spent > budget!;
    final color = over ? AppColors.expenseFor(context) : cs.primary;
    return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:cs.primaryContainer,borderRadius:BorderRadius.circular(12)),child:Icon(Icons.donut_large_rounded,color:cs.primary,size:21)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('মাসের বাজেট',style:Theme.of(context).textTheme.titleMedium),Text(budget == null ? 'খরচের সীমা ঠিক করুন' : over ? 'বাজেটের সীমা ছাড়িয়েছে' : 'আপনার খরচের অগ্রগতি',style:Theme.of(context).textTheme.bodySmall)])),IconButton(tooltip:budget == null ? 'বাজেট নির্ধারণ' : 'বাজেট বদলান',onPressed:onEdit,icon:Icon(budget == null ? Icons.add_circle_outline : Icons.edit_outlined,size:21,color:cs.primary))]),
      if (budget != null) ...[
        const SizedBox(height:17),LayoutBuilder(builder:(context,box) => Wrap(alignment:WrapAlignment.spaceBetween,spacing:14,runSpacing:4,children:[Text(formatMinor(spent),style:Theme.of(context).textTheme.titleMedium),Text('সীমা ${formatMinor(budget!)}',style:Theme.of(context).textTheme.bodySmall)])),
        const SizedBox(height:9),LinearProgressIndicator(value:(spent/budget!).clamp(0.0,1.0),minHeight:7,borderRadius:BorderRadius.circular(8),backgroundColor:cs.outlineVariant,color:color),const SizedBox(height:9),Text(over ? '${formatMinor(spent-budget!)} বেশি ব্যয় হয়েছে' : '${formatMinor(budget!-spent)} ব্যয় করতে পারবেন',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:color)),
      ],
    ])));
  }
}
class QuickActions extends StatelessWidget {
  final VoidCallback onIncome,onExpense;
  const QuickActions({super.key,required this.onIncome,required this.onExpense});
  @override Widget build(BuildContext context) => LayoutBuilder(builder:(context,box) {
    final buttons = [
      FilledButton.icon(onPressed:onExpense,icon:const Icon(Icons.remove_circle_outline,size:19),label:const Text('ব্যয় যোগ')),
      OutlinedButton.icon(onPressed:onIncome,style:OutlinedButton.styleFrom(backgroundColor:Theme.of(context).colorScheme.surface,padding:const EdgeInsets.symmetric(vertical:15,horizontal:12),side:BorderSide(color:Theme.of(context).colorScheme.outlineVariant),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))),icon:const Icon(Icons.add_circle_outline,size:19),label:const Text('আয় যোগ')),
    ];
    if (MediaQuery.textScalerOf(context).scale(14) > 22) return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[buttons[0],const SizedBox(height:10),buttons[1]]);
    return Row(children:[Expanded(child:buttons[0]),const SizedBox(width:12),Expanded(child:buttons[1])]);
  });
}
