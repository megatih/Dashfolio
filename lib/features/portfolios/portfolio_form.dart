import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design_system/app/app_ui.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/repositories/portfolio_repository.dart';

const kPortfolioColors = [0xFF3B82F6, 0xFF10B981, 0xFFF59E0B, 0xFFEF4444, 0xFF8B5CF6, 0xFF06B6D4, 0xFFEC4899, 0xFF64748B];

/// Creates (or edits) a portfolio. Returns the portfolio id when saved.
Future<int?> showPortfolioForm(BuildContext context, {Portfolio? editing}) =>
    showAppSheet<int>(context, maxWidth: 480, builder: (_) => PortfolioForm(editing: editing));

class PortfolioForm extends ConsumerStatefulWidget {
  const PortfolioForm({super.key, this.editing});

  final Portfolio? editing;

  @override
  ConsumerState<PortfolioForm> createState() => _PortfolioFormState();
}

class _PortfolioFormState extends ConsumerState<PortfolioForm> {
  late final _name = TextEditingController(text: widget.editing?.name);
  late final _desc = TextEditingController(text: widget.editing?.description);
  late int _color = widget.editing?.color ?? kPortfolioColors.first;
  late CostMethod _method = widget.editing?.costMethod ?? ref.read(appSettingsProvider).defaultCostMethod;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the portfolio a name');
      return;
    }
    final existing = ref.read(portfoliosProvider).value ?? const <Portfolio>[];
    if (existing.any((p) => p.id != widget.editing?.id && p.name.toLowerCase() == name.toLowerCase())) {
      setState(() => _error = 'A portfolio with this name already exists');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(portfolioRepositoryProvider);
    final desc = _desc.text.trim().isEmpty ? null : _desc.text.trim();
    final int id;
    if (widget.editing != null) {
      await repo.updatePortfolio(widget.editing!.copyWith(name: name, description: desc, color: _color, costMethod: _method));
      id = widget.editing!.id;
    } else {
      id = await repo.createPortfolio(NewPortfolio(name: name, description: desc, color: _color, costMethod: _method));
    }
    if (mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing != null;
    return AppSheetScaffold(
      title: editing ? 'Edit portfolio' : 'New portfolio',
      confirmLabel: editing ? 'Save changes' : 'Create portfolio',
      shortConfirmLabel: editing ? 'Save' : 'Create',
      onConfirm: _save,
      busy: _saving,
      children: [
        AppSection(
          bare: true,
          children: [
            AppTextField(
              controller: _name,
              label: 'Name',
              hint: 'e.g. Long-term growth',
              autofocus: true,
              errorText: _error,
              onChanged: (_) => setState(() => _error = null),
              maxLength: 40,
            ),
            AppTextField(controller: _desc, label: 'Description (optional)', maxLines: 2),
          ],
        ),
        AppSection(
          bare: true,
          title: 'Color',
          children: [
            Wrap(
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s3,
              children: [
                for (final c in kPortfolioColors)
                  AppPressable(
                    onTap: () => setState(() => _color = c),
                    semanticLabel: 'Color ${kPortfolioColors.indexOf(c) + 1}',
                    selected: c == _color,
                    radius: 22,
                    minSize: const Size(44, 44),
                    builder: (context, s) => AppSurface(
                      shape: c == _color ? AppShape.pressed : AppShape.raised,
                      depth: 1,
                      circle: true,
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle),
                        child: c == _color ? const AppIconView(AppIcon.check, size: 14, color: Colors.white) : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        AppSection(
          bare: true,
          footer: _method == CostMethod.average
              ? 'Sells realize profit against your weighted-average cost.'
              : 'Sells consume the oldest purchase lots first.',
          children: [
            AppSelect<CostMethod>(
              label: 'Cost basis method',
              value: _method,
              options: [for (final m in CostMethod.values) AppOption(m, m.label)],
              onChanged: (m) => setState(() => _method = m ?? _method),
            ),
          ],
        ),
      ],
    );
  }
}
