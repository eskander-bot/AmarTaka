import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const primary = Color(0xFF087F5B);
  static const income = Color(0xFF087F5B);
  static const expense = Color(0xFFD84355);
  static Color incomeFor(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? const Color(0xFF20D99B) : income;
  static Color expenseFor(BuildContext c) => Theme.of(c).brightness == Brightness.dark ? const Color(0xFFFF7B87) : expense;
}
class AppTheme {
  static ThemeData _build(Brightness brightness,{bool black = false}) {
    final dark = brightness == Brightness.dark;
    final bg = black ? Colors.black : dark ? const Color(0xFF080F0C) : const Color(0xFFF3F7F4);
    final surface = dark ? const Color(0xFF121D17) : Colors.white;
    final ink = dark ? const Color(0xFFF1F7F3) : const Color(0xFF13271D);
    final muted = dark ? const Color(0xFFA2B8AB) : const Color(0xFF526A5D);
    final line = dark ? const Color(0xFF28392F) : const Color(0xFFDDE8E0);
    final scheme = ColorScheme.fromSeed(seedColor:AppColors.primary,brightness:brightness).copyWith(
      primary:dark ? const Color(0xFF20D99B) : AppColors.primary,
      onPrimary:dark ? const Color(0xFF052C1C) : Colors.white,
      surface:surface,onSurface:ink,onSurfaceVariant:muted,outline:muted,outlineVariant:line,
      primaryContainer:dark ? const Color(0xFF123D2B) : const Color(0xFFE0F4E9),
      onPrimaryContainer:dark ? const Color(0xFF57EAB0) : AppColors.primary,
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
      cardTheme:CardThemeData(margin:const EdgeInsets.symmetric(vertical:5),elevation:0,color:surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20),side:BorderSide.none)),
      dividerTheme:DividerThemeData(color:line,thickness:1),
      navigationBarTheme:NavigationBarThemeData(height:70,backgroundColor:surface,indicatorColor:scheme.primaryContainer,labelTextStyle:WidgetStateProperty.resolveWith((s) => TextStyle(fontFamily:'HindSiliguri',fontSize:11,fontWeight:s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,color:s.contains(WidgetState.selected) ? scheme.primary : muted)),iconTheme:WidgetStateProperty.resolveWith((s) => IconThemeData(size:22,color:s.contains(WidgetState.selected) ? scheme.primary : muted))),
      progressIndicatorTheme:ProgressIndicatorThemeData(color:scheme.primary,linearTrackColor:line,linearMinHeight:6),
      iconTheme:IconThemeData(color:muted,size:21),
      floatingActionButtonTheme:FloatingActionButtonThemeData(backgroundColor:scheme.primary,foregroundColor:scheme.onPrimary,elevation:0),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(backgroundColor:scheme.primary,foregroundColor:scheme.onPrimary,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),padding:const EdgeInsets.symmetric(horizontal:20,vertical:15))),
    );
  }
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get amoled => _build(Brightness.dark,black:true);
}
