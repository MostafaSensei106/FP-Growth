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

// Helper to generate all non-empty proper subsets of a set
Set<Set<T>> getProperSubsets<T>(Set<T> itemset) {
  if (itemset.length <= 1) {
    return {};
  }

  final subsets = <Set<T>>{};
  // Iterate from 1 to 2^n - 2 to get all non-empty proper subsets.
  for (var i = 1; i < (1 << itemset.length) - 1; i++) {
    final subset = <T>{};
    for (var j = 0; j < itemset.length; j++) {
      // Check if the j-th bit is set in the integer i
      if ((i >> j) & 1 == 1) {
        subset.add(itemset.elementAt(j));
      }
    }
    subsets.add(subset);
  }
  return subsets;
}

void main() {
  group('FPGrowth Property-Based Tests', () {
    test('results are independent of input transaction order', () async {
      final transactions = generateRandomTransactions(
        numTransactions: 200,
        alphabetSize: 20,
      );
      const minSupport = 10;

      final fpGrowth1 = FPGrowth<String>(minSupport: minSupport.toDouble());
      fpGrowth1.addTransactions(transactions);
      final result1 = await fpGrowth1.mineFrequentItemsets();

      transactions.shuffle(); // Shuffle the order

      final fpGrowth2 = FPGrowth<String>(minSupport: minSupport.toDouble());
      fpGrowth2.addTransactions(transactions);
      final result2 = await fpGrowth2.mineFrequentItemsets();

      expect(
        areItemsetMapsEqual(result1, result2),
        isTrue,
        reason: 'Results should be identical regardless of transaction order.',
      );
    });

    test('frequent itemset property (monotonicity) holds', () async {
      // If an itemset is frequent, all of its subsets must also be frequent.
      final transactions = generateRandomTransactions(
        numTransactions: 500,
        maxItemsPerTransaction: 8,
        alphabetSize: 25,
      );
      const minSupport = 20;
      final fpGrowth = FPGrowth<String>(minSupport: minSupport.toDouble());
      fpGrowth.addTransactions(transactions);
      final frequentItemsets = await fpGrowth.mineFrequentItemsets();

      final frequentKeysAsSets = frequentItemsets.keys
          .map((k) => k.toSet())
          .toSet();

      for (final itemset in frequentItemsets.keys) {
        if (itemset.length > 1) {
          final subsets = getProperSubsets(itemset.toSet());
          for (final subset in subsets) {
            expect(
              frequentKeysAsSets.any((s) => SetEquality().equals(s, subset)),
              isTrue,
              reason:
                  'Subset $subset of frequent itemset $itemset was not found in frequent sets.',
            );
          }
        }
      }
    });

    test(
      'all returned itemsets meet minSupport and have correct count',
      () async {
        final transactions = generateRandomTransactions(
          numTransactions: 300,
          alphabetSize: 30,
        );
        const minSupport = 15;

        final fpGrowth = FPGrowth<String>(minSupport: minSupport.toDouble());
        fpGrowth.addTransactions(transactions);
        final frequentItemsets = await fpGrowth.mineFrequentItemsets();

        for (final entry in frequentItemsets.entries) {
          final itemset = entry.key;
          final reportedSupport = entry.value;

          // Manually calculate support to verify
          int actualSupport = 0;
          for (final transaction in transactions) {
            if (itemset.every((item) => transaction.contains(item))) {
              actualSupport++;
            }
          }

          expect(
            reportedSupport,
            equals(actualSupport),
            reason: 'Reported support for $itemset is incorrect.',
          );
          expect(
            actualSupport,
            greaterThanOrEqualTo(minSupport),
            reason:
                'Itemset $itemset has support $actualSupport, which is below minSupport $minSupport.',
          );
        }
      },
    );
  });
}
