import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const primary = Color(0xFF0E9F6E);
  static const income = Color(0xFF0E9F6E);
  static const expense = Color(0xFFE11D48);
  static Color incomeFor(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? const Color(0xFF1FD991) : income;
  static Color expenseFor(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? const Color(0xFFFF6B7A) : expense;
}
class AppTheme {
  static ThemeData _build(Brightness brightness,{bool black = false}) {
    final dark = brightness == Brightness.dark;
    final bg = black ? Colors.black : dark ? const Color(0xFF0B131B) : const Color(0xFFF3F7F6);
    final surface = black ? const Color(0xFF0E131D) : dark ? const Color(0xFF15232C) : Colors.white;
    final ink = dark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final muted = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final line = black ? const Color(0xFF1F2937) : dark ? const Color(0xFF283B44) : const Color(0xFFE1EAE6);
    final scheme = ColorScheme.fromSeed(seedColor:AppColors.primary,brightness:brightness).copyWith(
      primary:dark ? const Color(0xFF1FD991) : AppColors.primary,
      onPrimary:dark ? const Color(0xFF04281B) : Colors.white,
      surface:surface,onSurface:ink,onSurfaceVariant:muted,outline:muted,outlineVariant:line,
      primaryContainer:dark ? const Color(0xFF0F3B2E) : const Color(0xFFD9F7E8),
      onPrimaryContainer:dark ? const Color(0xFF5CEBB4) : AppColors.primary,
    );
    final text = Typography.material2021().black.apply(fontFamily:'NotoSansBengali',bodyColor:ink,displayColor:ink).copyWith(
      headlineSmall:TextStyle(fontFamily:'NotoSansBengali',fontSize:22,height:1.35,fontWeight:FontWeight.w600,color:ink),
      titleLarge:TextStyle(fontFamily:'NotoSansBengali',fontSize:18,height:1.4,fontWeight:FontWeight.w600,color:ink),
      titleMedium:TextStyle(fontFamily:'NotoSansBengali',fontSize:15,height:1.4,fontWeight:FontWeight.w600,color:ink),
      bodyLarge:TextStyle(fontFamily:'NotoSansBengali',fontSize:15,height:1.45,color:ink),
      bodyMedium:TextStyle(fontFamily:'NotoSansBengali',fontSize:14,height:1.45,color:ink),
      bodySmall:TextStyle(fontFamily:'NotoSansBengali',fontSize:12,height:1.4,color:muted),
      labelLarge:TextStyle(fontFamily:'NotoSansBengali',fontSize:14,height:1.35,fontWeight:FontWeight.w600,color:ink),
    );
    return ThemeData(useMaterial3:true,fontFamily:'NotoSansBengali',textTheme:text,colorScheme:scheme,scaffoldBackgroundColor:bg,
      appBarTheme:AppBarTheme(backgroundColor:bg,surfaceTintColor:Colors.transparent,elevation:0,scrolledUnderElevation:0,centerTitle:false,titleSpacing:20,titleTextStyle:text.titleLarge,systemOverlayStyle:dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark),
      inputDecorationTheme:InputDecorationTheme(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:15),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:line)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:line)),filled:true,fillColor:surface),
      cardTheme:CardThemeData(margin:const EdgeInsets.symmetric(vertical:5),elevation:0,color:surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22),side:BorderSide(color:line))),
      listTileTheme:const ListTileThemeData(contentPadding:EdgeInsets.symmetric(horizontal:16,vertical:6)),
      snackBarTheme:SnackBarThemeData(behavior:SnackBarBehavior.floating,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),
      dividerTheme:DividerThemeData(color:line,thickness:1),
      navigationBarTheme:NavigationBarThemeData(height:70,backgroundColor:surface,indicatorColor:scheme.primaryContainer,labelTextStyle:WidgetStateProperty.resolveWith((s) => TextStyle(fontFamily:'NotoSansBengali',fontSize:11,fontWeight:s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,color:s.contains(WidgetState.selected) ? scheme.primary : muted)),iconTheme:WidgetStateProperty.resolveWith((s) => IconThemeData(size:22,color:s.contains(WidgetState.selected) ? scheme.primary : muted))),
      progressIndicatorTheme:ProgressIndicatorThemeData(color:scheme.primary,linearTrackColor:line,linearMinHeight:6),
      iconTheme:IconThemeData(color:muted,size:21),
      floatingActionButtonTheme:FloatingActionButtonThemeData(backgroundColor:scheme.primary,foregroundColor:scheme.onPrimary,elevation:2,shape:const CircleBorder()),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:scheme.primary,foregroundColor:scheme.onPrimary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),padding:const EdgeInsets.symmetric(horizontal:20,vertical:15))),
    );
  }
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get amoled => _build(Brightness.dark,black:true);
}
