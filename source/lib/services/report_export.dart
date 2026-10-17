import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class ReportExport {
  // Render with Flutter's Bengali shaping and bundled font, then embed pages.
  static Future<Uint8List> build(List<Txn> rows,DateTime start,DateTime end) async {
    if(rows.length>2000)throw const FormatException('এক PDF-এ সর্বোচ্চ ২০০০ এন্ট্রি; ছোট সময়সীমা বাছুন।');
    final doc=pw.Document();
    final income=rows.where((t)=>t.type==TxnType.income).fold<int>(0,(s,t)=>s+t.amountMinor);
    final expense=rows.where((t)=>t.type==TxnType.expense).fold<int>(0,(s,t)=>s+t.amountMinor);
    var recorder=ui.PictureRecorder();var canvas=Canvas(recorder);var y=0.0,page=1;
    void line(String text,{double size=18,FontWeight weight=FontWeight.normal,Color color=Colors.black}) {
      final p=TextPainter(text:TextSpan(text:text,style:TextStyle(fontFamily:'NotoSansBengali',fontSize:size,fontWeight:weight,color:color)),textDirection:TextDirection.ltr)..layout(maxWidth:700);
      p.paint(canvas,Offset(40,y));y+=p.height+12;p.dispose();
    }
    void header(){
      canvas.drawColor(Colors.white,BlendMode.src);y=34;
      line('Amar Taka • by MEskander',size:25,weight:FontWeight.bold,color:const Color(0xFF13664F));
      line('${formatDate(start)} — ${formatDate(end)}',size:16);
      line('আয় ${formatMinor(income)} • ব্যয় ${formatMinor(expense)}',weight:FontWeight.bold);
      line('নিট ${formatMinor(income-expense)} • ${toBangla('${rows.length}')}টি লেনদেন',size:16);
    }
    Future<void> flush() async {
      y=1050;line('পৃষ্ঠা ${toBangla('$page')} • স্থানীয় আয়–ব্যয়ের রিপোর্ট',size:13,color:Colors.grey);
      final picture=recorder.endRecording();final image=await picture.toImage(780,1104);
      final data=await image.toByteData(format:ui.ImageByteFormat.png);
      image.dispose();picture.dispose();
      doc.addPage(pw.Page(pageFormat:PdfPageFormat.a4,margin:pw.EdgeInsets.zero,build:(_)=>pw.Image(pw.MemoryImage(data!.buffer.asUint8List()),fit:pw.BoxFit.contain)));
      page++;recorder=ui.PictureRecorder();canvas=Canvas(recorder);
    }
    header();if(rows.isEmpty)line('এই সময়সীমায় কোনো লেনদেন নেই।');
    for(final t in rows){
      if(y>870){await flush();header();}
      final note=t.note.replaceAll('\n',' ');
      line('${formatDate(t.date)} • ${t.type==TxnType.income?'আয়':'ব্যয়'} • ${formatMinor(t.amountMinor)}',weight:FontWeight.bold);
      line('${categoryLabel(t.category)}${note.isEmpty?'':' • ${note.length>80?'${note.substring(0,80)}…':note}'}',size:15);y+=6;
    }
    await flush();recorder.endRecording().dispose();return doc.save();
  }
  static Future<bool> save(List<Txn> rows,DateTime start,DateTime end) async => await FilePicker.platform.saveFile(dialogTitle:'PDF সংরক্ষণ',fileName:'Amar-Taka-report.pdf',bytes:await build(rows,start,end))!=null;
  static Future<void> share(List<Txn> rows,DateTime start,DateTime end) async {
    await Printing.sharePdf(bytes:await build(rows,start,end),filename:'Amar-Taka-report.pdf');
  }
}
