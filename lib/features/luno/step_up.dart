import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design_system/app/app_ui.dart';
import '../lock/lock_controller.dart';
import '../lock/lock_screen.dart';

/// A successful step-up authentication stays valid this long, so one flow (open the key form, then save) asks once.
const kStepUpGrace = Duration(seconds: 60);

/// When the user last passed step-up authentication.
class StepUpState extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void passed(DateTime at) => state = at;
  void reset() => state = null;
}

final stepUpProvider = NotifierProvider<StepUpState, DateTime?>(StepUpState.new);

/// Fresh biometric (or PIN) check before touching API credentials. Needs the app lock to be on: without one there is
/// nothing to authenticate against, so the caller is told to enable it. A pass is reused for [kStepUpGrace].
Future<bool> requireStepUp(BuildContext context, WidgetRef ref, {required String reason}) async {
  final settings = ref.read(appSettingsProvider);
  if (!settings.lockEnabled) {
    showAppToast(context, 'Turn on the app lock in Settings first. It protects your Luno API key.', error: true);
    return false;
  }
  final now = ref.read(clockProvider).now();
  final last = ref.read(stepUpProvider);
  if (last != null && now.difference(last) < kStepUpGrace) return true;

  var ok = false;
  final lock = ref.read(lockControllerProvider);
  if (settings.lockBiometric && lock.biometricAvailable) {
    ok = await ref.read(biometricAuthProvider).authenticate(reason);
  }
  if (!ok && context.mounted) ok = await verifyCurrentPin(context, ref, title: reason);
  if (ok) ref.read(stepUpProvider.notifier).passed(ref.read(clockProvider).now());
  return ok;
}
