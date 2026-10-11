import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amartaka/screens/item_editor.dart';
import 'package:amartaka/theme/app_theme.dart';
void main() {
  testWidgets('Goal editor validates amounts before saving',(tester) async {
    await tester.binding.setSurfaceSize(const Size(800,1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(theme:AppTheme.light,home:const ItemEditor(goal:true)));
    await tester.ensureVisible(find.text('সংরক্ষণ করুন'));
    await tester.tap(find.text('সংরক্ষণ করুন'));
    await tester.pump();
    expect(find.text('একটি নাম দিন'),findsOneWidget);
    expect(find.text('সঠিক পরিমাণ দিন'),findsOneWidget);
    expect(tester.takeException(),isNull);
  });
}
