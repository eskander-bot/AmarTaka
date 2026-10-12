import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const primary = Color(0xFF5168F5);
  static const income = Color(0xFF168A6C);
  static const expense = Color(0xFFD86A50);
  static Color incomeFor(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? const Color(0xFF69D9B6) : income;
  static Color expenseFor(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? const Color(0xFFFFAF92) : expense;
}
class AppTheme {
  static ThemeData _build(Brightness brightness,{bool black = false}) {
    final dark = brightness == Brightness.dark;
    final bg = black ? Colors.black : dark ? const Color(0xFF0D1321) : const Color(0xFFF4F6FB);
    final surface = dark ? const Color(0xFF171F30) : Colors.white;
    final ink = dark ? const Color(0xFFF1F4FF) : const Color(0xFF1C2741);
    final muted = dark ? const Color(0xFF9CAAC2) : const Color(0xFF6B7890);
    final line = dark ? const Color(0xFF2A3549) : const Color(0xFFE5EAF3);
    final scheme = ColorScheme.fromSeed(seedColor:AppColors.primary,brightness:brightness).copyWith(
      primary:dark ? const Color(0xFFA3B2FF) : AppColors.primary,
      onPrimary:dark ? const Color(0xFF172353) : Colors.white,
      surface:surface,onSurface:ink,onSurfaceVariant:muted,outline:muted,outlineVariant:line,
      primaryContainer:dark ? const Color(0xFF2A365C) : const Color(0xFFEAEFFF),
      onPrimaryContainer:dark ? const Color(0xFFBBC7FF) : AppColors.primary,
    );
    final text = Typography.material2021().black.apply(fontFamily:'HindSiliguri',bodyColor:ink,displayColor:ink).copyWith(
      headlineSmall:TextStyle(fontFamily:'HindSiliguri',fontSize:22,height:1.35,fontWeight:FontWeight.w600,color:ink),
      titleLarge:TextStyle(fontFamily:'HindSiliguri',fontSize:18,height:1.4,fontWeight:FontWeight.w600,color:ink),
      titleMedium:TextStyle(fontFamily:'HindSiliguri',fontSize:15,height:1.4,fontWeight:FontWeight.w600,color:ink),
      bodyLarge:TextStyle(fontFamily:'HindSiliguri',fontSize:15,height:1.45,color:ink),
      bodyMedium:TextStyle(fontFamily:'HindSiliguri',fontSize:14,height:1.45,color:ink),
      bodySmall:TextStyle(fontFamily:'HindSiliguri',fontSize:12,height:1.4,color:muted),
      labelLarge:TextStyle(fontFamily:'HindSiliguri',fontSize:14,height:1.35,fontWeight:FontWeight.w600,color:ink),
    );
    return ThemeData(useMaterial3:true,fontFamily:'HindSiliguri',textTheme:text,colorScheme:scheme,scaffoldBackgroundColor:bg,
      appBarTheme:AppBarTheme(backgroundColor:bg,surfaceTintColor:Colors.transparent,elevation:0,scrolledUnderElevation:0,centerTitle:false,titleSpacing:20,titleTextStyle:text.titleLarge,systemOverlayStyle:dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark),
      inputDecorationTheme:InputDecorationTheme(contentPadding:const EdgeInsets.symmetric(horizontal:16,vertical:15),border:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:line)),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(16),borderSide:BorderSide(color:line)),filled:true,fillColor:surface),
      cardTheme:CardThemeData(margin:const EdgeInsets.symmetric(vertical:5),elevation:0,color:surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),side:BorderSide(color:line.withValues(alpha:0.65)))),
      dividerTheme:DividerThemeData(color:line,thickness:1),
      navigationBarTheme:NavigationBarThemeData(height:70,backgroundColor:surface,indicatorColor:scheme.primaryContainer,labelTextStyle:WidgetStateProperty.resolveWith((s) => TextStyle(fontFamily:'HindSiliguri',fontSize:11,fontWeight:s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,color:s.contains(WidgetState.selected) ? scheme.primary : muted)),iconTheme:WidgetStateProperty.resolveWith((s) => IconThemeData(size:22,color:s.contains(WidgetState.selected) ? scheme.primary : muted))),
      floatingActionButtonTheme:const FloatingActionButtonThemeData(backgroundColor:AppColors.primary,foregroundColor:Colors.white,elevation:2),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:AppColors.primary,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),padding:const EdgeInsets.symmetric(horizontal:20,vertical:15))),
    );
  }
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get amoled => _build(Brightness.dark,black:true);
}
