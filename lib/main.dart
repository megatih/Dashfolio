import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/logging.dart';
import 'data/db/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initLogging();
  final db = AppDatabase();
  runApp(
    ProviderScope(
      // Failed providers surface their error in the UI with a manual retry instead of retrying silently.
      retry: (retryCount, error) => null,
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const DashfolioApp(),
    ),
  );
}
