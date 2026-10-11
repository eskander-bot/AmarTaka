import 'package:flutter_test/flutter_test.dart';
import 'package:amartaka/utils/formatters.dart';
void main() {
  test('Money keeps exact paisa and accepts Bengali digits',() {
    expect(parseMoney('১২৫.৫০'),12550);
    expect(parseMoney('0.01'),1);
    expect(parseMoney('12.1'),1210);
    expect(parseMoney('999999999.99'),99999999999);
    expect(formatMinor(123456789),'৳১২,৩৪,৫৬৭.৮৯');
    expect(formatMinor(-10),'−৳০.১০');
    expect(formatMinor(0),'৳০.০০');
  });
  test('Reject invalid and ambiguous amounts',() {
    for (final s in ['0','-1','NaN','Infinity','1e3','1.001','1,000','1000000000','']) { expect(parseMoney(s),isNull,reason:s); }
  });
}
