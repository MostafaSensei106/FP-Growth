import 'fp_node.dart';

/// A record to hold header table information, including the total count
/// of an item and the head/tail of its node-link list in the FP-Tree.
typedef Header = ({int count, FPNode? head, FPNode? tail});

/// Represents the FP-Tree (Frequent Pattern Tree).
///
/// The tree is built by processing a set of transactions. It stores frequent
/// item IDs in a compact structure that is used for mining frequent itemsets.
class FPTree {
  /// The root of the tree. It does not represent any item.
  final FPNode root = FPNode(null);

  /// The header table for the tree.
  /// Maps each frequent item ID to its frequency count and the head of the node-link list.
  final Map<int, Header> headerTable = {};

  /// Builds the FP-Tree from a set of transactions and a frequency map.
  ///
  /// [transactions] is an iterable of transactions, where each transaction is a
  /// list of item IDs. These transactions must be pre-filtered to contain only
  /// frequent items and sorted by frequency in descending order.
  /// [frequency] is a map of frequent item IDs to their frequency counts.
  FPTree(Iterable<List<int>> transactions, Map<int, int> frequency) {
    // Initialize header table with frequent items and their counts.
    for (final item in frequency.keys) {
      headerTable[item] = (count: frequency[item]!, head: null, tail: null);
    }

    for (final transaction in transactions) {
      if (transaction.isNotEmpty) {
        _addTransaction(transaction);
      }
    }
  }

  /// Adds a single, pre-processed transaction to the tree.
  void _addTransaction(List<int> transaction) {
    var currentNode = root;
    for (final item in transaction) {
      var childNode = currentNode.findChild(item);
      if (childNode != null) {
        childNode.count++;
        currentNode = childNode;
      } else {
        final newNode = FPNode(item, parent: currentNode);
        currentNode.addChild(newNode);
        currentNode = newNode;
        _updateHeaderTable(item, newNode);
      }
    }
  }

  /// Updates the header table with a new node, linking it to the existing chain.
  void _updateHeaderTable(int item, FPNode newNode) {
    final header = headerTable[item];
    if (header != null) {
      if (header.tail != null) {
        // Append to the end of the node-link list.
        header.tail!.next = newNode;
        headerTable[item] = (
          count: header.count,
          head: header.head,
          tail: newNode,
        );
      } else {
        // This is the first node for this item.
        headerTable[item] = (count: header.count, head: newNode, tail: newNode);
      }
    }
  }

  /// Finds all paths in the tree ending with the given [item].
  /// These paths are called conditional pattern bases.
  ///
  /// Returns a map where keys are the paths (as lists of item IDs) and
  /// values are the frequency counts of those paths.
  Map<List<int>, int> findPaths(int item) {
    final conditionalPatternBases = <List<int>, int>{};
    var startNode = headerTable[item]?.head;

    while (startNode != null) {
      final path = <int>[];
      var currentNode = startNode.parent;
      // Traverse up to the root.
      while (currentNode != null) {
        final item = currentNode.item;
        if (item != null) {
          path.add(item);
        }
        currentNode = currentNode.parent;
      }
      if (path.isNotEmpty) {
        conditionalPatternBases[path.reversed.toList()] = startNode.count;
      }
      startNode = startNode.next;
    }

    return conditionalPatternBases;
  }

  /// Checks if the tree contains only a single path.
  bool isSinglePath() {
    var currentNode = root;
    while (currentNode.children.isNotEmpty) {
      if (currentNode.children.length > 1) {
        return false;
      }
      currentNode = currentNode.children.values.first;
    }
    return true;
  }

  /// Traverses the single path in the tree and returns all nodes in it.
  ///
  /// This should only be called if [isSinglePath] is true.
  List<FPNode> getSinglePathNodes() {
    final path = <FPNode>[];
    var currentNode = root;
    while (currentNode.children.isNotEmpty) {
      currentNode = currentNode.children.values.first;
      path.add(currentNode);
    }
    return path;
  }
}
