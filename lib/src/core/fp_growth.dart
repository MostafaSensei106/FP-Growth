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

  logger.debug(
    '  Processing item: ${mapper.getItem(item)} (support: $support)',
  );

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

  final conditionalFrequentItems = filterFrequentItems(
    conditionalFrequency,
    absoluteMinSupport,
  );

  if (conditionalFrequentItems.isNotEmpty) {
    // Reconstruct transactions for conditional tree
    final weightedTransactions = buildConditionalTransactions(
      conditionalPatternBases,
      conditionalFrequentItems,
    );

    if (weightedTransactions.isNotEmpty) {
      final conditionalTree = FPTree(conditionalFrequentItems)
        ..addWeightedTransactions(weightedTransactions);

      // Single-path optimization
      if (conditionalTree.isSinglePath()) {
        logger.debug(
          '    Single-path optimization applied for prefix: ${newPrefix.map(mapper.getItem).join(', ')}',
        );
        final pathNodes = conditionalTree.getSinglePathNodes();
        final allSubsets = generateSubsets(pathNodes);

        for (final subset in allSubsets) {
          final itemset = subset.map((node) => node.item!).toList();
          final support = subset
              .map((node) => node.count)
              .reduce((a, b) => a < b ? a : b);
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

  final entries = frequency.entries.toList()
    ..sort((a, b) {
      final compare = a.value.compareTo(b.value);
      if (compare == 0) {
        return a.key.compareTo(b.key);
      }
      return compare;
    });

  final sortedItems = entries.map((e) => e.key).toList();

  logger.debug(
    'Mining conditional tree for prefix: ${prefix.map(mapper.getItem).join(', ')}',
  );

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

/// Builds conditional transactions from pattern bases without unrolling them.
Map<List<int>, int> buildConditionalTransactions(
  Map<List<int>, int> conditionalPatternBases,
  Map<int, int> conditionalFrequentItems,
) {
  final weightedTransactions = <List<int>, int>{};

  for (final entry in conditionalPatternBases.entries) {
    final path = entry.key;
    final count = entry.value;

    final orderedPath =
        path
            .where((item) => conditionalFrequentItems.containsKey(item))
            .toList()
          ..sort((a, b) {
            final compare = conditionalFrequentItems[b]!.compareTo(
              conditionalFrequentItems[a]!,
            );
            if (compare == 0) {
              // Stable sort based on item ID
              return a.compareTo(b);
            }
            return compare;
          });

    if (orderedPath.isNotEmpty) {
      weightedTransactions[orderedPath] = count;
    }
  }

  return weightedTransactions;
}

/// Filters items that meet the minimum support threshold.
Map<int, int> filterFrequentItems(
  Map<int, int> frequency,
  int absoluteMinSupport,
) {
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
  final Logger _logger;

  /// Creates an instance of the FP-Growth algorithm runner.
  ///
  /// [minSupport] is the minimum support threshold. If the value is less than 1.0,
  /// it's treated as a percentage of the total transactions. Otherwise, it's
  /// treated as an absolute count.
  /// [logger] an optional logger instance. If not provided, a default logger with info level is used.
  /// [parallelism] the number of isolates to use for parallel processing. Defaults to 1.
  /// This is ignored on the web platform.
  FPGrowth({required this.minSupport, Logger? logger, this.parallelism = 1})
    : _logger = logger ?? Logger() {
    if (minSupport <= 0) {
      throw ArgumentError.value(
        minSupport,
        'minSupport',
        'Must be greater than 0',
      );
    }
    if (parallelism < 1) {
      throw ArgumentError.value(
        parallelism,
        'parallelism',
        'Must be at least 1',
      );
    }
  }

  /// Mines the frequent itemsets from the given transaction stream.
  ///
  /// [streamProvider] is a function that returns a new stream of transactions
  /// for each pass of the algorithm. This is crucial for handling large
  /// datasets from sources like files, as it allows the data to be processed
  //  without being fully loaded into memory.
  ///
  /// Returns a record containing a map of frequent itemsets to their support
  /// counts, and the total number of non-empty transactions processed.
  Future<(Map<List<T>, int>, int)> mine(
    Stream<List<T>> Function() streamProvider,
  ) async {
    _logger.info(
      'Starting frequent itemset mining with minSupport: $minSupport',
    );

    // Pass 1: Calculate frequencies and count transactions
    _logger.debug('Pass 1: Calculating initial item frequencies...');
    final frequency = <int, int>{};
    int transactionCount = 0;

    await for (final transaction in streamProvider()) {
      if (transaction.isNotEmpty) {
        transactionCount++;
        for (final item in transaction) {
          final id = _mapper.getId(item);
          frequency[id] = (frequency[id] ?? 0) + 1;
        }
      }
    }

    if (transactionCount == 0) {
      _logger.warning('No non-empty transactions to mine');
      return (<List<T>, int>{}, 0);
    }
    _logger.debug('Found $transactionCount non-empty transactions.');

    final absoluteMinSupport = calculateAbsoluteMinSupport(
      minSupport,
      transactionCount,
    );

    _logger.debug('Filtering frequent items...');
    final frequentItems = filterFrequentItems(frequency, absoluteMinSupport);

    if (frequentItems.isEmpty) {
      _logger.warning('No frequent items found with minSupport: $minSupport');
      return (<List<T>, int>{}, transactionCount);
    }

    _logger.debug('Found ${frequentItems.length} frequent items.');

    _logger.debug('Pass 2: Building FP-Tree...');
    // Pass 2: Build the FP-Tree
    final tree = FPTree(frequentItems);
    await for (final transaction in streamProvider()) {
      final orderedItems = _prepareOrderedTransaction(
        transaction.map((t) => _mapper.getId(t)).toList(),
        frequentItems,
      );
      if (orderedItems.isNotEmpty) {
        tree.addTransaction(orderedItems, 1);
      }
    }
    _logger.debug('FP-Tree built.');

    _logger.info('Starting recursive mining...');
    final Map<List<int>, int> mappedItemsets;

    if (parallelism == 1) {
      mappedItemsets = _mineSingleThreaded(
        tree,
        frequentItems,
        absoluteMinSupport,
      );
    } else {
      mappedItemsets = await runParallelMining(
        tree: tree,
        frequentItems: frequentItems,
        absoluteMinSupport: absoluteMinSupport,
        mapper: _mapper,
        logger: _logger,
        parallelism: parallelism,
      );
    }

    _logger.info(
      'Finished mining. Found ${mappedItemsets.length} frequent itemsets.',
    );

    // Unmap the results before returning
    final unmappedItemsets = mappedItemsets.map(
      (itemset, support) => MapEntry(_mapper.unmapItemset(itemset), support),
    );

    return (unmappedItemsets, transactionCount);
  }

  /// A convenience method to mine frequent itemsets from an in-memory list.
  ///
  /// This is simpler to use than the standard [mine] method if your dataset
  /// is already loaded into a list.
  Future<(Map<List<T>, int>, int)> mineFromList(List<List<T>> transactions) {
    return mine(() => Stream.fromIterable(transactions));
  }

  /// Prepares a single ordered transaction for FP-Tree construction.
  List<int> _prepareOrderedTransaction(
    List<int> transaction,
    Map<int, int> frequentItems,
  ) {
    final orderedItems =
        transaction.where((item) => frequentItems.containsKey(item)).toList()
          ..sort((a, b) {
            final compare = frequentItems[b]!.compareTo(frequentItems[a]!);
            if (compare == 0) {
              return a.compareTo(b);
            }
            return compare;
          });
    return orderedItems;
  }

  /// Mines frequent itemsets using a single thread.
  Map<List<int>, int> _mineSingleThreaded(
    FPTree tree,
    Map<int, int> frequentItems,
    int absoluteMinSupport,
  ) {
    return mineLogic(
      tree,
      [],
      frequentItems,
      absoluteMinSupport,
      _mapper,
      _logger,
    );
  }
}
