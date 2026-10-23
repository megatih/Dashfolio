import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design_system/app/app_ui.dart';
import 'lock_controller.dart';

const kMinPinLength = 4;
const kMaxPinLength = 6;

/// Full-screen lock: PIN pad plus optional biometric unlock.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  String? _message;
  Timer? _ticker;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      ref.read(lockControllerProvider.notifier).refreshCooldown();
      setState(() {});
    });
    // Offer biometrics straight away on supported devices.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric(auto: true));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _tryBiometric({bool auto = false}) async {
    final state = ref.read(lockControllerProvider);
    if (!state.ready || !state.biometricAvailable || !ref.read(appSettingsProvider).lockBiometric) return;
    final ok = await ref.read(lockControllerProvider.notifier).unlockWithBiometric();
    if (!ok && !auto && mounted) setState(() => _message = 'Biometric authentication failed. Enter your PIN.');
  }

  void _digit(String d) {
    if (_pin.length >= kMaxPinLength || _checking) return;
    setState(() {
      _pin += d;
      _message = null;
    });
  }

  void _back() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    if (_pin.length < kMinPinLength || _checking) return;
    setState(() => _checking = true);
    final result = await ref.read(lockControllerProvider.notifier).unlockWithPin(_pin);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _pin = '';
      _message = switch (result) {
        UnlockResult.success => null,
        UnlockResult.wrongPin => 'Incorrect PIN',
        UnlockResult.coolingDown => 'Too many attempts. Try again later.',
        UnlockResult.noPin => 'No PIN is set.',
      };
    });
  }

  Future<void> _forgot() async {
    final ok = await showAppConfirm(
      context,
      title: 'Reset Dashfolio?',
      message: 'If you forgot your PIN the only way back in is to erase all portfolios, transactions and watchlists from this device. Restore a backup afterwards if you have one.',
      confirmLabel: 'Erase and reset',
      destructive: true,
    );
    if (ok) await ref.read(lockControllerProvider.notifier).resetApp();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    final label = k.keyLabel;
    if (label.length == 1 && RegExp(r'[0-9]').hasMatch(label)) {
      _digit(label);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.backspace) {
      _back();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    final lock = ref.watch(lockControllerProvider);
    final cooldown = ref.read(lockControllerProvider.notifier).cooldownRemaining;
    final showBio = lock.biometricAvailable && ref.watch(appSettingsProvider.select((s) => s.lockBiometric));

    return AppScaffold(
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _onKey,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.s6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSurface(
                      shape: AppShape.inset,
                      depth: 3,
                      circle: true,
                      width: 84,
                      height: 84,
                      child: AppIconView(AppIcon.lock, size: 36, color: n.accent),
                    ),
                    const SizedBox(height: AppSpace.s5),
                    Semantics(header: true, child: Text('Dashfolio is locked', style: context.text.titleLarge)),
                    const SizedBox(height: AppSpace.s2),
                    Text('Enter your PIN to continue', style: context.text.bodyMedium!.copyWith(color: n.textMuted)),
                    const SizedBox(height: AppSpace.s6),
                    Semantics(
                      label: '${_pin.length} digits entered',
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < kMaxPinLength; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < _pin.length ? n.accent : Colors.transparent,
                                  border: Border.all(color: i < _pin.length ? n.accent : n.outline, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    SizedBox(
                      height: 40,
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          cooldown != null ? 'Locked for ${_fmt(cooldown)}' : (_message ?? ''),
                          textAlign: TextAlign.center,
                          style: context.text.bodyMedium!.copyWith(color: n.loss),
                        ),
                      ),
                    ),
                    _Keypad(
                      enabled: cooldown == null && !_checking,
                      onDigit: _digit,
                      onBackspace: _back,
                      onSubmit: _submit,
                      canSubmit: _pin.length >= kMinPinLength,
                      biometric: showBio ? () => _tryBiometric() : null,
                    ),
                    const SizedBox(height: AppSpace.s5),
                    AppTextButton(label: 'Forgot PIN?', onPressed: _forgot),
                    if (kIsWeb)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpace.s3),
                        child: Text(
                          'On the web the PIN only hides the screen; your data stays in this browser.',
                          textAlign: TextAlign.center,
                          style: context.text.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) => d.inMinutes >= 1 ? '${d.inMinutes}m ${d.inSeconds % 60}s' : '${d.inSeconds}s';
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onSubmit,
    required this.canSubmit,
    this.biometric,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool canSubmit;
  final VoidCallback? biometric;

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback? onTap, {AppIcon? icon, String? semantic}) => AppPressable(
      onTap: enabled ? onTap : null,
      semanticLabel: semantic ?? label,
      radius: 18,
      minSize: const Size(72, 56),
      builder: (context, s) {
        final content = icon != null ? AppIconView(icon, size: 22) : Text(label, style: context.text.titleLarge);
        return SkinBuilder(
          neumorphic: (_) => AppSurface(
            shape: s.pressed ? AppShape.pressed : AppShape.raised,
            depth: 2,
            width: 72,
            height: 56,
            radius: 18,
            alignment: Alignment.center,
            child: content,
          ),
          // Override O1: iOS-style round keys.
          cupertino: (_) => AppSurface(
            shape: s.pressed ? AppShape.pressed : AppShape.inset,
            circle: true,
            width: 72,
            height: 72,
            alignment: Alignment.center,
            child: content,
          ),
        );
      },
    );
    const gap = SizedBox(width: AppSpace.s4, height: AppSpace.s4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ]) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in row) ...[key(d, () => onDigit(d)), if (d != row.last) gap],
            ],
          ),
          gap,
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            biometric != null
                ? key('', biometric, icon: AppIcon.fingerprint, semantic: 'Use biometrics')
                : const SizedBox(width: 72, height: 56),
            gap,
            key('0', () => onDigit('0')),
            gap,
            key('', onBackspace, icon: AppIcon.backspace, semantic: 'Delete digit'),
          ],
        ),
        gap,
        AppButton(label: 'Unlock', kind: AppButtonKind.primary, expand: true, onPressed: enabled && canSubmit ? onSubmit : null),
      ],
    );
  }
}

// ---- PIN management dialogs (used from Settings) ---------------------------------

final _pinFormatters = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(kMaxPinLength)];

/// Asks for a new PIN twice; returns it, or null when cancelled.
Future<String?> askNewPin(BuildContext context, {String title = 'Set a PIN'}) {
  final a = TextEditingController();
  final b = TextEditingController();
  String? error;
  return showAppModal<String>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AppDialog(
        title: title,
        actions: [
          AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx)),
          AppButton(
            label: 'Save PIN',
            kind: AppButtonKind.primary,
            onPressed: () {
              if (a.text.length < kMinPinLength) {
                setState(() => error = 'Use $kMinPinLength to $kMaxPinLength digits');
              } else if (a.text != b.text) {
                setState(() => error = 'The PINs do not match');
              } else {
                Navigator.pop(ctx, a.text);
              }
            },
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: a,
              label: 'New PIN ($kMinPinLength–$kMaxPinLength digits)',
              sensitive: true,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: _pinFormatters,
            ),
            const SizedBox(height: AppSpace.s4),
            AppTextField(
              controller: b,
              label: 'Confirm PIN',
              sensitive: true,
              keyboardType: TextInputType.number,
              inputFormatters: _pinFormatters,
              errorText: error,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Asks for the current PIN and verifies it; returns true when correct.
Future<bool> verifyCurrentPin(BuildContext context, WidgetRef ref, {String title = 'Enter your PIN'}) async {
  final c = TextEditingController();
  String? error;
  final ok = await showAppModal<bool>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AppDialog(
        title: title,
        actions: [
          AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(ctx, false)),
          AppButton(
            label: 'Continue',
            kind: AppButtonKind.primary,
            onPressed: () async {
              final good = await ref.read(lockControllerProvider.notifier).verifyPin(c.text);
              if (!ctx.mounted) return;
              if (good) {
                Navigator.pop(ctx, true);
              } else {
                setState(() => error = 'Incorrect PIN');
              }
            },
          ),
        ],
        child: AppTextField(
          controller: c,
          label: 'Current PIN',
          sensitive: true,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: _pinFormatters,
          errorText: error,
        ),
      ),
    ),
  );
  return ok ?? false;
}

/// Blurs/covers content while the app is not in the foreground (app switcher privacy).
class PrivacyCover extends StatelessWidget {
  const PrivacyCover({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.app.surface,
    child: Center(child: AppIconView(AppIcon.lock, size: 56, color: context.app.textMuted)),
  );
}

/// Convenience used by Settings to show a toast after changing lock settings.
void toastLockChanged(BuildContext context, String message) => showAppToast(context, message);
