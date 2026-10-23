import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/app/app_ui.dart';
import '../../routing/routes.dart';
import '../common/symbol_search.dart';

/// Command-palette style symbol search (Ctrl/Cmd+K). Opens the quote page of the chosen symbol.
Future<void> showSearchPalette(BuildContext context) {
  final router = GoRouter.of(context);
  return showAppModal<void>(
    context,
    barrierColor: Colors.black38,
    builder: (ctx) => Align(
      alignment: const Alignment(0, -0.6),
      child: AppMaterialHost(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            child: AppSurface(
              depth: 4,
              radius: AppSpace.radiusL,
              padding: const EdgeInsets.all(AppSpace.s5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(header: true, child: Text('Search markets', style: ctx.text.titleMedium)),
                  const SizedBox(height: AppSpace.s3),
                  SymbolSearchField(
                    autofocus: true,
                    onSelected: (r) {
                      Navigator.of(ctx).pop();
                      router.push(Routes.quote(r.symbol));
                    },
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
