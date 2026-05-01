import 'dart:async';
import 'dart:developer' as developer;

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

// policy: allow-public-api injectable log sink for tests.
typedef AppLogWriter =
    void Function(
      String message, {
      String name,
      DateTime? time,
      int level,
      Object? error,
      StackTrace? stackTrace,
    });

bool _loggingConfigured = false;
StreamSubscription<LogRecord>? _rootLogSubscription;

void _defaultAppLogWriter(
  String message, {
  String name = '',
  DateTime? time,
  int level = 0,
  Object? error,
  StackTrace? stackTrace,
}) {
  developer.log(
    message,
    name: name,
    time: time,
    level: level,
    error: error,
    stackTrace: stackTrace,
  );
}

AppLogWriter _appLogWriter = _defaultAppLogWriter;

void configureAppLogging({Level level = Level.INFO}) {
  Logger.root.level = level;

  if (_loggingConfigured) {
    return;
  }

  _rootLogSubscription = Logger.root.onRecord.listen((record) {
    _appLogWriter(
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

// policy: allow-public-api test helper for asserting emitted log records.
@visibleForTesting
void setAppLogWriterForTesting(AppLogWriter writer) {
  _appLogWriter = writer;
}

// policy: allow-public-api test helper for resetting global logging state.
@visibleForTesting
Future<void> resetAppLoggingForTesting() async {
  await _rootLogSubscription?.cancel();
  _rootLogSubscription = null;
  _appLogWriter = _defaultAppLogWriter;
  _loggingConfigured = false;
  Logger.root.level = Level.INFO;
}
