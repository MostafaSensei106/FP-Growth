import 'package:collection/collection.dart';
import 'package:fpgrowth_dart/fpgrowth_dart.dart';
import 'package:test/test.dart';

// Helper to compare maps where keys are lists of items (treated as sets).
bool areItemsetMapsEqual<T>(Map<List<T>, int> map1, Map<List<T>, int> map2) {
  if (map1.length != map2.length) return false;

  final setMap1 = map1.map((key, value) => MapEntry(key.toSet(), value));
  final setMap2 = map2.map((key, value) => MapEntry(key.toSet(), value));

  for (final entry in setMap1.entries) {
    final keySet = entry.key;
    final value = entry.value;

    final matchingEntry = setMap2.entries.firstWhereOrNull(
      (e) => SetEquality().equals(e.key, keySet),
    );

    if (matchingEntry == null || matchingEntry.value != value) {
      return false;
    }
  }
  return true;
}

void main() {
  group('FPGrowth Core Logic', () {
    test('correctly mines frequent itemsets with a simple dataset', () async {
      final transactions = [
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
      final fpGrowth = FPGrowth<String>(minSupport: 3);
      fpGrowth.addTransactions(transactions);
      final frequentItemsets = fpGrowth.mineFrequentItemsets();

      // Correctly calculated expected results
      final expectedFiltered = {
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

      expect(
          areItemsetMapsEqual(await frequentItemsets, expectedFiltered), isTrue,
          reason: "Expected: $expectedFiltered, but got: $frequentItemsets");
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
      final frequentItemsets = fpGrowth.mineFrequentItemsets();

      final expectedFiltered = {
        ['bread']: 4,
        ['milk']: 4,
        ['diaper']: 4,
        ['beer']: 3,
        ['bread', 'milk']: 3,
        ['bread', 'diaper']: 3,
        ['milk', 'diaper']: 3,
        ['diaper', 'beer']: 3,
      };

      expect(
          areItemsetMapsEqual(await frequentItemsets, expectedFiltered), isTrue,
          reason: "Expected: $expectedFiltered, but got: $frequentItemsets");
    });

    test('returns empty map when no transactions are provided', () {
      final fpGrowth = FPGrowth<String>(minSupport: 2);
      final frequentItemsets = fpGrowth.mineFrequentItemsets();
      expect(frequentItemsets, isEmpty);
    });

    test('returns empty map when minSupport is too high', () {
      final transactions = [
        ['a', 'b'],
        ['b', 'c']
      ];
      final fpGrowth = FPGrowth<String>(minSupport: 10);
      fpGrowth.addTransactions(transactions);
      final frequentItemsets = fpGrowth.mineFrequentItemsets();
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
      final frequentItemsets = fpGrowth.mineFrequentItemsets();
      final expected = {
        ['a']: 2,
        ['b']: 3,
      };
      expect(areItemsetMapsEqual(await frequentItemsets, expected), isTrue);
    });
  });
}
