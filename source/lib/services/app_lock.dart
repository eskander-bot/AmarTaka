import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLock {
  static const _store = FlutterSecureStorage();
  static const _key = 'amar_taka_pin_v1';
  static final _kdf = Pbkdf2(macAlgorithm:Hmac.sha256(),iterations:210000,bits:256);
  static Future<bool> enabled() async => await _store.read(key:_key) != null;
  static Future<List<int>> _derive(String pin,List<int> salt) async => (await _kdf.deriveKey(secretKey:SecretKey(utf8.encode(pin)),nonce:salt)).extractBytes();
  static Future<void> set(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) throw const FormatException('Six digits required');
    final random = Random.secure();
    final salt = List<int>.generate(24,(_) => random.nextInt(256));
    await _store.write(key:_key,value:jsonEncode({'salt':base64Encode(salt),'hash':base64Encode(await _derive(pin,salt))}));
    await _store.delete(key:'pin_attempts');
    await _store.delete(key:'pin_wait_until');
  }
  static Future<bool> verify(String pin) async {
    final wait = int.tryParse(await _store.read(key:'pin_wait_until') ?? '') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch < wait) throw StateError('একটু অপেক্ষা করে আবার চেষ্টা করুন।');
    final raw = await _store.read(key:_key);
    if (raw == null) return true;
    final data = jsonDecode(raw) as Map;
    final expected = base64Decode(data['hash'] as String);
    final actual = await _derive(pin,base64Decode(data['salt'] as String));
    var diff = expected.length ^ actual.length;
    for (var i = 0; i < expected.length && i < actual.length; i++) { diff |= expected[i] ^ actual[i]; }
    if (diff != 0) {
      final n = (int.tryParse(await _store.read(key:'pin_attempts') ?? '') ?? 0) + 1;
      await _store.write(key:'pin_attempts',value:'$n');
      if (n >= 5) await _store.write(key:'pin_wait_until',value:'${DateTime.now().add(const Duration(seconds:60)).millisecondsSinceEpoch}');
      return false;
    }
    await _store.delete(key:'pin_attempts');
    await _store.delete(key:'pin_wait_until');
    return true;
  }
  static Future<void> remove(String pin) async {
    if (!await verify(pin)) throw StateError('PIN সঠিক নয়।');
    await _store.delete(key:_key);
    await _store.delete(key:'biometric_enabled');
  }
}
