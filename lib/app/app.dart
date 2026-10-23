import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/app/skin_scope.dart';
import '../design_system/cupertino/cupertino_theme.dart';
import '../design_system/neu/theme.dart';
import '../features/lock/lock_controller.dart';
import '../features/lock/lock_screen.dart' show PrivacyCover;
import '../routing/router.dart';
import 'providers.dart';
import 'skin.dart';

/// Root widget: theme, router, lock lifecycle handling and the privacy cover.
class DashfolioApp extends ConsumerStatefulWidget {
  const DashfolioApp({super.key});

  @override
  ConsumerState<DashfolioApp> createState() => _DashfolioAppState();
}

class _DashfolioAppState extends ConsumerState<DashfolioApp> {
  late final AppLifecycleListener _lifecycle;
  bool _inForeground = true;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () => setState(() => _inForeground = false),
      onHide: () => ref.read(lockControllerProvider.notifier).onBackgrounded(),
      onShow: () => ref.read(lockControllerProvider.notifier).onResumed(),
      onResume: () => setState(() => _inForeground = true),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final lock = ref.watch(lockControllerProvider);
    final router = ref.watch(routerProvider);
    final ready = settings.loaded && lock.ready;
    final skin = ref.watch(effectiveSkinProvider);

    Widget builder(BuildContext context, Widget? child) {
      if (!ready) return const SplashScreen();
      return Stack(
        fit: StackFit.expand,
        children: [
          child ?? const SizedBox.shrink(),
          // Hide content in the app switcher when the lock is on.
          if (!_inForeground && settings.lockEnabled) const PrivacyCover(),
        ],
      );
    }

    return AppSkinScope(
      skin: skin,
      child: switch (skin) {
        AppSkin.neumorphic => MaterialApp.router(
          title: 'Dashfolio',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          themeMode: settings.themeMode,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          builder: builder,
        ),
        AppSkin.cupertino => CupertinoApp.router(
          title: 'Dashfolio',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: buildCupertinoTheme(switch (settings.themeMode) {
            ThemeMode.light => Brightness.light,
            ThemeMode.dark => Brightness.dark,
            ThemeMode.system => null,
          }),
          localizationsDelegates: const [
            DefaultMaterialLocalizations.delegate,
            DefaultCupertinoLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          builder: (context, child) => CupertinoRoot(child: builder(context, child)),
        ),
      },
    );
  }
}
