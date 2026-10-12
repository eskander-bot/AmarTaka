const _digits = '০১২৩৪৫৬৭৮৯';
const maxMinor = 99999999999;
String toBangla(String input) => input.replaceAllMapped(RegExp(r'[0-9]'), (m) => _digits[int.parse(m[0]!)]);
String toEnglish(String input) {
  for (var i = 0; i < 10; i++) { input = input.replaceAll(_digits[i], '$i'); }
  return input;
}
/// Parse decimal money without floating point rounding. Input is in taka.
int? parseMoney(String text,{bool allowZero=false}) {
  final s = toEnglish(text.trim());
  if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(s)) return null;
  final parts = s.split('.');
  final n = int.parse(parts[0]) * 100 + (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return n >= (allowZero ? 0 : 1) && n <= maxMinor ? n : null;
}
String moneyInput(int minor) => '${minor ~/ 100}.${(minor % 100).toString().padLeft(2, '0')}';
String formatMinor(int minor) {
  final digits = (minor.abs() ~/ 100).toString();
  String groups = digits;
  if (digits.length > 3) {
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) { parts.insert(0, rest.substring(rest.length - 2)); rest = rest.substring(0, rest.length - 2); }
    groups = '$rest${parts.isEmpty ? '' : ',${parts.join(',')}'}${','}${digits.substring(digits.length - 3)}';
  }
  return '${minor < 0 ? '−' : ''}৳${toBangla(groups)}.${toBangla((minor.abs() % 100).toString().padLeft(2, '0'))}';
}
String formatDate(DateTime d) => toBangla('${d.day}/${d.month}/${d.year}');
String monthKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';
const monthNames = ['জানুয়ারি','ফেব্রুয়ারি','মার্চ','এপ্রিল','মে','জুন','জুলাই','আগস্ট','সেপ্টেম্বর','অক্টোবর','নভেম্বর','ডিসেম্বর'];
String monthLabel(DateTime d) => '${monthNames[d.month - 1]} ${toBangla('${d.year}')}';
const categoryLabels = {'Bazar':'বাজার','Transport':'যাতায়াত','Bills':'বিল','Health':'স্বাস্থ্য','Education':'শিক্ষা','Entertainment':'বিনোদন','Misc':'অন্যান্য','Salary':'বেতন','Freelance':'ফ্রিল্যান্সিং','Business':'ব্যবসা','Gift':'উপহার'};
String categoryLabel(String c) => categoryLabels[c] ?? c;
