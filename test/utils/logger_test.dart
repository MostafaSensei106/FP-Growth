import 'dart:async';

import 'package:fp_growth/src/utils/logger.dart';
import 'package:test/test.dart';

void main() {
  group('Logger', () {
    test('default level is info', () {
      final logger = Logger();
      expect(logger.currentLevel, equals(LogLevel.info));
    });

    test('level can be set', () {
      final logger = Logger();
      logger.level = LogLevel.warning;
      expect(logger.currentLevel, equals(LogLevel.warning));
    });

    test('shouldLog works correctly', () {
      expect(LogLevel.info.shouldLog(LogLevel.debug), isTrue);
      expect(LogLevel.debug.shouldLog(LogLevel.info), isFalse);
      expect(LogLevel.warning.shouldLog(LogLevel.info), isTrue);
      expect(LogLevel.info.shouldLog(LogLevel.warning), isFalse);
      expect(LogLevel.critical.shouldLog(LogLevel.critical), isTrue);
      expect(LogLevel.debug.shouldLog(LogLevel.none), isFalse);
    });

    test('isEnabled works correctly', () {
      final logger = Logger(initialLevel: LogLevel.warning);
      expect(logger.isEnabled(LogLevel.debug), isFalse);
      expect(logger.isEnabled(LogLevel.info), isFalse);
      expect(logger.isEnabled(LogLevel.warning), isTrue);
      expect(logger.isEnabled(LogLevel.error), isTrue);
      expect(logger.isEnabled(LogLevel.critical), isTrue);
    });

    test('enableAll sets level to debug', () {
      final logger = Logger(initialLevel: LogLevel.critical);
      logger.enableAll();
      expect(logger.currentLevel, equals(LogLevel.debug));
    });

    test('disableAll sets level to none', () {
      final logger = Logger();
      logger.disableAll();
      expect(logger.currentLevel, equals(LogLevel.none));
    });

    group('Logging Output', () {
      Future<List<String>> captureOutput(
        Logger logger,
        void Function(Logger) logAction,
      ) {
        final completer = Completer<List<String>>();
        final captured = <String>[];

        runZoned(
          () {
            logAction(logger);
            // A small delay to ensure all async prints are captured.
            Future.delayed(Duration(milliseconds: 10), () {
              completer.complete(captured);
            });
          },
          zoneSpecification: ZoneSpecification(
            print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
              captured.add(line);
            },
          ),
        );

        return completer.future;
      }

      test('logs messages at or above the current level', () async {
        final logger = Logger(initialLevel: LogLevel.info);
        final output = await captureOutput(logger, (l) {
          l.debug('should not be seen');
          l.info('info message');
          l.warning('warning message');
        });

        expect(output.length, equals(2));
        expect(output[0], contains('[INFO    ] info message'));
        expect(output[1], contains('[WARNING ] warning message'));
      });

      test('logs nothing when level is none', () async {
        final logger = Logger(initialLevel: LogLevel.none);
        final output = await captureOutput(logger, (l) {
          l.critical('should not be seen');
        });

        expect(output, isEmpty);
      });

      test('logs all messages when level is debug', () async {
        final logger = Logger(initialLevel: LogLevel.debug);
        final output = await captureOutput(logger, (l) {
          l.debug('d');
          l.info('i');
          l.warning('w');
          l.error('e');
          l.critical('c');
        });

        expect(output.length, equals(5));
        expect(output[0], contains('[DEBUG   ] d'));
        expect(output[1], contains('[INFO    ] i'));
        expect(output[2], contains('[WARNING ] w'));
        expect(output[3], contains('[ERROR   ] e'));
        expect(output[4], contains('[CRITICAL] c'));
      });

      test('logWithPrefix includes the prefix', () async {
        final logger = Logger();
        final output = await captureOutput(logger, (l) {
          l.logWithPrefix(LogLevel.info, 'MyPrefix', 'My message');
        });
        expect(output.length, equals(1));
        expect(output[0], contains('[INFO    ] [MyPrefix] My message'));
      });
    });
  });
}
