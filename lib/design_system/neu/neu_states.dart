import 'package:flutter/material.dart';

import '../../core/failure.dart';
import 'neu_button.dart';
import 'neu_surface.dart';
import 'tokens.dart';

/// Pulsing placeholder block used while data loads (static under reduced motion).
class NeuSkeleton extends StatefulWidget {
  const NeuSkeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  State<NeuSkeleton> createState() => _NeuSkeletonState();
}

class _NeuSkeletonState extends State<NeuSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(n.surfaceAlt, n.shadow.withValues(alpha: 0.45), 0.25 + 0.35 * _c.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// A card-shaped skeleton for dashboard tiles.
class NeuCardSkeleton extends StatelessWidget {
  const NeuCardSkeleton({super.key, this.height = 160, this.lines = 3});
  final double height;
  final int lines;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: NeuSurface(
      depth: 2,
      radius: NeuTheme.radiusL,
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.all(NeuTheme.s5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const NeuSkeleton(width: 120, height: 14),
          const SizedBox(height: NeuTheme.s4),
          for (var i = 0; i < lines; i++) ...[
            NeuSkeleton(height: 12, width: i == lines - 1 ? 180 : double.infinity),
            const SizedBox(height: NeuTheme.s3),
          ],
        ],
      ),
    ),
  );
}

/// Shared error view with a retry action.
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({super.key, required this.error, this.onRetry, this.compact = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  static String messageFor(Object error) => switch (error) {
    NetworkFailure() => "Can't reach the server. Check your connection and try again.",
    RateLimitedFailure(:final message) => '$message. Try again in a minute.',
    KeyRevokedFailure() => 'Luno rejected the API key. It may have been revoked; replace it in Settings → Luno.',
    ForbiddenFailure() => 'The API key does not have permission for this. Create a key with the permissions listed in the setup steps.',
    CredentialsMissingFailure() => 'No API key is stored for this connection. Enter a key in Settings → Luno.',
    SecureStorageUnavailableFailure() => 'Secure storage is unavailable on this device, so API keys cannot be kept safely.',
    KeyMismatchFailure(:final message) => message,
    UnsafeKeyFailure(:final message) => message,
    NotFoundFailure(:final message) => message,
    ConfigFailure(:final message) => message,
    AppFailure(:final message) => message,
    _ => 'Something went wrong.',
  };

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(compact ? NeuTheme.s4 : NeuTheme.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_outlined, size: compact ? 28 : 40, color: n.textMuted),
              const SizedBox(height: NeuTheme.s3),
              Text(messageFor(error), textAlign: TextAlign.center, style: context.text.bodyMedium),
              if (onRetry != null) ...[
                const SizedBox(height: NeuTheme.s4),
                NeuButton(label: 'Retry', icon: Icons.refresh, onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly empty state with an optional primary action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? NeuTheme.s5 : NeuTheme.s8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeuSurface(
                shape: NeuShape.concave,
                depth: 3,
                circle: true,
                width: compact ? 64 : 88,
                height: compact ? 64 : 88,
                child: Icon(icon, size: compact ? 28 : 38, color: n.accent),
              ),
              SizedBox(height: compact ? NeuTheme.s4 : NeuTheme.s6),
              Text(title, style: context.text.titleMedium, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: NeuTheme.s2),
                Text(
                  message!,
                  style: context.text.bodyMedium!.copyWith(color: n.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: NeuTheme.s5),
                NeuButton(label: actionLabel!, kind: NeuButtonKind.primary, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
