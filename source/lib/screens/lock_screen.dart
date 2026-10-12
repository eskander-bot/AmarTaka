import 'package:flutter/material.dart';
import '../services/app_lock.dart';
import '../services/biometrics.dart';
import '../utils/formatters.dart';
class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key,required this.onUnlocked});
  @override State<LockScreen> createState() => _LockScreenState();
}
class _LockScreenState extends State<LockScreen> {
  final _pin = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _biometric=false;
  @override void initState(){super.initState();_loadBiometric();}
  Future<void> _loadBiometric() async {try{final enabled=await Biometrics.enabled();if(mounted)setState(()=>_biometric=enabled);}catch(_){/* PIN remains available. */}}
  Future<void> _unlockBiometric() async {
    if(_busy)return;setState(()=>_busy=true);
    try{if(await Biometrics.enabled() && await Biometrics.authenticate()){if(mounted)widget.onUnlocked();}else{if(mounted)setState(()=>_error='Biometric হয়নি। PIN ব্যবহার করুন।');}}
    finally{if(mounted)setState(()=>_busy=false);}

  @override void dispose() { _pin.dispose(); super.dispose(); }
  Future<void> _unlock() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (await AppLock.verify(toEnglish(_pin.text))) { if (mounted) widget.onUnlocked(); }
      else { if (mounted) setState(() => _error = 'PIN সঠিক নয়।'); }
    } catch (_) { if (mounted) setState(() => _error = 'আনলক হয়নি। ১ মিনিট পর আবার চেষ্টা করুন।'); }
    finally { if (mounted) setState(() => _busy = false); }
    _pin.clear();
  }
  @override Widget build(BuildContext context) => PopScope(canPop:false,child:Scaffold(body:SafeArea(child:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(28),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:380),child:Column(mainAxisSize:MainAxisSize.min,children:[
    const Icon(Icons.account_balance_wallet_outlined,size:56),const SizedBox(height:20),const Text('Amar Taka',style:TextStyle(fontSize:30,fontWeight:FontWeight.bold)),const Text('by MEskander'),const SizedBox(height:32),
    TextField(controller:_pin,obscureText:true,enableSuggestions:false,autocorrect:false,keyboardType:TextInputType.number,maxLength:6,decoration:InputDecoration(labelText:'আপনার ৬ সংখ্যার PIN',errorText:_error),onSubmitted:(_) => _unlock()),
    const SizedBox(height:16),FilledButton(onPressed:_busy ? null : _unlock,child:Text(_busy ? 'অপেক্ষা করুন…' : 'আনলক করুন')),
    if(_biometric)TextButton.icon(onPressed:_busy?null:_unlockBiometric,icon:const Icon(Icons.fingerprint),label:const Text('Fingerprint / Face দিয়ে খুলুন')),
  ])))))));
}

