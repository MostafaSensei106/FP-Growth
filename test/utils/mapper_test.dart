import 'package:fp_growth/src/utils/mapper.dart';
import 'package:test/test.dart';

void main() {
  group('ItemMapper', () {
    late ItemMapper<String> mapper;

    setUp(() {
      mapper = ItemMapper<String>();
    });

    test('getId assigns a new ID for a new item', () {
      final id1 = mapper.getId('a');
      expect(id1, equals(0));
      expect(mapper.itemCount, equals(1));

      final id2 = mapper.getId('b');
      expect(id2, equals(1));
      expect(mapper.itemCount, equals(2));
    });

    test('getId returns the existing ID for a known item', () {
      final id1 = mapper.getId('a');
      final id2 = mapper.getId('b');
      final id3 = mapper.getId('a');

      expect(id1, equals(0));
      expect(id2, equals(1));
      expect(id3, equals(0));
      expect(mapper.itemCount, equals(2));
    });

    test('getItem returns the correct item for an ID', () {
      mapper.getId('a');
      mapper.getId('b');

      expect(mapper.getItem(0), equals('a'));
      expect(mapper.getItem(1), equals('b'));
    });

    test('getItem throws StateError for an unknown ID', () {
      expect(() => mapper.getItem(99), throwsA(isA<StateError>()));
    });

    test('mapTransaction converts a transaction to IDs', () {
      final transaction = ['a', 'b', 'a', 'c'];
      final mapped = mapper.mapTransaction(transaction);

      expect(mapped, equals([0, 1, 0, 2]));
      expect(mapper.itemCount, equals(3));
    });

    test('unmapItemset converts an itemset of IDs back to items', () {
      mapper.mapTransaction(['a', 'b', 'c']);
      final itemset = [2, 0, 1];
      final unmapped = mapper.unmapItemset(itemset);

      expect(unmapped, equals(['c', 'a', 'b']));
    });

    test('hasItem and hasId work correctly', () {
      mapper.getId('a');

      expect(mapper.hasItem('a'), isTrue);
      expect(mapper.hasItem('b'), isFalse);
      expect(mapper.hasId(0), isTrue);
      expect(mapper.hasId(1), isFalse);
    });

    test('clear resets the mapper', () {
      mapper.getId('a');
      mapper.getId('b');

      expect(mapper.itemCount, equals(2));
      expect(mapper.nextId, equals(2));

      mapper.clear();

      expect(mapper.itemCount, isZero);
      expect(mapper.nextId, isZero);
      expect(mapper.hasItem('a'), isFalse);
      expect(mapper.hasId(0), isFalse);
    });

    test('fromMaps constructor correctly reconstructs the mapper', () {
      final itemToId = {'a': 0, 'b': 1};
      final idToItem = {0: 'a', 1: 'b'};
      final nextId = 2;

      final reconstructedMapper =
          ItemMapper.fromMaps(itemToId, idToItem, nextId);

      expect(reconstructedMapper.itemCount, equals(2));
      expect(reconstructedMapper.nextId, equals(2));
      expect(reconstructedMapper.getItem(0), equals('a'));
      expect(reconstructedMapper.getId('b'), equals(1));

      // Check that it can assign a new ID
      expect(reconstructedMapper.getId('c'), equals(2));
    });
  });
}
