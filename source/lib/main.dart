import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'database/db_helper.dart';
import 'services/app_lock.dart';
import 'services/reminders.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'theme/app_theme.dart';

final preferences = Preferences();
class Preferences extends ChangeNotifier {
  String theme = 'system';
  bool pinEnabled = false;
  Future<void> load() async {
    theme = await DbHelper.instance.setting('theme') ?? 'system';
    pinEnabled = await AppLock.enabled();
  }
  Future<void> setTheme(String value) async {
    await DbHelper.instance.setSetting('theme',value);
    theme = value; notifyListeners();
  }
  Future<void> refreshPin() async { pinEnabled = await AppLock.enabled(); notifyListeners(); }
}
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* { yield LicenseEntryWithLineBreaks(['Noto Sans Bengali'],await rootBundle.loadString('assets/fonts/OFL.txt')); });
  runApp(const AmarTakaApp());
}
class AmarTakaApp extends StatefulWidget {
  const AmarTakaApp({super.key});
  @override State<AmarTakaApp> createState() => _AmarTakaAppState();
}
class _AmarTakaAppState extends State<AmarTakaApp> with WidgetsBindingObserver {
  bool _ready = false, _locked = true;
  String? _error;
  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _load(); }
  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await preferences.load();
      // Notification failure must not prevent access to local accounts.
      try { await Reminders.init(); } catch (_) { /* Retry on explicit scheduling. */ }
      if (mounted) setState(() { _ready = true; _locked = preferences.pinEnabled; });
    } catch (_) { if (mounted) setState(() => _error = 'অ্যাপ চালু করা যায়নি। ডেটা মুছবেন না; আবার চেষ্টা করুন।'); }
  }
  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && preferences.pinEnabled) setState(() => _locked = true);
  }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation:preferences,builder:(context,_) => MaterialApp(
    title:'Amar Taka',debugShowCheckedModeBanner:false,
    theme:AppTheme.light,darkTheme:preferences.theme == 'amoled' ? AppTheme.amoled : AppTheme.dark,
    themeMode:preferences.theme == 'light' ? ThemeMode.light : ['dark','amoled'].contains(preferences.theme) ? ThemeMode.dark : ThemeMode.system,
    locale:const Locale('bn'),supportedLocales:const [Locale('bn'),Locale('en')],
    localizationsDelegates:GlobalMaterialLocalizations.delegates,
    home:!_ready ? Scaffold(body:Center(child:_error == null ? const CircularProgressIndicator() : Column(mainAxisSize:MainAxisSize.min,children:[Padding(padding:const EdgeInsets.all(24),child:Text(_error!)),FilledButton(onPressed:_load,child:const Text('আবার চেষ্টা'))]))) : const HomeScreen(),
    builder:(context,child) => Stack(children:[Offstage(offstage:_ready && _locked,child:child!),if (_ready && _locked) Positioned.fill(child:LockScreen(onUnlocked:() => setState(() => _locked = false)))]),
  ));
}
