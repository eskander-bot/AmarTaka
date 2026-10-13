import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amartaka/models/transaction.dart';
import 'package:amartaka/screens/home_screen.dart';
import 'package:amartaka/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('HindSiliguri')
      ..addFont(rootBundle.load('assets/fonts/HindSiliguri-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/HindSiliguri-SemiBold.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  Future<LedgerOverview> fixture(DateTime month) async => LedgerOverview(
    budget:1800000,
    transactions:[
      Txn(id:1,amountMinor:68000,category:'Bazar',note:'সাপ্তাহিক বাজার',date:DateTime(month.year,month.month,12),type:TxnType.expense),
      Txn(id:2,amountMinor:12000,category:'Transport',note:'অফিস যাতায়াত',date:DateTime(month.year,month.month,12),type:TxnType.expense),
      Txn(id:3,amountMinor:850000,category:'Freelance',note:'ওয়েবসাইট প্রজেক্ট',date:DateTime(month.year,month.month,11),type:TxnType.income),
      Txn(id:4,amountMinor:4500000,category:'Salary',date:DateTime(month.year,month.month,1),type:TxnType.income),
    ],
  );
  for (final variant in ['light','dark','small-large-text']) {
    testWidgets('Dashboard fits $variant and exports real Flutter preview',(tester) async {
      final small = variant == 'small-large-text';
      final size = small ? const Size(320,740) : const Size(390,844);
      tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key:boundary,child:MaterialApp(
        debugShowCheckedModeBanner:false,
        theme:variant == 'dark' ? AppTheme.dark : AppTheme.light,
        locale:const Locale('bn'),supportedLocales:const [Locale('bn'),Locale('en')],localizationsDelegates:GlobalMaterialLocalizations.delegates,
        builder:(context,child) => MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(small ? 1.6 : 1)),child:child!),
        home:HomeScreen(loadData:fixture),
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio:2);
        final bytes = await image.toByteData(format:ui.ImageByteFormat.png);
        final dir = Directory('build/ui-previews')..createSync(recursive:true);
        File('${dir.path}/dashboard-$variant.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.scrollUntilVisible(find.byTooltip('ব্যালেন্স আড়াল করুন'),200,scrollable:find.byType(Scrollable).first);
      await tester.tap(find.byTooltip('ব্যালেন্স আড়াল করুন'));
      await tester.pumpAndSettle();
      expect(find.text('৳ ••••••'),findsOneWidget);
      await tester.scrollUntilVisible(find.text('ব্যয় যোগ'),200,scrollable:find.byType(Scrollable).first);
      expect(find.text('ব্যয় যোগ'),findsOneWidget);
      expect(find.text('আয় যোগ'),findsOneWidget);
      await tester.drag(find.byType(ListView).first,const Offset(0,-450));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
    });
  }
}
