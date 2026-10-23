import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/providers.dart';
import '../../app/skin.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../routing/routes.dart';
import 'settings_screen.dart';

/// Best-guess base currency from the device region.
String guessBaseCurrency(ui.Locale locale) => switch (locale.countryCode) {
  'GB' => 'GBP',
  'JP' => 'JPY',
  'CH' => 'CHF',
  'CA' => 'CAD',
  'AU' => 'AUD',
  'NZ' => 'NZD',
  'CN' => 'CNY',
  'HK' => 'HKD',
  'SG' => 'SGD',
  'SE' => 'SEK',
  'NO' => 'NOK',
  'DK' => 'DKK',
  'IN' => 'INR',
  'KR' => 'KRW',
  'BR' => 'BRL',
  'MX' => 'MXN',
  'ZA' => 'ZAR',
  'DE' || 'FR' || 'IT' || 'ES' || 'NL' || 'BE' || 'AT' || 'IE' || 'PT' || 'FI' || 'GR' => 'EUR',
  _ => 'USD',
};

/// First-run flow: disclaimer, base currency and a first portfolio.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late String _currency = guessBaseCurrency(WidgetsBinding.instance.platformDispatcher.locale);
  final _name = TextEditingController(text: 'My portfolio');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start({required bool thenImport}) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your first portfolio a name');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final settings = ref.read(settingsRepositoryProvider);
    await settings.set(SettingKeys.baseCurrency, _currency);
    await ref
        .read(portfolioRepositoryProvider)
        .createPortfolio(NewPortfolio(name: name, costMethod: ref.read(appSettingsProvider).defaultCostMethod));
    // Make the skin choice explicit before onboarding ends: the default depends on whether onboarding was completed.
    if (ref.read(cupertinoSkinAvailableProvider)) {
      await settings.set(SettingKeys.uiSkin, AppSettings.skinName(ref.read(effectiveSkinProvider)));
    }
    await settings.set(SettingKeys.disclaimerAccepted, 'true');
    if (!mounted) return;
    context.go(thenImport ? Routes.importCsv : Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final n = context.app;
    return AppScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.s6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpace.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: AppSurface(
                        shape: AppShape.inset,
                        depth: 3,
                        circle: true,
                        width: 84,
                        height: 84,
                        child: AppIconView(AppIcon.pieChart, size: 38, color: n.accent),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s5),
                    Semantics(
                      header: true,
                      child: Text('Welcome to Dashfolio', style: context.text.headlineMedium, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: AppSpace.s2),
                    Text(
                      'Track portfolios, performance and dividends with data from Yahoo Finance. Everything stays on this device.',
                      style: context.text.bodyMedium!.copyWith(color: n.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpace.s6),
                    AppSelect<String>(
                      label: 'Base currency',
                      value: kCurrencies.contains(_currency) ? _currency : 'USD',
                      options: [for (final c in kCurrencies) AppOption(c, c)],
                      onChanged: (c) => setState(() => _currency = c ?? _currency),
                    ),
                    const SizedBox(height: AppSpace.s4),
                    AppTextField(
                      controller: _name,
                      label: 'First portfolio',
                      errorText: _error,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: AppSpace.s5),
                    AppSurface(
                      shape: AppShape.inset,
                      depth: 1,
                      padding: const EdgeInsets.all(AppSpace.s4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppIconView(AppIcon.info, size: 18, color: n.textMuted),
                          const SizedBox(width: AppSpace.s3),
                          Expanded(child: Text(kDisclaimer, style: context.text.bodySmall)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.s5),
                    AppButton(
                      label: 'Accept and get started',
                      kind: AppButtonKind.primary,
                      expand: true,
                      loading: _busy,
                      onPressed: () => _start(thenImport: false),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    AppButton(
                      label: 'Accept and import a CSV',
                      icon: AppIcon.uploadFile,
                      expand: true,
                      onPressed: _busy ? null : () => _start(thenImport: true),
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
}
