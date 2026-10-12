import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class FinanceCharts extends StatelessWidget {
  final List<Txn> transactions;final DateTime month;
  const FinanceCharts({super.key,required this.transactions,required this.month});
  static const palette=[Color(0xFF5168F5),Color(0xFF1FAD87),Color(0xFFED9A51),Color(0xFFB375DD),Color(0xFFDA6581),Color(0xFF7295BC)];
  @override Widget build(BuildContext context){
    final byCategory=<String,int>{};
    for(final t in transactions.where((t)=>t.type==TxnType.expense&&t.date.year==month.year&&t.date.month==month.month)){byCategory.update(t.category,(v)=>v+t.amountMinor,ifAbsent:()=>t.amountMinor);}
    final entries=byCategory.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));final total=entries.fold<int>(0,(s,e)=>s+e.value);
    final months=List.generate(6,(i)=>DateTime(month.year,month.month-5+i));
    final values=months.map((d){final rows=transactions.where((t)=>t.date.year==d.year&&t.date.month==d.month);return [for(final type in TxnType.values)rows.where((t)=>t.type==type).fold<int>(0,(s,t)=>s+t.amountMinor)];}).toList();
    final peak=values.expand((v)=>v).fold<int>(1,math.max);
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('৬ মাসের আয় ও ব্যয়',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:8),const Text('সবুজ: আয় • কমলা: ব্যয়'),const SizedBox(height:20),SizedBox(height:130,child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:List.generate(months.length,(i)=>Expanded(child:Semantics(label:'${monthLabel(months[i])}, আয় ${formatMinor(values[i][0])}, ব্যয় ${formatMinor(values[i][1])}',child:Column(mainAxisAlignment:MainAxisAlignment.end,children:[SizedBox(height:104,child:Row(mainAxisAlignment:MainAxisAlignment.center,crossAxisAlignment:CrossAxisAlignment.end,children:[for(var j=0;j<2;j++)Flexible(child:Container(width:16,height:104*values[i][j]/peak,margin:const EdgeInsets.symmetric(horizontal:2),decoration:BoxDecoration(color:j==0?palette[1]:palette[2],borderRadius:BorderRadius.circular(4))))])),const SizedBox(height:6),Text(toBangla('${months[i].month}'),style:const TextStyle(fontSize:11))]))))))]))),
      if(total>0)Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('খরচের ভাগ',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:18),Center(child:SizedBox(width:150,height:150,child:CustomPaint(painter:_Donut(entries.map((e)=>e.value/total).toList()),child:Center(child:Text('মোট ব্যয়\n${formatMinor(total)}',textAlign:TextAlign.center,style:const TextStyle(fontSize:11)))))),const SizedBox(height:18),...List.generate(entries.length,(i)=>Padding(padding:const EdgeInsets.only(bottom:7),child:Row(children:[Container(width:10,height:10,color:palette[i%palette.length]),const SizedBox(width:9),Expanded(child:Text(categoryLabel(entries[i].key))),Text('${toBangla((100*entries[i].value/total).toStringAsFixed(1))}%')])))]))),
    ]);
  }
}
class _Donut extends CustomPainter {
  final List<double> fractions;_Donut(this.fractions);
  @override void paint(Canvas canvas,Size size){var start=-math.pi/2;final rect=Offset.zero&size;for(var i=0;i<fractions.length;i++){final sweep=2*math.pi*fractions[i];canvas.drawArc(rect.deflate(11),start,sweep,false,Paint()..style=PaintingStyle.stroke..strokeWidth=20..color=FinanceCharts.palette[i%FinanceCharts.palette.length]);start+=sweep;}}
  @override bool shouldRepaint(covariant _Donut oldDelegate)=>true;
}
