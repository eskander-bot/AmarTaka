import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/app_lock.dart';
import '../services/biometrics.dart';
import '../utils/formatters.dart';
import '../widgets/home_cards.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  String _digits = '';
  bool _busy = false;
  bool _biometric = false;
  bool _promptPending = true;
  int _shake = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBiometric();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The fingerprint / face prompt opens by itself once per lock, when the app is in front.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _promptPending = true;
    if (state == AppLifecycleState.resumed) _maybePrompt();
  }

  Future<void> _loadBiometric() async {
    try {
      final enabled = await Biometrics.enabled();
      if (mounted) setState(() => _biometric = enabled);
    } catch (_) {
      // PIN remains available.
    }
    _maybePrompt();
  }

  void _maybePrompt() {
    if (!mounted || !_promptPending || !_biometric) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    _promptPending = false;
    _unlockBiometric(auto: true);
  }

  Future<void> _unlockBiometric({bool auto = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      if (!auto) _error = null;
    });
    try {
      if (await Biometrics.enabled() && await Biometrics.authenticate()) {
        if (mounted) widget.onUnlocked();
      } else if (!auto && mounted) {
        setState(() => _error = 'Biometric হয়নি। PIN ব্যবহার করুন।');
      }
    } catch (_) {
      if (!auto && mounted) setState(() => _error = 'Biometric হয়নি। PIN ব্যবহার করুন।');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _press(String digit) {
    if (_busy || _digits.length >= 6) return;
    HapticFeedback.selectionClick();
    setState(() {
      _digits += digit;
      _error = null;
    });
    if (_digits.length == 6) _unlock();
  }

  void _back() {
    if (_busy || _digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (await AppLock.verify(_digits)) {
        if (mounted) widget.onUnlocked();
      } else {
        HapticFeedback.heavyImpact();
        if (mounted) {
          setState(() {
            _error = 'PIN সঠিক নয়।';
            _shake++;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'আনলক হয়নি। ১ মিনিট পর আবার চেষ্টা করুন।');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _digits = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF0A101C), Color(0xFF0B2A24)]
                : const [Color(0xFFF6F8FB), Color(0xFFD9F7E8)],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final keySize = math.min(76.0, (math.min(box.maxWidth, 380.0) - 56 - 40) / 3);
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 380, minHeight: box.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _brand(cs),
                            _dots(cs),
                            _keypad(cs, keySize),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _brand(ColorScheme cs) => Column(children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              'assets/logo/app_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.account_balance_wallet_rounded, size: 56, color: cs.primary),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const GradientText('Amar Taka', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('by MEskander', style: Theme.of(context).textTheme.bodySmall),
      ]);

  Widget _dots(ColorScheme cs) => Column(children: [
        TweenAnimationBuilder<double>(
          key: ValueKey(_shake),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 420),
          builder: (context, t, child) => Transform.translate(
            offset: Offset(_shake == 0 ? 0 : math.sin(t * math.pi * 6) * (1 - t) * 14, 0),
            child: child,
          ),
          child: Semantics(
            label: 'PIN এর ${toBangla('${_digits.length}')} টি সংখ্যা দেওয়া হয়েছে',
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 6; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  width: i < _digits.length ? 17 : 14,
                  height: i < _digits.length ? 17 : 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < _digits.length ? (_error != null ? cs.error : cs.primary) : Colors.transparent,
                    border: Border.all(color: _error != null ? cs.error : cs.primary, width: 2),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: Text(
            _error ?? (_biometric ? 'PIN দিন, অথবা নিচের ফিঙ্গারপ্রিন্ট চাপুন' : '৬ সংখ্যার PIN দিন'),
            textAlign: TextAlign.center,
            style: TextStyle(color: _error != null ? cs.error : cs.onSurfaceVariant, fontSize: 14),
          ),
        ),
      ]);

  Widget _keypad(ColorScheme cs, double size) {
    Widget key({required Widget child, required VoidCallback? onTap, String? tip, Color? fill, Color? line}) =>
        Semantics(
          button: true,
          label: tip,
          child: Material(
            color: fill ?? cs.surface,
            shape: CircleBorder(side: BorderSide(color: line ?? cs.outlineVariant)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(width: size, height: size, child: Center(child: child)),
            ),
          ),
        );
    Widget digit(String d) => key(
          tip: toBangla(d),
          onTap: _busy ? null : () => _press(d),
          child: Text(toBangla(d), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
        );
    Widget row(List<Widget> items) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: items),
        );
    final fingerprint = _biometric
        ? key(
            tip: 'Fingerprint / Face দিয়ে খুলুন',
            onTap: _busy ? null : () => _unlockBiometric(),
            fill: cs.primary.withValues(alpha: 0.14),
            line: cs.primary,
            child: Icon(Icons.fingerprint, size: 36, color: cs.primary),
          )
        : SizedBox(width: size, height: size);
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1,
      maxScaleFactor: 1.2,
      child: Column(children: [
        row([digit('1'), digit('2'), digit('3')]),
        row([digit('4'), digit('5'), digit('6')]),
        row([digit('7'), digit('8'), digit('9')]),
        row([
          fingerprint,
          digit('0'),
          key(
            tip: 'মুছুন',
            onTap: _busy ? null : _back,
            fill: Colors.transparent,
            line: Colors.transparent,
            child: Icon(Icons.backspace_outlined, size: 26, color: cs.onSurfaceVariant),
          ),
        ]),
      ]),
    );
  }
}
