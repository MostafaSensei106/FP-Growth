import 'package:collection/collection.dart';
import 'package:fp_growth/src/core/fp_tree.dart';
import 'package:test/test.dart';

void main() {
  group('FPTree', () {
    // A common setup for frequent items and transactions
    late Map<int, int> frequentItems;
    late List<List<int>> orderedTransactions;

    setUp(() {
      // Example from the original paper
      // Transactions:
      // {f, a, c, d, g, i, m, p}
      // {a, b, c, f, l, m, o}
      // {b, f, h, j, o}
      // {b, c, k, s, p}
      // {a, f, c, e, l, p, m, n}
      //
      // MinSupport = 3
      // Frequent Items (and their counts):
      // f: 4, c: 4, a: 3, b: 3, m: 3, p: 3
      frequentItems = {
        1: 4, // f
        2: 4, // c
        3: 3, // a
        4: 3, // b
        5: 3, // m
        6: 3, // p
      };

      // Transactions, filtered and ordered by frequency
      orderedTransactions = [
        [1, 2, 3, 5, 6], // f, c, a, m, p
        [1, 2, 3, 5], // f, c, a, m (b, l, o are infrequent)
        [1, 4], // f, b (h, j, o are infrequent)
        [2, 4, 6], // c, b, p (k, s are infrequent)
        [1, 2, 3, 5, 6], // f, c, a, m, p (e, l, n are infrequent)
      ];
    });

    test('constructor builds the tree correctly', () {
      final tree = FPTree(orderedTransactions, frequentItems);

      // Check root
      expect(tree.root.item, isNull);
      expect(tree.root.count, equals(1)); // Root count is nominal
      expect(tree.root.children.length,
          equals(2)); // Starts with 'f' (1) or 'c' (2)

      // Check header table initialization
      expect(tree.headerTable.length, equals(frequentItems.length));
      expect(tree.headerTable[1]!.count, equals(4)); // f
      expect(tree.headerTable[2]!.count, equals(4)); // c
      expect(tree.headerTable[3]!.count, equals(3)); // a

      // Check some paths to verify structure
      // Path: f(1) -> c(2) -> a(3) -> m(5) -> p(6)
      var node = tree.root.findChild(1)!;
      expect(node.count, equals(4)); // f appears in 4 paths starting with f
      node = node.findChild(2)!;
      expect(node.count, equals(3)); // c appears in 3 paths starting with f,c
      node = node.findChild(3)!;
      expect(node.count, equals(3)); // a appears in 3 paths starting with f,c,a
      node = node.findChild(5)!;
      expect(
          node.count, equals(3)); // m appears in 3 paths starting with f,c,a,m
      node = node.findChild(6)!;
      expect(node.count,
          equals(2)); // p appears in 2 paths starting with f,c,a,m,p

      // Check another path: c(2) -> b(4) -> p(6)
      node = tree.root.findChild(2)!;
      expect(node.count, equals(1)); // c appears in 1 path starting with c
      node = node.findChild(4)!;
      expect(node.count, equals(1)); // b appears in 1 path starting with c,b
      node = node.findChild(6)!;
      expect(node.count, equals(1)); // p appears in 1 path starting with c,b,p
    });

    test('header table links are established correctly', () {
      final tree = FPTree(orderedTransactions, frequentItems);

      // Check links for item 'p' (6)
      var pNode = tree.headerTable[6]!.head;
      expect(pNode, isNotNull);
      expect(pNode!.item, equals(6));
      expect(pNode.count, equals(2)); // First 'p' node

      pNode = pNode.next;
      expect(pNode, isNotNull);
      expect(pNode!.item, equals(6));
      expect(pNode.count, equals(1)); // Second 'p' node

      expect(pNode.next, isNull); // End of chain
    });

    test('findPaths returns correct conditional pattern bases', () {
      final tree = FPTree(orderedTransactions, frequentItems);

      // Find conditional pattern base for 'p' (6)
      final pPaths = tree.findPaths(6);
      final expectedPPaths = {
        [1, 2, 3, 5]: 2,
        [2, 4]: 1,
      };
      
      // Debugging print statements
      if (!MapEquality(keys: ListEquality(), values: Equality()).equals(pPaths, expectedPPaths)) {
        print('DEBUG: pPaths (actual): $pPaths');
        print('DEBUG: expectedPPaths: $expectedPPaths');
      }

      expect(
        MapEquality(keys: ListEquality(), values: Equality())
            .equals(pPaths, expectedPPaths),
        isTrue,
      );

      // Find conditional pattern base for 'm' (5)
      final mPaths = tree.findPaths(5);
      final expectedMPaths = {
        [1, 2, 3]: 3, // This should be 3 based on the corrected counts
      };

      // Debugging print statements
      if (!MapEquality(keys: ListEquality(), values: Equality()).equals(mPaths, expectedMPaths)) {
        print('DEBUG: mPaths (actual): $mPaths');
        print('DEBUG: expectedMPaths: $expectedMPaths');
      }

      expect(
        MapEquality(keys: ListEquality(), values: Equality())
            .equals(mPaths, expectedMPaths),
        isTrue,
      );
    });

    test('isSinglePath returns true for a single-path tree', () {
      final singlePathTransactions = [
        [1, 2, 3],
        [1, 2],
        [1],
      ];
      final singlePathFrequents = {1: 3, 2: 2, 3: 1};
      final tree = FPTree(singlePathTransactions, singlePathFrequents);

      expect(tree.isSinglePath(), isTrue);
    });

    test('isSinglePath returns false for a multi-path tree', () {
      final tree = FPTree(orderedTransactions, frequentItems);
      expect(tree.isSinglePath(), isFalse);
    });

    test('getSinglePathNodes returns the correct nodes', () {
      final singlePathTransactions = [
        [1, 2, 3],
        [1, 2],
      ];
      final singlePathFrequents = {1: 2, 2: 2, 3: 1};
      final tree = FPTree(singlePathTransactions, singlePathFrequents);

      final pathNodes = tree.getSinglePathNodes();
      expect(pathNodes.length, equals(3));
      expect(pathNodes[0].item, equals(1));
      expect(pathNodes[0].count, equals(2));
      expect(pathNodes[1].item, equals(2));
      expect(pathNodes[1].count, equals(2));
      expect(pathNodes[2].item, equals(3));
      expect(pathNodes[2].count, equals(1));
    });
  });
}
