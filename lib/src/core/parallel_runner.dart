import 'dart:async';
import 'dart:isolate';

import 'fp_growth.dart';
import 'fp_tree.dart';
import '../utils/logger.dart';
import '../utils/mapper.dart';

// --- Isolate Communication Messages ---

/// Base class for messages sent to the worker isolate.
sealed class _WorkerMessage<T> {}

/// Message to initialize the worker with common data.
class _InitMessage<T> extends _WorkerMessage<T> {
  final SendPort mainSendPort;
  final Map<T, int> itemToId;
  final Map<int, T> idToItem;
  final int nextId;
  final LogLevel logLevel;

  _InitMessage({
    required this.mainSendPort,
    required this.itemToId,
    required this.idToItem,
    required this.nextId,
    required this.logLevel,
  });
}

/// Message representing a single mining task.
class _MineTaskMessage<T> extends _WorkerMessage<T> {
  final int taskId;
  final Map<List<int>, int> conditionalPatternBases;
  final Map<int, int> conditionalFrequentItems;
  final List<int> prefix;
  final int absoluteMinSupport;

  _MineTaskMessage({
    required this.taskId,
    required this.conditionalPatternBases,
    required this.conditionalFrequentItems,
    required this.prefix,
    required this.absoluteMinSupport,
  });
}

/// Message to tell the worker to terminate.
class _ShutdownMessage<T> extends _WorkerMessage<T> {}

/// Base class for messages sent from the worker back to the main isolate.
sealed class _MainMessage {}

/// Message indicating the worker is ready to receive tasks.
class _ReadyMessage extends _MainMessage {}

/// Message containing the result of a completed mining task.
class _ResultMessage extends _MainMessage {
  final int taskId;
  final Map<List<int>, int> frequentItemsets;

  _ResultMessage(this.taskId, this.frequentItemsets);
}

/// Message containing an error that occurred in the worker.
class _ErrorMessage extends _MainMessage {
  final String error;
  final String stackTrace;

  _ErrorMessage(this.error, this.stackTrace);
}

/// Entry point for the worker isolate.
Future<void> _workerEntrypoint<T>(SendPort mainSendPort) async {
  final workerReceivePort = ReceivePort();
  ItemMapper<T>? mapper;
  Logger? logger;

  // Send the worker's port to the main isolate so it can send messages.
  mainSendPort.send(workerReceivePort.sendPort);

  await for (final message in workerReceivePort) {
    try {
      switch (message) {
        case _InitMessage<T>():
          mapper = ItemMapper<T>.fromMaps(
            message.itemToId,
            message.idToItem,
            message.nextId,
          );
          logger = Logger(initialLevel: message.logLevel);
          mainSendPort.send(_ReadyMessage());

        case _MineTaskMessage<T>():
          if (mapper == null || logger == null) {
            throw StateError('Worker not initialized.');
          }
          final frequentItemsets = _performMining(message, mapper, logger);
          mainSendPort.send(_ResultMessage(message.taskId, frequentItemsets));

        case _ShutdownMessage<T>():
          workerReceivePort.close();
          return;

        default:
          throw ArgumentError('Unknown message type: ${message.runtimeType}');
      }
    } catch (e, s) {
      mainSendPort.send(_ErrorMessage(e.toString(), s.toString()));
    }
  }
}

/// The actual mining logic performed within the isolate.
Map<List<int>, int> _performMining<T>(
  _MineTaskMessage<T> task,
  ItemMapper<T> mapper,
  Logger logger,
) {
  final frequentItemsets = <List<int>, int>{};

  // The new prefix (base item + its own item) is a frequent itemset itself.
  final newPrefix = task.prefix;
  task.conditionalFrequentItems.values.fold(
    0,
    (sum, val) => sum + val,
  ); // Simplified support calculation
  // This support is for the conditional items, not the prefix itself.
  // The prefix support is already known. We just need to mine sub-trees.

  if (task.conditionalFrequentItems.isNotEmpty) {
    final weightedTransactions = buildConditionalTransactions(
      task.conditionalPatternBases,
      task.conditionalFrequentItems,
    );

    if (weightedTransactions.isNotEmpty) {
      final conditionalTree = FPTree(task.conditionalFrequentItems)
        ..addWeightedTransactions(weightedTransactions);

      if (conditionalTree.isSinglePath()) {
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
        final minedPatterns = mineLogic(
          conditionalTree,
          newPrefix,
          task.conditionalFrequentItems,
          task.absoluteMinSupport,
          mapper,
          logger,
        );
        frequentItemsets.addAll(minedPatterns);
      }
    }
  }
  return frequentItemsets;
}

/// Mines frequent itemsets using a parallel pool of isolates.
Future<Map<List<int>, int>> runParallelMining<T>({
  required FPTree tree,
  required Map<int, int> frequentItems,
  required int absoluteMinSupport,
  required ItemMapper<T> mapper,
  required Logger logger,
  required int parallelism,
}) async {
  logger.info('Parallel mining using an Isolate pool of size $parallelism...');

  final mainReceivePort = ReceivePort();
  final completer = Completer<Map<List<int>, int>>();
  final results = <List<int>, int>{};
  final workerPorts = <SendPort>[];
  var readyWorkers = 0;
  var tasksSent = 0;
  var tasksCompleted = 0;

  // Create task queue
  final tasks = <_MineTaskMessage<T>>[];
  final sortedItems = frequentItems.keys.toList()
    ..sort((a, b) => frequentItems[a]!.compareTo(frequentItems[b]!));

  // The top-level frequent items (size 1) are the base case.
  for (final item in sortedItems) {
    results[[item]] = frequentItems[item]!;

    final conditionalPatternBases = tree.findPaths(item);
    if (conditionalPatternBases.isEmpty) continue;

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
      tasks.add(
        _MineTaskMessage<T>(
          taskId: tasks.length,
          prefix: [item],
          conditionalPatternBases: conditionalPatternBases,
          conditionalFrequentItems: conditionalFrequentItems,
          absoluteMinSupport: absoluteMinSupport,
        ),
      );
    }
  }

  if (tasks.isEmpty) {
    return results; // No further mining needed
  }

  // --- Isolate Pool Management ---
  final isolates = <Isolate>[];

  void shutdownPool() {
    for (final port in workerPorts) {
      port.send(_ShutdownMessage<T>());
    }
    for (final isolate in isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
    mainReceivePort.close();
  }

  mainReceivePort.listen((message) {
    switch (message) {
      case SendPort():
        // Worker sent its port. Initialize it.
        workerPorts.add(message);
        message.send(
          _InitMessage<T>(
            mainSendPort: mainReceivePort.sendPort,
            itemToId: mapper.itemToIdMap,
            idToItem: mapper.idToItemMap,
            nextId: mapper.nextId,
            logLevel: logger.currentLevel,
          ),
        );

      case _ReadyMessage():
        readyWorkers++;
        if (readyWorkers == parallelism) {
          // All workers are ready, start sending tasks.
          for (int i = 0; i < parallelism && i < tasks.length; i++) {
            workerPorts[i].send(tasks[i]);
            tasksSent++;
          }
        }

      case _ResultMessage():
        results.addAll(message.frequentItemsets);
        tasksCompleted++;
        if (tasksCompleted == tasks.length) {
          shutdownPool();
          if (!completer.isCompleted) {
            completer.complete(results);
          }
        } else if (tasksSent < tasks.length) {
          // Send next task to the worker that just finished.
          // The sender of the result is not easily known, so we just round-robin.
          final workerIndex = tasksCompleted % parallelism;
          workerPorts[workerIndex].send(tasks[tasksSent]);
          tasksSent++;
        }

      case _ErrorMessage():
        logger.error('Isolate error: ${message.error}');
        shutdownPool();
        if (!completer.isCompleted) {
          completer.completeError(
            Exception('Mining isolate failed: ${message.error}'),
            StackTrace.fromString(message.stackTrace),
          );
        }
    }
  });

  try {
    for (var i = 0; i < parallelism; i++) {
      isolates.add(
        await Isolate.spawn(_workerEntrypoint<T>, mainReceivePort.sendPort),
      );
    }
  } catch (e, s) {
    shutdownPool();
    completer.completeError(e, s);
  }

  return completer.future;
}
