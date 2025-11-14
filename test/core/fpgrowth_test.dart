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

void main() {
  group('FPGrowth Core Logic', () {
    final simpleTransactions = [
      ['a', 'b'],
      ['b', 'c', 'd'],
      ['a', 'c', 'd', 'e'],
      ['a', 'd', 'e'],
      ['a', 'b', 'c'],
      ['a', 'b', 'c', 'd'],
      ['a'],
      ['a', 'b', 'd'],
      ['a', 'b'],
      ['c', 'e']
    ];

    test('correctly mines frequent itemsets with a simple dataset', () async {
      final fpGrowth = FPGrowth<String>(minSupport: 3);
      fpGrowth.addTransactions(simpleTransactions);
      final frequentItemsets = await fpGrowth.mineFrequentItemsets();

      // The original test case had an incomplete expected result.
      // After manual verification, the following are the correct frequent itemsets
      // with minSupport=3. The itemset {a, c} has support 3, but {a, c, d} only has support 2.
      // Let's re-verify the logic.
      // Transactions with {a,c,d}:
      // 1. a, c, d, e
      // 2. a, b, c, d
      // Support is 2. So if minSupport is 3, {a,c,d} should NOT be in the result.
      // Let's check the original expected result again.
      final expected = {
        ['a']: 8,
        ['b']: 6,
        ['c']: 5,
        ['d']: 5,
        ['e']: 3,
        ['a', 'b']: 5,
        ['a', 'd']: 4,
        ['a', 'c']: 3,
        ['b', 'c']: 3,
        ['b', 'd']: 3,
        ['c', 'd']: 3,
      };

      expect(areItemsetMapsEqual(frequentItemsets, expected), isTrue,
          reason: "Expected: $expected, but got: $frequentItemsets");
    });

    test('matches original test case with corrected expectations', () async {
      final transactions = [
        ['bread', 'milk'],
        ['bread', 'diaper', 'beer', 'eggs'],
        ['milk', 'diaper', 'beer', 'cola'],
        ['bread', 'milk', 'diaper', 'beer'],
        ['bread', 'milk', 'diaper', 'cola'],
      ];
      final fpGrowth = FPGrowth<String>(minSupport: 3);
      fpGrowth.addTransactions(transactions);
      final frequentItemsets = await fpGrowth.mineFrequentItemsets();

      final expectedFiltered = {
        ['bread']: 4,
        ['milk']: 4,
        ['diaper']: 4,
        ['beer']: 3,
        ['bread', 'milk']: 3,
        ['bread', 'diaper']: 3,
        ['milk', 'diaper']: 3,
        ['diaper', 'beer']: 3,
        // Added based on re-evaluation.
        // {bread, milk, diaper} appears in 2 txs.
        // {bread, diaper, beer} appears in 1 tx.
        // {milk, diaper, beer} appears in 2 txs.
        // With minSupport=3, no 3-item sets should be frequent.
        // Let's check the logic for {bread, milk, diaper}
        // tx 4: bread, milk, diaper, beer
        // tx 5: bread, milk, diaper, cola
        // Support is 2. So it should not be in the result.
        // The provided test seems to have an error in its frequent itemsets.
        // Let's re-run with the implementation's output.
        // The implementation seems to be missing {bread, milk, diaper} which has support 2.
        // And {milk, diaper, beer} which has support 2.
        // The provided frequent itemsets are correct for minSupport=3.
      };

      expect(areItemsetMapsEqual(frequentItemsets, expectedFiltered), isTrue,
          reason: "Expected: $expectedFiltered, but got: $frequentItemsets");
    });

    test('returns empty map when no transactions are provided', () async {
      final fpGrowth = FPGrowth<String>(minSupport: 2);
      final frequentItemsets = await fpGrowth.mineFrequentItemsets();
      expect(frequentItemsets, isEmpty);
    });

    test('handles transactions with empty lists', () async {
      final transactionsWithEmpty = <List<String>>[
        ['a', 'b'],
        [],
        ['b', 'c'],
        []
      ];
      final fpGrowth = FPGrowth<String>(minSupport: 2);
      fpGrowth.addTransactions(transactionsWithEmpty);
      final frequentItemsets = await fpGrowth.mineFrequentItemsets();
      final expected = {
        ['b']: 2,
      };
      expect(areItemsetMapsEqual(frequentItemsets, expected), isTrue);
      expect(fpGrowth.transactionCount, equals(2)); // Should ignore empty txs
    });

    test('returns empty map when minSupport is too high', () async {
      final transactions = [
        ['a', 'b'],
        ['b', 'c']
      ];
      final fpGrowth = FPGrowth<String>(minSupport: 10);
      fpGrowth.addTransactions(transactions);
      final frequentItemsets = await fpGrowth.mineFrequentItemsets();
      expect(frequentItemsets, isEmpty);
    });

    test('handles transactions with single items correctly', () async {
      final transactions = [
        ['a'],
        ['a'],
        ['b'],
        ['b'],
        ['b']
      ];
      final fpGrowth = FPGrowth<String>(minSupport: 2);
      fpGrowth.addTransactions(transactions);
      final frequentItemsets = await fpGrowth.mineFrequentItemsets();
      final expected = {
        ['a']: 2,
        ['b']: 3,
      };
      expect(areItemsetMapsEqual(frequentItemsets, expected), isTrue);
    });

    test('correctly applies single-path optimization', () async {
      // In a single-path tree, all combinations of nodes on the path are frequent
      final transactions = [
        ['a', 'b', 'c'],
        ['a', 'b'],
        ['a'],
      ];
      final fpGrowth = FPGrowth<String>(minSupport: 1);
      fpGrowth.addTransactions(transactions);
      final frequentItemsets = await fpGrowth.mineFrequentItemsets();

      final expected = {
        ['a']: 3,
        ['b']: 2,
        ['c']: 1,
        ['a', 'b']: 2,
        ['a', 'c']: 1,
        ['b', 'c']: 1,
        ['a', 'b', 'c']: 1,
      };

      expect(areItemsetMapsEqual(frequentItemsets, expected), isTrue,
          reason: "Expected: $expected, but got: $frequentItemsets");
    });
  });

  group('FPGrowth Parallelism', () {
    final transactions = [
      ['a', 'b', 'c', 'd', 'e', 'f'],
      ['a', 'c', 'e'],
      ['b', 'd', 'f'],
      ['a', 'b', 'c', 'd'],
      ['f', 'h', 'i'],
      ['a', 'b', 'c'],
      ['a', 'b', 'd'],
      ['b', 'c', 'd'],
      ['a', 'e', 'f'],
      ['b', 'c', 'e']
    ];

    test('produces identical results with parallelism = 2', () async {
      final singleThreaded = FPGrowth<String>(minSupport: 3, parallelism: 1);
      singleThreaded.addTransactions(transactions);
      final singleResult = await singleThreaded.mineFrequentItemsets();

      final multiThreaded = FPGrowth<String>(minSupport: 3, parallelism: 2);
      multiThreaded.addTransactions(transactions);
      final multiResult = await multiThreaded.mineFrequentItemsets();

      expect(areItemsetMapsEqual(multiResult, singleResult), isTrue,
          reason: 'Parallel (2) results do not match single-threaded results.');
    });

    test('produces identical results with parallelism = 4', () async {
      final singleThreaded = FPGrowth<String>(minSupport: 3, parallelism: 1);
      singleThreaded.addTransactions(transactions);
      final singleResult = await singleThreaded.mineFrequentItemsets();

      final multiThreaded = FPGrowth<String>(minSupport: 3, parallelism: 4);
      multiThreaded.addTransactions(transactions);
      final multiResult = await multiThreaded.mineFrequentItemsets();

      expect(areItemsetMapsEqual(multiResult, singleResult), isTrue,
          reason: 'Parallel (4) results do not match single-threaded results.');
    });

    test('handles case where parallelism > number of frequent items', () async {
      final singleThreaded = FPGrowth<String>(minSupport: 3, parallelism: 1);
      singleThreaded.addTransactions(transactions);
      final singleResult = await singleThreaded.mineFrequentItemsets();

      // There are fewer than 20 frequent items, so this tests the logic
      final multiThreaded = FPGrowth<String>(minSupport: 3, parallelism: 20);
      multiThreaded.addTransactions(transactions);
      final multiResult = await multiThreaded.mineFrequentItemsets();

      expect(areItemsetMapsEqual(multiResult, singleResult), isTrue,
          reason:
              'Parallel (20) results do not match single-threaded results.');
    });
  });
}
