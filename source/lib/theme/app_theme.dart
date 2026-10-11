import 'package:flutter/material.dart';
class AppColors {
  static const primary = Color(0xFF286451);
  static const income = Color(0xFF299773);
  static const expense = Color(0xFFCF7055);
}
class AppTheme {
  static ThemeData _build(Brightness brightness,{bool black = false}) {
    final dark = brightness == Brightness.dark;
    final bg = black ? Colors.black : dark ? const Color(0xFF172320) : const Color(0xFFF7F4EC);
    final scheme = ColorScheme.fromSeed(seedColor:AppColors.primary,brightness:brightness).copyWith(surface:black ? const Color(0xFF111614) : dark ? const Color(0xFF20312A) : const Color(0xFFFFFEF9));
    return ThemeData(useMaterial3:true,colorScheme:scheme,scaffoldBackgroundColor:bg,
      appBarTheme:AppBarTheme(backgroundColor:bg,elevation:0,centerTitle:false),
      inputDecorationTheme:InputDecorationTheme(border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)),filled:true,fillColor:scheme.surface),
      cardTheme:CardThemeData(elevation:0,color:scheme.surface,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22))),
      navigationBarTheme:NavigationBarThemeData(backgroundColor:scheme.surface),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:22,vertical:16))));
  }
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get amoled => _build(Brightness.dark,black:true);
}
