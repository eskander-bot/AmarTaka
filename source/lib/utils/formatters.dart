String toBangla(String input) {
  const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bn = ['\u09e6', '\u09e7', '\u09e8', '\u09e9', '\u09ea', '\u09eb', '\u09ec', '\u09ed', '\u09ee', '\u09ef'];
  var out = input;
  for (var i = 0; i < 10; i++) {
    out = out.replaceAll(en[i], bn[i]);
  }
  return out;
}

String formatAmount(double amount) {
  final negative = amount < 0;
  final abs = amount.abs();
  final str = abs.truncate().toString();
  String grouped;
  if (str.length <= 3) {
    grouped = str;
  } else {
    final last3 = str.substring(str.length - 3);
    var rest = str.substring(0, str.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${negative ? '-' : ''}\u09f3${toBangla(grouped)}';
}
