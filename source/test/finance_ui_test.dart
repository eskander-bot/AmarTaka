import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amartaka/finance/finance_screen.dart';
import 'package:amartaka/finance/holding_editor.dart';
import 'package:amartaka/finance/finance_charts.dart';
import 'package:amartaka/finance/portfolio.dart';
import 'package:amartaka/models/transaction.dart';
import 'package:amartaka/theme/app_theme.dart';

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(()async{
    await (FontLoader('NotoSansBengali')..addFont(rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf'))..addFont(rootBundle.load('assets/fonts/NotoSansBengali-SemiBold.ttf'))).load();
    await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  final sample=Portfolio(holdings:[for(var i=0;i<financeKinds.length;i++){'id':i+1,'kind':financeKinds[i],'title':['হাতের নগদ','আমার ব্যাংক','ভবিষ্যতের সঞ্চয়','মেয়াদি আমানত','পরিবার সঞ্চয়পত্র','শেয়ার পোর্টফোলিও','বন্ধুকে ধার','ব্যক্তিগত ঋণ'][i],'institution':'','reference':'','subtype':'','note':'','amount_minor':i==2?200000:1500000,'value_minor':i==5?1750000:0,'months_paid':4,'rate_bps':850,'active':1,'start':'2026-01-01T00:00:00.000','end':'2027-01-01T00:00:00.000'}]);
  Future<void> mount(WidgetTester tester,Widget child,{bool small=false,GlobalKey? key})async{
    tester.view.physicalSize=small?const Size(320,740):const Size(390,844);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(RepaintBoundary(key:key,child:MaterialApp(debugShowCheckedModeBanner:false,theme:AppTheme.light,locale:const Locale('bn'),supportedLocales:const [Locale('bn'),Locale('en')],localizationsDelegates:GlobalMaterialLocalizations.delegates,builder:(c,w)=>MediaQuery(data:MediaQuery.of(c).copyWith(textScaler:TextScaler.linear(small?1.6:1)),child:w!),home:child)));await tester.pumpAndSettle();
  }
  for(final small in [false,true]){
    testWidgets('Portfolio filters and scrolling fit ${small?'large text':'normal'}',(tester)async{
      final boundary=GlobalKey();await mount(tester,FinanceScreen(loader:()async=>sample),small:small,key:boundary);expect(tester.takeException(),isNull);
      await tester.runAsync(()async{
        final image=await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio:2);final bytes=await image.toByteData(format:ui.ImageByteFormat.png);Directory('build/ui-previews').createSync(recursive:true);File('build/ui-previews/portfolio-${small?'large-text':'light'}.png').writeAsBytesSync(bytes!.buffer.asUint8List());image.dispose();
      });
      await tester.drag(find.byType(ListView).first,const Offset(0,-450));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    });
  }
  testWidgets('DPS form and charts remain usable at large text',(tester)async{
    await mount(tester,const HoldingEditor(kind:'dps'),small:true);
    await tester.drag(find.byType(ListView).first,const Offset(0,-650));await tester.pumpAndSettle();expect(tester.takeException(),isNull);
    final chartBoundary=GlobalKey();
    await mount(tester,Scaffold(body:ListView(children:[FinanceCharts(month:DateTime(2026,10),transactions:[Txn(amountMinor:10000,category:'Bazar',date:DateTime(2026,10,12),type:TxnType.expense)])])),small:true,key:chartBoundary);
    expect(tester.takeException(),isNull);
    await tester.runAsync(()async{
      final image=await (chartBoundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio:2);final bytes=await image.toByteData(format:ui.ImageByteFormat.png);Directory('build/ui-previews').createSync(recursive:true);File('build/ui-previews/charts-large-text.png').writeAsBytesSync(bytes!.buffer.asUint8List());image.dispose();
    });
  });
}
