import 'package:collection/collection.dart';
import 'package:fp_growth/src/core/fp_growth.dart';
import 'package:fp_growth/src/core/fp_node.dart';
import 'package:test/test.dart';

void main() {
  group('FP-Growth Helper Functions', () {
    group('calculateAbsoluteMinSupport', () {
      test('treats values >= 1.0 as absolute count', () {
        expect(calculateAbsoluteMinSupport(3.0, 100), equals(3));
        expect(calculateAbsoluteMinSupport(1.0, 100), equals(1));
        expect(calculateAbsoluteMinSupport(10.5, 100), equals(10));
      });

      test('treats values < 1.0 as relative percentage', () {
        expect(calculateAbsoluteMinSupport(0.5, 100), equals(50));
        expect(calculateAbsoluteMinSupport(0.1, 50), equals(5));
        expect(calculateAbsoluteMinSupport(0.0, 100), equals(0));
      });

      test('ceil()s the result for relative support', () {
        expect(calculateAbsoluteMinSupport(0.095, 100), equals(10)); // 9.5 -> 10
        expect(calculateAbsoluteMinSupport(0.991, 1000), equals(991));
      });
    });

    group('filterFrequentItems', () {
      final frequency = {1: 5, 2: 2, 3: 10, 4: 2};

      test('filters items below absoluteMinSupport', () {
        final frequent = filterFrequentItems(frequency, 3);
        expect(frequent, equals({1: 5, 3: 10}));
      });

      test('includes items equal to absoluteMinSupport', () {
        final frequent = filterFrequentItems(frequency, 2);
        expect(frequent, equals({1: 5, 2: 2, 3: 10, 4: 2}));
      });

      test('returns an empty map if no items meet support', () {
        final frequent = filterFrequentItems(frequency, 11);
        expect(frequent, isEmpty);
      });
    });

    group('generateSubsets', () {
      test('generates all non-empty subsets for a list of nodes', () {
        final nodes = [
          FPNode(1, count: 1),
          FPNode(2, count: 1),
          FPNode(3, count: 1),
        ];

        final subsets = generateSubsets(nodes);
        final subsetItems =
            subsets.map((s) => s.map((n) => n.item).toSet()).toSet();

        expect(subsets.length, equals(7)); // 2^3 - 1
        expect(
          subsetItems,
          equals({
            {1},
            {2},
            {3},
            {1, 2},
            {1, 3},
            {2, 3},
            {1, 2, 3},
          }),
        );
      });

      test('returns a single subset for a single node', () {
        final nodes = [FPNode(1, count: 1)];
        final subsets = generateSubsets(nodes);
        expect(subsets.length, equals(1));
        expect(subsets[0][0].item, equals(1));
      });

      test('returns an empty list for no nodes', () {
        final subsets = generateSubsets([]);
        expect(subsets, isEmpty);
      });
    });

    group('buildConditionalTransactions', () {
      test('builds and orders transactions correctly', () {
        final conditionalPatternBases = {
          [1, 2, 3]: 2, // Path {c, b, a} with count 2
          [2, 4]: 1, // Path {b, d} with count 1
        };

        final conditionalFrequentItems = {
          1: 3, // a
          2: 5, // b
          3: 4, // c
          // item 4 is not frequent
        };

        final weightedTransactions = buildConditionalTransactions(
          conditionalPatternBases,
          conditionalFrequentItems,
        );

        // Expected order is by frequency descending: b, c, a
        // {b:5, c:4, a:3} -> [2, 3, 1]
        final expected = {
          [2, 3, 1]: 2, // from [1, 2, 3] -> ordered and filtered
          [2]: 1, // from [2, 4] -> filtered (4 is removed)
        };

        expect(
          MapEquality(keys: ListEquality(), values: Equality())
              .equals(weightedTransactions, expected),
          isTrue,
        );
      });

      test('handles empty pattern bases', () {
        final weightedTransactions = buildConditionalTransactions({}, {1: 2});
        expect(weightedTransactions, isEmpty);
      });

      test('handles empty frequent items', () {
        final conditionalPatternBases = {
          [1, 2]: 1,
        };
        final weightedTransactions =
            buildConditionalTransactions(conditionalPatternBases, {});
        expect(weightedTransactions, isEmpty);
      });

      test('handles stable sort when frequencies are equal', () {
        final conditionalPatternBases = {
          [1, 2]: 1,
        };
        final conditionalFrequentItems = {
          1: 5,
          2: 5,
        };
        final weightedTransactions = buildConditionalTransactions(
          conditionalPatternBases,
          conditionalFrequentItems,
        );
        // with equal frequency, sort by item ID ascending
        // The primary sort is by frequency descending. When equal, secondary sort is item ID ascending.
        expect(weightedTransactions.keys.first, equals([1, 2]));
      });
    });
  });
}
