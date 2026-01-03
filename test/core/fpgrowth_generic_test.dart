import 'package:collection/collection.dart';
import 'package:fp_growth/fp_growth.dart';
import 'package:test/test.dart';

// Helper from fpgrowth_test.dart
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

class _TestItem {
  final String id;
  _TestItem(this.id);

  @override
  String toString() => 'Item($id)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

void main() {
  group('FPGrowth with Generic Types', () {
    test('correctly mines with <int> type', () async {
      final transactions = [
        [1, 2, 5],
        [2, 4],
        [2, 3],
        [1, 2, 4],
        [1, 3],
        [2, 3],
        [1, 3],
        [1, 2, 3, 5],
        [1, 2, 3],
      ];

      final fpGrowth = FPGrowth<int>(minSupport: 3);
      final (frequentItemsets, _) = await fpGrowth.mineFromList(transactions);

      final expected = {
        [1]: 6,
        [2]: 7,
        [3]: 6,
        [5]: 2,
        [4]: 2,
        [1, 2]: 4,
        [1, 3]: 4,
        [2, 3]: 4,
        [1, 2, 3]: 2,
      };

      final expectedFiltered = Map<List<int>, int>.from(expected)
        ..removeWhere((k, v) => v < 3);

      expect(
        areItemsetMapsEqual(frequentItemsets, expectedFiltered),
        isTrue,
        reason:
            "Expected integer itemsets: $expectedFiltered, but got: $frequentItemsets",
      );
    });

    test('correctly mines with a custom object type', () async {
      final i1 = _TestItem('1');
      final i2 = _TestItem('2');
      final i3 = _TestItem('3');
      final i4 = _TestItem('4');

      final transactions = [
        [i1, i2],
        [i2, i3],
        [i1, i2, i4],
        [i1, i2, i3],
        [i1, i3],
        [i2, i3],
      ];

      final fpGrowth = FPGrowth<_TestItem>(minSupport: 3);
      final (frequentItemsets, _) = await fpGrowth.mineFromList(transactions);

      final expected = {
        [i1]: 4,
        [i2]: 5,
        [i3]: 4,
        [i1, i2]: 3,
        [i1, i3]: 2,
        [i2, i3]: 3,
      };

      final expectedFiltered = Map<List<_TestItem>, int>.from(expected)
        ..removeWhere((k, v) => v < 3);

      expect(
        areItemsetMapsEqual(frequentItemsets, expectedFiltered),
        isTrue,
        reason:
            "Expected custom object itemsets: $expectedFiltered, but got: $frequentItemsets",
      );
    });
  });
}
