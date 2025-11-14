import 'dart:async';

import '../utils/logger.dart';
import '../utils/mapper.dart';
import 'fp_node.dart';
import 'fp_tree.dart';
import 'parallel_runner.dart' if (dart.library.html) 'parallel_runner_web.dart';

/// Calculates absolute minimum support from relative or absolute value.
int calculateAbsoluteMinSupport(double minSupport, int transactionCount) {
  if (minSupport >= 1.0) {
    return minSupport.toInt();
  }
  return (transactionCount * minSupport).ceil();
}

/// Mines frequent itemsets for a specific item.
Map<List<int>, int> mineForItem<T>(
  FPTree tree,
  int item,
  List<int> prefix,
  Map<int, int> frequency,
  int absoluteMinSupport,
  ItemMapper<T> mapper,
  Logger logger,
) {
  final frequentItemsets = <List<int>, int>{};
  final newPrefix = List<int>.from(prefix)..add(item);
  final support = frequency[item]!;
  frequentItemsets[newPrefix] = support;

  logger
      .debug('  Processing item: ${mapper.getItem(item)} (support: $support)');

  // Find conditional pattern bases
  final conditionalPatternBases = tree.findPaths(item);

  // Calculate conditional frequency
  final conditionalFrequency = <int, int>{};
  for (final entry in conditionalPatternBases.entries) {
    for (final itemInPath in entry.key) {
      conditionalFrequency[itemInPath] =
          (conditionalFrequency[itemInPath] ?? 0) + entry.value;
    }
  }

  final conditionalFrequentItems =
      filterFrequentItems(conditionalFrequency, absoluteMinSupport);

  if (conditionalFrequentItems.isNotEmpty) {
    // Reconstruct transactions for conditional tree
    final unrolledTransactions = buildConditionalTransactions(
      conditionalPatternBases,
      conditionalFrequentItems,
    );

    if (unrolledTransactions.isNotEmpty) {
      final conditionalTree =
          FPTree(unrolledTransactions, conditionalFrequentItems);

      // Single-path optimization
      if (conditionalTree.isSinglePath()) {
        logger.debug(
            '    Single-path optimization applied for prefix: ${newPrefix.map(mapper.getItem).join(', ')}');
        final pathNodes = conditionalTree.getSinglePathNodes();
        final allSubsets = generateSubsets(pathNodes);

        for (final subset in allSubsets) {
          final itemset = subset.map((node) => node.item!).toList();
          final support =
              subset.map((node) => node.count).reduce((a, b) => a < b ? a : b);
          frequentItemsets[List<int>.from(newPrefix)..addAll(itemset)] =
              support;
        }
      } else {
        // Recursively mine the conditional tree
        final minedPatterns = mineLogic(
          conditionalTree,
          newPrefix,
          conditionalFrequentItems,
          absoluteMinSupport,
          mapper,
          logger,
        );
        frequentItemsets.addAll(minedPatterns);
      }
    }
  }

  return frequentItemsets;
}

/// The core recursive mining logic of the FP-Growth algorithm.
Map<List<int>, int> mineLogic<T>(
  FPTree tree,
  List<int> prefix,
  Map<int, int> frequency,
  int absoluteMinSupport,
  ItemMapper<T> mapper,
  Logger logger,
) {
  final frequentItemsets = <List<int>, int>{};

  // Sort items by frequency (ascending) to process from least to most frequent
  final sortedItems = frequency.keys.toList()
    ..sort((a, b) => frequency[a]!.compareTo(frequency[b]!));

  logger.debug(
      'Mining conditional tree for prefix: ${prefix.map(mapper.getItem).join(', ')}');

  for (final item in sortedItems) {
    final itemResult = mineForItem(
      tree,
      item,
      prefix,
      frequency,
      absoluteMinSupport,
      mapper,
      logger,
    );
    frequentItemsets.addAll(itemResult);
  }

  return frequentItemsets;
}

/// Builds conditional transactions from pattern bases.
List<List<int>> buildConditionalTransactions(
  Map<List<int>, int> conditionalPatternBases,
  Map<int, int> conditionalFrequentItems,
) {
  final unrolledTransactions = <List<int>>[];

  for (final entry in conditionalPatternBases.entries) {
    final path = entry.key;
    final count = entry.value;

    final orderedPath = path
        .where((item) => conditionalFrequentItems.containsKey(item))
        .toList()
      ..sort((a, b) =>
          conditionalFrequentItems[b]!.compareTo(conditionalFrequentItems[a]!));

    if (orderedPath.isNotEmpty) {
      // Add the path 'count' times
      for (var i = 0; i < count; i++) {
        unrolledTransactions.add(orderedPath);
      }
    }
  }

  return unrolledTransactions;
}

/// Filters items that meet the minimum support threshold.
Map<int, int> filterFrequentItems(
    Map<int, int> frequency, int absoluteMinSupport) {
  return Map.fromEntries(
    frequency.entries.where((entry) => entry.value >= absoluteMinSupport),
  );
}

/// Generates all non-empty subsets for a given list of nodes.
List<List<FPNode>> generateSubsets(List<FPNode> nodes) {
  final subsets = <List<FPNode>>[];
  final n = nodes.length;

  // Iterate from 1 to 2^n - 1 to get all non-empty subsets
  for (int i = 1; i < (1 << n); i++) {
    final subset = <FPNode>[];
    for (int j = 0; j < n; j++) {
      if ((i >> j) & 1 == 1) {
        subset.add(nodes[j]);
      }
    }
    subsets.add(subset);
  }

  return subsets;
}

/// Calculates the frequency of each item in the transactions.
Map<int, int> _calculateFrequency(List<List<int>> transactions) {
  final frequency = <int, int>{};

  for (final transaction in transactions) {
    for (final item in transaction) {
      frequency[item] = (frequency[item] ?? 0) + 1;
    }
  }

  return frequency;
}

/// Implements the FP-Growth algorithm for mining frequent itemsets.
///
/// This class provides a high-level interface to run the FP-Growth algorithm.
/// It handles transactions, calculates minimum support, and mines the patterns.
/// It uses an internal integer mapping to optimize performance and memory.
class FPGrowth<T> {
  /// The minimum support threshold.
  ///
  /// This value can be provided as a percentage (0.0 to 1.0) or as an
  /// absolute count of transactions.
  final double minSupport;

  /// The number of isolates to use for parallel processing.
  ///
  /// This has no effect on the web platform, where mining will always be
  /// single-threaded.
  ///
  /// A value of 1 means no parallelism (runs on the main isolate).
  /// A value greater than 1 will attempt to distribute the mining tasks
  /// across multiple isolates on native platforms.
  final int parallelism;

  final ItemMapper<T> _mapper = ItemMapper<T>();
  final List<List<int>> _mappedTransactions = [];
  final Logger _logger;

  /// A list of all transactions that have been added.
  List<List<T>> get transactions =>
      _mappedTransactions.map((tx) => _mapper.unmapItemset(tx)).toList();

  /// The total number of transactions.
  int get transactionCount => _mappedTransactions.length;

  /// Creates an instance of the FP-Growth algorithm runner.
  ///
  /// [minSupport] is the minimum support threshold. If the value is less than 1.0,
  /// it's treated as a percentage of the total transactions. Otherwise, it's
  /// treated as an absolute count.
  /// [logger] an optional logger instance. If not provided, a default logger with info level is used.
  /// [parallelism] the number of isolates to use for parallel processing. Defaults to 1.
  /// This is ignored on the web platform.
  FPGrowth({
    required this.minSupport,
    Logger? logger,
    this.parallelism = 1,
  }) : _logger = logger ?? Logger() {
    if (minSupport <= 0) {
      throw ArgumentError.value(
          minSupport, 'minSupport', 'Must be greater than 0');
    }
    if (parallelism < 1) {
      throw ArgumentError.value(
          parallelism, 'parallelism', 'Must be at least 1');
    }
  }

  /// Adds a single transaction to the miner.
  void addTransaction(List<T> transaction) {
    if (transaction.isNotEmpty) {
      _mappedTransactions.add(_mapper.mapTransaction(transaction));
    }
  }

  /// Adds a list of transactions to the miner.
  void addTransactions(List<List<T>> transactions) {
    // This is intentionally not logged to avoid verbose output when streaming.
    // The caller is responsible for entry/exit logging if needed.
    for (final transaction in transactions) {
      addTransaction(transaction);
    }
  }

  /// Calculates the absolute minimum support count from the relative [minSupport].
  int get _absoluteMinSupport =>
      calculateAbsoluteMinSupport(minSupport, _mappedTransactions.length);

  /// Mines the frequent itemsets from the transactions.
  ///
  /// Returns a map of frequent itemsets to their support counts.
  Future<Map<List<T>, int>> mineFrequentItemsets() async {
    if (_mappedTransactions.isEmpty) {
      _logger.warning('No transactions to mine');
      return {};
    }

    _logger
        .info('Starting frequent itemset mining with minSupport: $minSupport');

    _logger.debug('Calculating initial item frequencies...');
    final frequency = _calculateFrequency(_mappedTransactions);

    _logger.debug('Filtering frequent items...');
    final frequentItems = filterFrequentItems(frequency, _absoluteMinSupport);

    if (frequentItems.isEmpty) {
      _logger.warning('No frequent items found with minSupport: $minSupport');
      return {};
    }

    _logger.debug('Found ${frequentItems.length} frequent items.');

    _logger.debug('Preparing transactions for FP-Tree construction...');
    final orderedTransactions = _prepareOrderedTransactions(frequentItems);

    _logger.debug('Building FP-Tree...');
    final tree = FPTree(orderedTransactions, frequentItems);
    _logger.debug('FP-Tree built.');

    _logger.info('Starting recursive mining...');
    final Map<List<int>, int> mappedItemsets;

    if (parallelism == 1) {
      mappedItemsets = _mineSingleThreaded(tree, frequentItems);
    } else {
      mappedItemsets = await runParallelMining(
        tree: tree,
        frequentItems: frequentItems,
        absoluteMinSupport: _absoluteMinSupport,
        mapper: _mapper,
        logger: _logger,
        parallelism: parallelism,
      );
    }

    _logger.info(
        'Finished mining. Found ${mappedItemsets.length} frequent itemsets.');

    // Unmap the results before returning
    return mappedItemsets.map(
      (itemset, support) => MapEntry(_mapper.unmapItemset(itemset), support),
    );
  }

  /// Prepares ordered transactions for FP-Tree construction.
  List<List<int>> _prepareOrderedTransactions(Map<int, int> frequentItems) {
    return _mappedTransactions
        .map((transaction) {
          final orderedItems = transaction
              .where((item) => frequentItems.containsKey(item))
              .toList()
            ..sort((a, b) => frequentItems[b]!.compareTo(frequentItems[a]!));
          return orderedItems;
        })
        .where((t) => t.isNotEmpty)
        .toList();
  }

  /// Mines frequent itemsets using a single thread.
  Map<List<int>, int> _mineSingleThreaded(
      FPTree tree, Map<int, int> frequentItems) {
    return mineLogic(
      tree,
      [],
      frequentItems,
      _absoluteMinSupport,
      _mapper,
      _logger,
    );
  }

  /// Clears all transactions from the miner.
  void clear() {
    _mappedTransactions.clear();
    _logger.debug('Cleared all transactions');
  }
}
