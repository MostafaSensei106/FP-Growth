import 'dart:async';
import 'dart:isolate';

import 'fp_growth.dart';
import 'fp_tree.dart';
import '../utils/logger.dart';
import '../utils/mapper.dart';

// Note: The functions _mineLogic, _buildConditionalTransactions, _generateSubsets,
// and _filterFrequentItems are defined in the main fp_growth.dart file.
// This file contains only the Isolate-specific implementation.

/// Arguments passed to the _mineInIsolateEntrypoint function.
class _MineTaskArgs<T> {
  final Map<List<int>, int> conditionalPatternBases;
  final Map<int, int> conditionalFrequentItems;
  final List<int> prefix;
  final int absoluteMinSupport;
  final Map<T, int> itemToId;
  final Map<int, T> idToItem;
  final int nextId;
  final LogLevel logLevel;
  final SendPort sendPort;

  _MineTaskArgs({
    required this.conditionalPatternBases,
    required this.conditionalFrequentItems,
    required this.prefix,
    required this.absoluteMinSupport,
    required this.itemToId,
    required this.idToItem,
    required this.nextId,
    required this.logLevel,
    required this.sendPort,
  });
}

/// Entry point for mining in a separate isolate.
/// This function must be a top-level or static function.
Future<void> _mineInIsolateEntrypoint<T>(_MineTaskArgs<T> args) async {
  try {
    // Reconstruct ItemMapper and Logger
    final mapper = ItemMapper<T>.fromMaps(
      args.itemToId,
      args.idToItem,
      args.nextId,
    );
    final logger = Logger(initialLevel: args.logLevel);

    final frequentItemsets = <List<int>, int>{};

    if (args.conditionalFrequentItems.isNotEmpty) {
      // Reconstruct transactions for conditional tree
      final unrolledTransactions = buildConditionalTransactions(
        args.conditionalPatternBases,
        args.conditionalFrequentItems,
      );

      if (unrolledTransactions.isNotEmpty) {
        final conditionalTree = FPTree(
          unrolledTransactions,
          args.conditionalFrequentItems,
        );

        // Single-path optimization
        if (conditionalTree.isSinglePath()) {
          logger.debug(
            '    Single-path optimization applied for prefix: ${args.prefix.map(mapper.getItem).join(', ')}',
          );
          final pathNodes = conditionalTree.getSinglePathNodes();
          final allSubsets = generateSubsets(pathNodes);

          for (final subset in allSubsets) {
            final itemset = subset.map((node) => node.item!).toList();
            final support = subset
                .map((node) => node.count)
                .reduce((a, b) => a < b ? a : b);
            frequentItemsets[List<int>.from(args.prefix)..addAll(itemset)] =
                support;
          }
        } else {
          // Recursively mine the conditional tree
          final minedPatterns = mineLogic(
            conditionalTree,
            args.prefix,
            args.conditionalFrequentItems,
            args.absoluteMinSupport,
            mapper,
            logger,
          );
          frequentItemsets.addAll(minedPatterns);
        }
      }
    }

    args.sendPort.send(frequentItemsets);
  } catch (e, stackTrace) {
    args.sendPort.send({
      'error': e.toString(),
      'stackTrace': stackTrace.toString(),
    });
  }
}

/// Spawns a mining isolate for a subset of items.
Future<Map<List<int>, int>> _spawnMiningIsolate<T>({
  required Map<List<int>, int> conditionalPatternBases,
  required Map<int, int> conditionalFrequentItems,
  required List<int> prefix,
  required int absoluteMinSupport,
  required ItemMapper<T> mapper,
  required Logger logger,
}) async {
  final receivePort = ReceivePort();
  final args = _MineTaskArgs<T>(
    conditionalPatternBases: conditionalPatternBases,
    conditionalFrequentItems: conditionalFrequentItems,
    prefix: prefix,
    absoluteMinSupport: absoluteMinSupport,
    itemToId: mapper.itemToIdMap,
    idToItem: mapper.idToItemMap,
    nextId: mapper.nextId,
    logLevel: logger.currentLevel,
    sendPort: receivePort.sendPort,
  );

  Isolate? isolate;
  try {
    isolate = await Isolate.spawn(_mineInIsolateEntrypoint<T>, args);
    final result = await receivePort.first;

    if (result is Map<String, dynamic> && result.containsKey('error')) {
      logger.error('Isolate error: ${result['error']}');
      throw Exception('Mining isolate failed: ${result['error']}');
    }

    return result as Map<List<int>, int>;
  } finally {
    isolate?.kill(priority: Isolate.immediate);
    receivePort.close();
  }
}

/// Mines frequent itemsets using parallel isolates.
Future<Map<List<int>, int>> runParallelMining<T>({
  required FPTree tree,
  required Map<int, int> frequentItems,
  required int absoluteMinSupport,
  required ItemMapper<T> mapper,
  required Logger logger,
  required int parallelism,
}) async {
  logger.info('Parallel mining using $parallelism isolates...');

  final sortedItems = frequentItems.keys.toList()
    ..sort((a, b) => frequentItems[a]!.compareTo(frequentItems[b]!));

  final futures = <Future<Map<List<int>, int>>>[];
  final mappedItemsets = <List<int>, int>{};

  // The top-level frequent items (size 1) are the base case.
  for (final item in sortedItems) {
    mappedItemsets[[item]] = frequentItems[item]!;
  }

  for (final item in sortedItems) {
    final conditionalPatternBases = tree.findPaths(item);

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
      futures.add(
        _spawnMiningIsolate(
          conditionalPatternBases: conditionalPatternBases,
          conditionalFrequentItems: conditionalFrequentItems,
          prefix: [item],
          absoluteMinSupport: absoluteMinSupport,
          mapper: mapper,
          logger: logger,
        ),
      );
    }
  }

  final results = await Future.wait(futures);

  for (final result in results) {
    mappedItemsets.addAll(result);
  }

  return mappedItemsets;
}
