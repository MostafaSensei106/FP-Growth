import 'dart:math';
import 'package:collection/collection.dart';
import 'package:fp_growth/fp_growth.dart';
import 'package:test/test.dart';

// Helper to compare maps where keys are lists of items (treated as sets).
bool areItemsetMapsEqual<T>(Map<List<T>, int> map1, Map<List<T>, int> map2) {
  if (map1.length != map2.length) {
    print('Maps have different lengths: ${map1.length} vs ${map2.length}');
    return false;
  }

  final setMap1 = map1.map((key, value) => MapEntry(key.toSet(), value));
  final setMap2 = map2.map((key, value) => MapEntry(key.toSet(), value));

  for (final entry in setMap1.entries) {
    final keySet = entry.key;
    final value = entry.value;

    final matchingEntry = setMap2.entries.firstWhereOrNull(
      (e) => SetEquality().equals(e.key, keySet),
    );

    if (matchingEntry == null) {
      print('Key not found in second map: $keySet');
      return false;
    }
    if (matchingEntry.value != value) {
      print('Value mismatch for key $keySet: ${matchingEntry.value} vs $value');
      return false;
    }
  }
  return true;
}

// Helper to generate random transactions
List<List<String>> generateRandomTransactions({
  int numTransactions = 100,
  int maxItemsPerTransaction = 10,
  int alphabetSize = 20,
}) {
  final random = Random();
  final transactions = <List<String>>[];
  final alphabet = List.generate(alphabetSize, (i) => 'item_$i');

  for (var i = 0; i < numTransactions; i++) {
    final transactionSize = random.nextInt(maxItemsPerTransaction) + 1;
    final transaction = <String>{}; // Use a set to avoid duplicates
    for (var j = 0; j < transactionSize; j++) {
      transaction.add(alphabet[random.nextInt(alphabetSize)]);
    }
    transactions.add(transaction.toList());
  }
  return transactions;
}

void main() {
  group('FPGrowth Stress Tests', () {
    // These tests can be slow and are meant to be run manually or in a CI
    // environment that can handle longer test durations. To exclude them, run:
    // dart test --exclude-tags=slow

    test('handles 10k transactions', () async {
      final transactions = generateRandomTransactions(
        numTransactions: 10000,
        maxItemsPerTransaction: 15,
        alphabetSize: 50,
      );
      final fpGrowth = FPGrowth<String>(minSupport: 100.0); // 1% support
      final stopwatch = Stopwatch()..start();

      final (frequentItemsets, _) = await fpGrowth.mine(
        () => Stream.fromIterable(transactions),
      );
      stopwatch.stop();

      print(
        'Stress Test (10k txs) completed in ${stopwatch.elapsedMilliseconds} ms.',
      );
      print('Found ${frequentItemsets.length} frequent itemsets.');

      // Basic sanity check
      expect(frequentItemsets, isNotNull);
      // We can't know the exact number of frequent itemsets, but it shouldn't be empty with this setup.
      expect(frequentItemsets, isNotEmpty);
    }, timeout: Timeout(Duration(minutes: 2)));

    test('handles a huge single transaction', () async {
      final hugeTransaction = List.generate(5000, (i) => 'item_$i');
      final transactions = [
        hugeTransaction,
        ['item_1', 'item_2', 'item_3'],
        ['item_1', 'item_2', 'item_99'],
      ];

      final fpGrowth = FPGrowth<String>(minSupport: 2.0);
      final (frequentItemsets, _) = await fpGrowth.mine(
        () => Stream.fromIterable(transactions),
      );

      final expected = {
        ['item_1']: 3,
        ['item_2']: 3,
        ['item_3']: 2,
        ['item_99']: 2,
        ['item_1', 'item_2']: 3,
        ['item_1', 'item_3']: 2,
        ['item_2', 'item_3']: 2,
        ['item_1', 'item_2', 'item_3']: 2,
        ['item_1', 'item_99']: 2,
        ['item_2', 'item_99']: 2,
        ['item_1', 'item_2', 'item_99']: 2,
      };

      expect(
        areItemsetMapsEqual(frequentItemsets, expected),
        isTrue,
        reason: "Expected: $expected, but got: $frequentItemsets",
      );
    });

    // This test is very slow and should be run manually.
    // To run it, remove the skip tag and run:
    // dart test --run-skipped
    test(
      'handles 100k transactions',
      () async {
        final transactions = generateRandomTransactions(
          numTransactions: 100000,
          maxItemsPerTransaction: 20,
          alphabetSize: 100,
        );
        final fpGrowth = FPGrowth<String>(minSupport: 1000.0); // 1% support
        final stopwatch = Stopwatch()..start();

        final (frequentItemsets, _) = await fpGrowth.mine(
          () => Stream.fromIterable(transactions),
        );
        stopwatch.stop();

        print(
          'Stress Test (100k txs) completed in ${stopwatch.elapsedMilliseconds} ms.',
        );
        print('Found ${frequentItemsets.length} frequent itemsets.');

        expect(frequentItemsets, isNotNull);
        expect(frequentItemsets, isNotEmpty);
      },
      timeout: Timeout(Duration(minutes: 5)),
      tags: ['slow'],
    );
  });
}
