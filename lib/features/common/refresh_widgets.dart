import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/refresh_controller.dart';
import '../../core/format.dart';
import '../../design_system/app/app_ui.dart';

/// Refresh button showing a spinner while a refresh is running.
class RefreshAction extends ConsumerWidget {
  const RefreshAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(refreshControllerProvider);
    return AppIconButton(
      icon: AppIcon.refresh,
      tooltip: 'Refresh prices (Ctrl/Cmd+R)',
      loading: state.running,
      onPressed: () => ref.read(refreshControllerProvider.notifier).refresh(),
    );
  }
}

/// "Updated hh:mm" chip; amber when stale, red-tinged after a failed refresh.
class UpdatedChip extends ConsumerWidget {
  const UpdatedChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = context.app;
    final last = ref.watch(appSettingsProvider.select((s) => s.lastRefreshAt));
    final state = ref.watch(refreshControllerProvider);
    final now = ref.watch(clockProvider).now();

    String text;
    Color color = n.textMuted;
    AppIcon icon = AppIcon.schedule;
    if (state.running) {
      text = 'Refreshing…';
      color = n.accent;
      icon = AppIcon.sync;
    } else if (state.error != null) {
      text = 'Refresh failed';
      color = n.loss;
      icon = AppIcon.error;
    } else if (state.throttledAt != null && now.difference(state.throttledAt!) < const Duration(seconds: 5)) {
      text = 'Already up to date';
      color = n.gain;
      icon = AppIcon.checkCircle;
    } else if (last == null) {
      text = 'Never updated';
      color = n.warning;
    } else {
      final local = last.toLocal();
      final sameDay = now.year == local.year && now.month == local.month && now.day == local.day;
      text = 'Updated ${sameDay ? Fmt.time(local) : Fmt.shortDate(local)}';
      if (now.difference(last) > const Duration(days: 1)) color = n.warning;
      if (state.partial) {
        text = '$text · partial';
        color = n.warning;
      }
    }

    final tooltip = state.error != null ? AppErrorRetry.messageFor(state.error!) : 'Prices refresh manually';
    return AppTooltip(
      message: tooltip,
      child: Semantics(
        liveRegion: true,
        label: text,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconView(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(text, style: context.text.labelMedium!.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Thin progress bar shown while refreshing.
class RefreshProgressBar extends ConsumerWidget {
  const RefreshProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(refreshControllerProvider);
    if (!s.running) return const SizedBox(height: 10);
    return AppProgress(value: s.progress, height: 10);
  }
}
