/// Represents a node in the FP-Tree.
///
/// Each node stores an item ID, its frequency count, a link to its parent,
/// a map of its children nodes, and a link to the next node with the same item.
class FPNode {
  /// The item ID this node represents. Can be null for the root node.
  final int? item;

  /// The frequency count of the item.
  int count;

  /// A reference to the parent node.
  final FPNode? parent;

  /// A map of child nodes, where the key is the item ID and the value is the node.
  /// Using a standard Map for better performance with small collections.
  final Map<int, FPNode> children;

  /// A link to the next node in the tree with the same item.
  /// This is used to quickly traverse all nodes for a given item.
  FPNode? next;

  /// Creates a new [FPNode] for a given [item].
  ///
  /// The [parent] is optional and can be set later.
  /// [count] defaults to 0.
  FPNode(this.item, {this.parent, this.count = 0}) : children = {};

  /// Finds a child node with the given [item].
  ///
  /// Returns the [FPNode] if found, otherwise returns `null`.
  /// This is an O(1) operation using the Map lookup.
  FPNode? findChild(int item) => children[item];

  /// Adds a child node to this node.
  ///
  /// Assumes the child's item is non-null.
  /// Only adds if the child doesn't already exist.
  void addChild(FPNode child) {
    assert(child.item != null, 'Child node must have a non-null item');
    children.putIfAbsent(child.item!, () => child);
  }

  /// Increments the count of this node.
  void incrementCount([int amount = 1]) {
    count += amount;
  }

  @override
  String toString() =>
      'FPNode(item: $item, count: $count, children: ${children.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FPNode &&
          runtimeType == other.runtimeType &&
          item == other.item &&
          count == other.count;

  @override
  int get hashCode => Object.hash(item, count);
}
