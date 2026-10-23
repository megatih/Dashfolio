import 'package:flutter/material.dart' show CircularProgressIndicator;
import 'package:flutter/widgets.dart';

import '../cupertino/cu_controls.dart';
import '../cupertino/cu_states.dart';
import '../neu/neu_states.dart';
import 'app_icons.dart';
import 'skin_scope.dart';

class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, this.width, this.height = 16, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => NeuSkeleton(width: width, height: height, radius: radius),
    AppSkin.cupertino => CuSkeleton(width: width, height: height, radius: radius),
  };
}

class AppCardSkeleton extends StatelessWidget {
  const AppCardSkeleton({super.key, this.height = 160, this.lines = 3});

  final double height;
  final int lines;

  @override
  Widget build(BuildContext context) => switch (AppSkinScope.of(context)) {
    AppSkin.neumorphic => NeuCardSkeleton(height: height, lines: lines),
    AppSkin.cupertino => CuCardSkeleton(height: height, lines: lines),
  };
}

class AppErrorRetry extends StatelessWidget {
  const AppErrorRetry({super.key, required this.error, this.onRetry, this.compact = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  /// User-facing text for a failure.
  static String messageFor(Object error) => ErrorRetryView.messageFor(error);

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => ErrorRetryView(error: error, onRetry: onRetry, compact: compact),
      AppSkin.cupertino => CuErrorRetry(message: messageFor(error), icon: AppIcon.cloudOff.of(skin), onRetry: onRetry, compact: compact),
    };
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final AppIcon icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final skin = AppSkinScope.of(context);
    return switch (skin) {
      AppSkin.neumorphic => EmptyState(
        icon: icon.of(skin),
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        compact: compact,
      ),
      AppSkin.cupertino => CuEmptyState(
        icon: icon.of(skin),
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        compact: compact,
      ),
    };
  }
}

/// Indeterminate activity indicator.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.size, this.strokeWidth = 2, this.color});

  final double? size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (AppSkinScope.of(context) == AppSkin.cupertino) return CuSpinner(size: size, color: color);
    final indicator = CircularProgressIndicator(strokeWidth: strokeWidth, color: color);
    return size == null ? indicator : SizedBox(width: size, height: size, child: indicator);
  }
}
