import 'dart:async';
import 'package:fp_growth/fp_growth.dart';
import 'package:test/test.dart';
import 'package:collection/collection.dart';

void main() {
  group('StreamProcessor', () {
    late FPGrowth<String> fpGrowth;
    late StreamProcessor<String> streamProcessor;

    setUp(() {
      fpGrowth = FPGrowth<String>(minSupport: 2);
      streamProcessor = StreamProcessor<String>(fpGrowth);
    });

    test('processes a stream of transactions correctly', () async {
      final transactions = [
        ['a', 'b'],
        ['b', 'c'],
        ['a', 'b', 'c'],
        ['c'],
      ];
      final stream = Stream.fromIterable(transactions);

      await streamProcessor.process(stream);

      expect(fpGrowth.transactionCount, equals(4));

      final frequentItemsets = await fpGrowth.mineFrequentItemsets();
      final expected = {
        ['a']: 2,
        ['b']: 3,
        ['c']: 3,
        ['a', 'b']: 2,
        ['b', 'c']: 2,
      };

      // Using a helper from another test file is not ideal, but for this case it's ok.
      // A better approach would be to have a shared test utility file.
      final setMap1 = frequentItemsets.map(
        (key, value) => MapEntry(key.toSet(), value),
      );
      final setMap2 = expected.map(
        (key, value) => MapEntry(key.toSet(), value),
      );
      expect(
        MapEquality(
          keys: SetEquality(),
          values: Equality(),
        ).equals(setMap1, setMap2),
        isTrue,
      );
    });

    test('handles an empty stream', () async {
      final stream = Stream<List<String>>.empty();
      await streamProcessor.process(stream);
      expect(fpGrowth.transactionCount, isZero);
      final frequentItemsets = await fpGrowth.mineFrequentItemsets();
      expect(frequentItemsets, isEmpty);
    });

    test('handles a stream with empty transactions', () async {
      final transactions = <List<String>>[
        ['a', 'b'],
        [],
        ['b', 'c'],
        [],
      ];

      final stream = Stream.fromIterable(transactions);

      await streamProcessor.process(stream);

      expect(
        fpGrowth.transactionCount,
        equals(2),
      ); // Empty transactions are ignored
    });
  });
}
