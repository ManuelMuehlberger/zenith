import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:zenith/utils/app_logger.dart';

void main() {
  group('configureAppLogging', () {
    late List<LogInvocation> invocations;

    setUp(() async {
      await resetAppLoggingForTesting();
      invocations = [];
      setAppLogWriterForTesting((
        String message, {
        String name = '',
        DateTime? time,
        int level = 0,
        Object? error,
        StackTrace? stackTrace,
      }) {
        invocations.add(
          LogInvocation(
            message: message,
            name: name,
            time: time,
            level: level,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      });
    });

    tearDown(() async {
      await resetAppLoggingForTesting();
    });

    test('is idempotent while still updating the root level', () {
      configureAppLogging(level: Level.WARNING);
      configureAppLogging(level: Level.SEVERE);

      expect(Logger.root.level, Level.SEVERE);

      final stackTrace = StackTrace.current;
      Logger('AppLoggerTest').severe('only once', 'boom', stackTrace);

      expect(invocations, hasLength(1));
      expect(
        invocations.single,
        isA<LogInvocation>()
            .having((log) => log.message, 'message', 'only once')
            .having((log) => log.name, 'name', 'AppLoggerTest')
            .having((log) => log.level, 'level', Level.SEVERE.value)
            .having((log) => log.error, 'error', 'boom')
            .having((log) => log.stackTrace, 'stackTrace', same(stackTrace)),
      );
    });

    test('forwards matching root log records to the configured writer', () {
      configureAppLogging(level: Level.WARNING);

      Logger('AppLoggerTest').info('ignored');
      Logger('AppLoggerTest').warning('captured');

      expect(invocations, hasLength(1));
      expect(invocations.single.message, 'captured');
      expect(invocations.single.name, 'AppLoggerTest');
      expect(invocations.single.level, Level.WARNING.value);
      expect(invocations.single.time, isNotNull);
    });
  });
}

class LogInvocation {
  const LogInvocation({
    required this.message,
    required this.name,
    required this.time,
    required this.level,
    this.error,
    this.stackTrace,
  });

  final String message;
  final String name;
  final DateTime? time;
  final int level;
  final Object? error;
  final StackTrace? stackTrace;
}
