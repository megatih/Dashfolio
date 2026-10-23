import 'dart:developer' as dev;

import 'package:logging/logging.dart';

void initLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((r) {
    dev.log(r.message, name: r.loggerName, level: r.level.value, error: r.error, stackTrace: r.stackTrace);
  });
}
