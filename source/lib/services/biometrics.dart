import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_lock.dart';

class Biometrics {
  static final _auth=LocalAuthentication();
  static const _storage=FlutterSecureStorage();
  static Future<bool> enabled() async=>await AppLock.enabled() && await _storage.read(key:'biometric_enabled')=='1';
  static Future<bool> authenticate() async {
    try {return await _auth.authenticate(localizedReason:'Amar Taka খুলতে আপনার পরিচয় যাচাই করুন',options:const AuthenticationOptions(biometricOnly:true,stickyAuth:true,useErrorDialogs:false));}
    catch(_){return false;}
  }
  static Future<void> setEnabled(bool value) async {
    if(value && (!await AppLock.enabled() || !await authenticate()))throw const FormatException('Biometric চালু হয়নি। ফোনে fingerprint/face সেট আছে কি না দেখুন।');
    await _storage.write(key:'biometric_enabled',value:value?'1':'0');
  }
}
