/// A utility class to map items of a generic type `T` to integer IDs and back.
///
/// This is used to optimize memory usage and performance by using integers
/// for internal computations instead of potentially large objects or strings.
class ItemMapper<T> {
  final Map<T, int> _itemToId;
  final Map<int, T> _idToItem;
  int _nextId;

  /// Creates a new empty [ItemMapper].
  ItemMapper()
      : _itemToId = {},
        _idToItem = {},
        _nextId = 0;

  /// Creates an [ItemMapper] from existing maps.
  ///
  /// This is useful for reconstructing the mapper in isolates.
  ItemMapper.fromMaps(
    Map<T, int> itemToId,
    Map<int, T> idToItem,
    int nextId,
  )   : _itemToId = Map.from(itemToId),
        _idToItem = Map.from(idToItem),
        _nextId = nextId;

  /// Gets the integer ID for a given [item].
  ///
  /// If the item has not been seen before, a new ID is created and assigned.
  int getId(T item) {
    return _itemToId.putIfAbsent(item, () {
      final id = _nextId++;
      _idToItem[id] = item;
      return id;
    });
  }

  /// Gets the original item for a given integer [id].
  ///
  /// Throws a [StateError] if the ID is not found.
  T getItem(int id) {
    final item = _idToItem[id];
    if (item == null) {
      throw StateError('No item found for ID: $id');
    }
    return item;
  }

  /// Converts a transaction of items into a list of integer IDs.
  List<int> mapTransaction(List<T> transaction) {
    return transaction.map(getId).toList();
  }

  /// Converts an itemset of integer IDs back to a list of original items.
  List<T> unmapItemset(List<int> itemset) {
    return itemset.map(getItem).toList();
  }

  /// Returns the number of unique items mapped.
  int get itemCount => _itemToId.length;

  /// Returns a copy of the item-to-ID map.
  Map<T, int> get itemToIdMap => Map.from(_itemToId);

  /// Returns a copy of the ID-to-item map.
  Map<int, T> get idToItemMap => Map.from(_idToItem);

  /// Returns the next ID that will be assigned.
  int get nextId => _nextId;

  /// Checks if an item has been mapped.
  bool hasItem(T item) => _itemToId.containsKey(item);

  /// Checks if an ID exists.
  bool hasId(int id) => _idToItem.containsKey(id);

  /// Clears all mappings.
  void clear() {
    _itemToId.clear();
    _idToItem.clear();
    _nextId = 0;
  }
}
