import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class Reminders {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(const InitializationSettings(android:AndroidInitializationSettings('ic_stat_taka')));
  }
  /// Schedule in Bangladesh time, explicitly shown in the settings screen.
  static Future<void> schedule(int hour,int minute,{int? day}) async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (await android?.requestNotificationsPermission() == false) throw StateError('ফোনের Settings থেকে notification permission দিন।');
    final location = tz.getLocation('Asia/Dhaka');
    final now = tz.TZDateTime.now(location);
    var next = tz.TZDateTime(location,now.year,now.month,day ?? now.day,hour,minute);
    if (!next.isAfter(now)) {
      next = day == null ? tz.TZDateTime(location,now.year,now.month,now.day+1,hour,minute) : tz.TZDateTime(location,now.year,now.month+1,day,hour,minute);
    }
    await _plugin.zonedSchedule(1,'Amar Taka','আজকের আয়–ব্যয়ের হিসাব লিখেছেন?',next,const NotificationDetails(android:AndroidNotificationDetails('ledger_reminder','হিসাবের রিমাইন্ডার',channelDescription:'নিজের নির্ধারিত সময়ে হিসাব লেখার স্মরণ',importance:Importance.defaultImportance)),androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle,matchDateTimeComponents:day == null ? DateTimeComponents.time : DateTimeComponents.dayOfMonthAndTime);
  }
  static Future<void> backupReminder(bool enabled) async {
    await _plugin.cancel(2);
    if(!enabled)return;
    final android=_plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if(await android?.requestNotificationsPermission()==false)throw StateError('Notification permission দিন।');
    final location=tz.getLocation('Asia/Dhaka'),now=tz.TZDateTime.now(tz.getLocation('Asia/Dhaka'));
    final next=tz.TZDateTime(location,now.year,now.month,now.day+7,20);
    await _plugin.zonedSchedule(2,'Amar Taka','আপনার হিসাবের JSON backup নিরাপদ জায়গায় রাখুন।',next,const NotificationDetails(android:AndroidNotificationDetails('backup_reminder','Backup reminder',importance:Importance.defaultImportance)),androidScheduleMode:AndroidScheduleMode.inexactAllowWhileIdle,matchDateTimeComponents:DateTimeComponents.dayOfWeekAndTime);
  }
  static Future<void> cancel() async => _plugin.cancel(1);
}
