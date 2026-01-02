import 'package:fp_growth/src/core/fp_node.dart';
import 'package:test/test.dart';

void main() {
  group('FPNode', () {
    test('constructor initializes properties correctly', () {
      final parent = FPNode(null);
      final node = FPNode(1, parent: parent, count: 5);

      expect(node.item, equals(1));
      expect(node.parent, same(parent));
      expect(node.count, equals(5));
      expect(node.children, isEmpty);
      expect(node.next, isNull);
    });

    test('default count is 0', () {
      final node = FPNode(1);
      expect(node.count, equals(0));
    });

    test('incrementCount increases the count', () {
      final node = FPNode(1, count: 3);
      node.incrementCount();
      expect(node.count, equals(4));

      node.incrementCount(5);
      expect(node.count, equals(9));
    });

    test('addChild adds a child if it does not exist', () {
      final parent = FPNode(null);
      final child = FPNode(1);
      parent.addChild(child);

      expect(parent.children.length, equals(1));
      expect(parent.children[1], same(child));
    });

    test('addChild does not add a child if it already exists', () {
      final parent = FPNode(null);
      final child1 = FPNode(1);
      final child2 = FPNode(1, count: 10); // Different instance, same item
      parent.addChild(child1);
      parent.addChild(child2);

      expect(parent.children.length, equals(1));
      expect(parent.children[1], same(child1)); // Should keep the first one
    });

    test('findChild returns the correct child node', () {
      final parent = FPNode(null);
      final child1 = FPNode(1);
      final child2 = FPNode(2);
      parent.addChild(child1);
      parent.addChild(child2);

      expect(parent.findChild(1), same(child1));
      expect(parent.findChild(2), same(child2));
    });

    test('findChild returns null if child does not exist', () {
      final parent = FPNode(null);
      final child = FPNode(1);
      parent.addChild(child);

      expect(parent.findChild(99), isNull);
    });

    test('equality operator works correctly', () {
      final node1 = FPNode(1, count: 5);
      final node2 = FPNode(1, count: 5);
      final node3 = FPNode(2, count: 5);
      final node4 = FPNode(1, count: 6);

      expect(node1 == node2, isTrue);
      expect(node1 == node3, isFalse);
      expect(node1 == node4, isFalse);
      expect(node1 == FPNode(1, count: 5), isTrue);
    });

    test('hashCode is consistent with equality', () {
      final node1 = FPNode(1, count: 5);
      final node2 = FPNode(1, count: 5);
      final node3 = FPNode(2, count: 5);

      expect(node1.hashCode, equals(node2.hashCode));
      expect(node1.hashCode, isNot(equals(node3.hashCode)));
    });
  });
}
