import 'dart:developer' as developer;

import 'package:logging/logging.dart';

bool _loggingConfigured = false;

void configureAppLogging({Level level = Level.INFO}) {
  Logger.root.level = level;

  if (_loggingConfigured) {
    return;
  }

  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      name: record.loggerName,
      time: record.time,
      level: record.level.value,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  _loggingConfigured = true;
}
