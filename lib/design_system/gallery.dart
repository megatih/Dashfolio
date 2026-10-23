import 'package:flutter/material.dart';

import '../core/failure.dart';

import 'package:decimal/decimal.dart';

import 'app/app_ui.dart' hide AppContext;
import 'design_system.dart';

/// Debug-only catalogue of every design-system component (also used for golden tests).
class DesignGallery extends StatefulWidget {
  const DesignGallery({super.key});

  @override
  State<DesignGallery> createState() => _DesignGalleryState();
}

class _DesignGalleryState extends State<DesignGallery> {
  bool _switch = true;
  String _seg = 'a';
  bool _chip = true;
  double _slider = 0.4;
  int _nav = 0;
  String? _dropdown = 'USD';
  String? _sort = 'value';
  bool _asc = false;

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: NeuTheme.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleMedium),
          const SizedBox(height: NeuTheme.s3),
          child,
        ],
      ),
    );

    final rows = [('AAPL', 1200.5, 0.0123), ('MSFT', 980.0, -0.0042), ('BTC-USD', 450.0, 0.0)];

    return Scaffold(
      appBar: AppBar(title: const Text('Design gallery')),
      body: ListView(
        padding: const EdgeInsets.all(NeuTheme.s4),
        children: [
          section(
            'Surfaces',
            Wrap(
              spacing: NeuTheme.s4,
              runSpacing: NeuTheme.s4,
              children: [
                for (final s in NeuShape.values)
                  NeuSurface(shape: s, depth: 3, width: 110, height: 80, alignment: Alignment.center, child: Text(s.name)),
              ],
            ),
          ),
          section('Card', const NeuCard(child: Text('A NeuCard with content'))),
          section(
            'Buttons',
            Wrap(
              spacing: NeuTheme.s3,
              runSpacing: NeuTheme.s3,
              children: [
                NeuButton(label: 'Normal', onPressed: () {}),
                NeuButton(label: 'Primary', kind: NeuButtonKind.primary, icon: Icons.add, onPressed: () {}),
                NeuButton(label: 'Danger', kind: NeuButtonKind.danger, onPressed: () {}),
                const NeuButton(label: 'Disabled'),
                NeuButton(label: 'Loading', loading: true, onPressed: () {}),
                NeuIconButton(icon: Icons.refresh, tooltip: 'Refresh', onPressed: () {}),
                NeuIconButton(icon: Icons.star, tooltip: 'Selected', selected: true, onPressed: () {}),
              ],
            ),
          ),
          section(
            'Controls',
            Wrap(
              spacing: NeuTheme.s4,
              runSpacing: NeuTheme.s4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                NeuSwitch(value: _switch, onChanged: (v) => setState(() => _switch = v), semanticLabel: 'Sample switch'),
                NeuSegmentedControl<String>(
                  segments: const [NeuSegment('a', '1D'), NeuSegment('b', '1W'), NeuSegment('c', '1M')],
                  selected: _seg,
                  onChanged: (v) => setState(() => _seg = v),
                ),
                NeuChip(label: 'Chip', selected: _chip, onTap: () => setState(() => _chip = !_chip)),
                SizedBox(
                  width: 200,
                  child: NeuSlider(value: _slider, onChanged: (v) => setState(() => _slider = v)),
                ),
                const SizedBox(width: 200, child: NeuProgress(value: 0.6)),
              ],
            ),
          ),
          section(
            'Inputs',
            Column(
              children: [
                const NeuTextField(label: 'Symbol', hint: 'e.g. AAPL', prefixIcon: Icons.search),
                const SizedBox(height: NeuTheme.s3),
                const NeuTextField(label: 'Quantity', errorText: 'Must be greater than zero'),
                const SizedBox(height: NeuTheme.s3),
                NeuDropdown<String>(
                  label: 'Currency',
                  value: _dropdown,
                  items: const [
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                    DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                  ],
                  onChanged: (v) => setState(() => _dropdown = v),
                ),
              ],
            ),
          ),
          section(
            'Badges & money',
            Wrap(
              spacing: NeuTheme.s3,
              runSpacing: NeuTheme.s3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const AppChangeBadge(ratio: 0.0123),
                const AppChangeBadge(ratio: -0.0456),
                const AppChangeBadge(ratio: 0),
                const AppChangeBadge(ratio: null),
                Text(
                  'Gain',
                  style: TextStyle(color: n.gain, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Loss',
                  style: TextStyle(color: n.loss, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          section(
            'Data table',
            NeuCard(
              padding: EdgeInsets.zero,
              child: NeuDataTable<(String, double, double)>(
                columns: [
                  NeuColumn(
                    id: 'symbol',
                    label: 'Symbol',
                    width: 120,
                    flex: 1,
                    cell: (c, r) => Text(r.$1, style: c.text.titleSmall),
                  ),
                  NeuColumn(id: 'value', label: 'Value', numeric: true, cell: (c, r) => Text(r.$2.toStringAsFixed(2))),
                  NeuColumn(
                    id: 'chg',
                    label: 'Day',
                    numeric: true,
                    cell: (c, r) => AppChangeBadge(ratio: r.$3, dense: true),
                  ),
                ],
                rows: rows,
                sortColumnId: _sort,
                ascending: _asc,
                onSort: (id, asc) => setState(() {
                  _sort = id;
                  _asc = asc;
                }),
                onRowTap: (_) {},
              ),
            ),
          ),
          section('Skeleton', const NeuCardSkeleton(height: 150)),
          section(
            'Empty state',
            const SizedBox(
              height: 340,
              child: EmptyState(
                icon: Icons.pie_chart_outline,
                title: 'No holdings yet',
                message: 'Add your first transaction.',
                actionLabel: 'Add transaction',
                onAction: null,
              ),
            ),
          ),
          section('Error', const SizedBox(height: 260, child: ErrorRetryView(error: NetworkFailure()))),
          section(
            'Navigation',
            SizedBox(
              height: 130,
              child: NeuNavBar(
                items: const [
                  NeuNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined),
                  NeuNavItem(label: 'Portfolios', icon: Icons.folder_outlined),
                  NeuNavItem(label: 'Markets', icon: Icons.show_chart),
                ],
                selectedIndex: _nav,
                onSelected: (i) => setState(() => _nav = i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every facade widget, written once: renders in whichever skin is active (see `AppSkinScope`). Used for the
/// per-skin golden tests and as the visual baseline for new facade widgets.
class AppCatalogue extends StatefulWidget {
  const AppCatalogue({super.key});

  @override
  State<AppCatalogue> createState() => _AppCatalogueState();
}

class _AppCatalogueState extends State<AppCatalogue> {
  bool _on = true;
  String _seg = 'a';
  String? _pick = 'EUR';

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpace.s4);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpace.s3,
            runSpacing: AppSpace.s3,
            children: [
              AppButton(label: 'Normal', onPressed: () {}),
              AppButton(label: 'Primary', kind: AppButtonKind.primary, icon: AppIcon.add, onPressed: () {}),
              AppButton(label: 'Danger', kind: AppButtonKind.danger, onPressed: () {}),
              const AppButton(label: 'Disabled'),
              AppIconButton(icon: AppIcon.refresh, tooltip: 'Refresh', onPressed: () {}),
              AppTextButton(label: 'Text button', onPressed: () {}),
            ],
          ),
          gap,
          Row(
            children: [
              AppSwitch(value: _on, onChanged: (v) => setState(() => _on = v), semanticLabel: 'Switch'),
              const SizedBox(width: AppSpace.s4),
              AppChip(label: 'Chip', selected: _on, onTap: () {}),
              const SizedBox(width: AppSpace.s4),
              const AppChangeBadge(ratio: 0.0123),
              const SizedBox(width: AppSpace.s2),
              const AppChangeBadge(ratio: -0.0456),
            ],
          ),
          gap,
          AppSegmented<String>(
            selected: _seg,
            onChanged: (v) => setState(() => _seg = v),
            segments: const [AppSegment('a', 'Day'), AppSegment('b', 'Week'), AppSegment('c', 'Month')],
          ),
          gap,
          const AppTextField(label: 'Name', hint: 'My portfolio'),
          gap,
          const AppTextField(label: 'Quantity', errorText: 'Enter a number'),
          gap,
          AppSelect<String>(
            label: 'Currency',
            value: _pick,
            options: const [AppOption('USD', 'USD'), AppOption('EUR', 'EUR')],
            onChanged: (v) => setState(() => _pick = v),
          ),
          gap,
          const AppProgress(value: 0.6),
          gap,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionHeader('Card'),
                const AppDivider(),
                AppRow(
                  title: 'AAPL',
                  subtitle: 'Apple Inc.',
                  trailing: AppMoneyText(Decimal.parse('1234.5'), currency: 'USD'),
                  onTap: () {},
                ),
              ],
            ),
          ),
          gap,
          const SizedBox(
            height: 180,
            child: AppEmptyState(icon: AppIcon.pieChart, title: 'Nothing here', message: 'Add a transaction.', compact: true),
          ),
        ],
      ),
    );
  }
}

/// The grouped-form primitives (sections, form rows, fields, button groups, the sheet frame), written once. Kept apart from
/// [AppCatalogue] so the original catalogue goldens stay unchanged.
class AppFormCatalogue extends StatefulWidget {
  const AppFormCatalogue({super.key});

  @override
  State<AppFormCatalogue> createState() => _AppFormCatalogueState();
}

class _AppFormCatalogueState extends State<AppFormCatalogue> {
  bool _on = true;
  String? _pick = 'EUR';
  int _range = 3;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpace.s5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSection(
          title: 'Appearance',
          children: [
            AppFormRow(
              label: 'Theme',
              wide: true,
              control: AppSegmented<int>(
                selected: _range,
                onChanged: (v) => setState(() => _range = v),
                segments: const [AppSegment(1, 'System'), AppSegment(2, 'Light'), AppSegment(3, 'Dark')],
              ),
            ),
            AppFormRow(
              label: 'Currency',
              description: 'All totals are shown in this currency.',
              control: AppSelect<String>(
                width: 140,
                value: _pick,
                options: const [AppOption('USD', 'USD'), AppOption('EUR', 'EUR')],
                onChanged: (v) => setState(() => _pick = v),
              ),
            ),
            AppFormRow(
              label: 'App lock',
              control: AppSwitch(value: _on, onChanged: (v) => setState(() => _on = v), semanticLabel: 'App lock'),
            ),
          ],
        ),
        AppSection(
          title: 'Your data',
          footer: 'Everything is stored on this device.',
          children: [
            AppButtonGroup(
              buttons: [
                AppButton(label: 'Import CSV', icon: AppIcon.uploadFile, onPressed: () {}),
                AppButton(label: 'Delete everything', kind: AppButtonKind.danger, icon: AppIcon.delete, onPressed: () {}),
              ],
            ),
          ],
        ),
        AppSection(
          bare: true,
          title: 'Form fields',
          children: [
            const AppTextField(label: 'Name', hint: 'My portfolio'),
            const AppTextField(label: 'Quantity', errorText: 'Enter a number'),
            AppField(
              label: 'Date',
              child: AppPressable(
                onTap: () {},
                semanticLabel: 'Date',
                builder: (context, s) => const AppSurface(
                  shape: AppShape.inset,
                  padding: EdgeInsets.symmetric(horizontal: AppSpace.s3),
                  constraints: BoxConstraints(minHeight: AppSpace.minHit),
                  child: Text('Jun 3, 2024'),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
