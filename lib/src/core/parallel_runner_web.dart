import 'dart:async';

import 'fp_growth.dart';
import 'fp_tree.dart';
import '../utils/logger.dart';
import '../utils/mapper.dart';

/// Web implementation for parallel mining, which falls back to single-threaded
/// execution as Isolates are not available on the web.
Future<Map<List<int>, int>> runParallelMining<T>({
  required FPTree tree,
  required Map<int, int> frequentItems,
  required int absoluteMinSupport,
  required ItemMapper<T> mapper,
  required Logger logger,
  required int parallelism,
}) async {
  logger.warning(
      'Parallelism is not supported on the web. Running single-threaded.');

  // Fallback to the single-threaded mining logic.
  return mineLogic(
    tree,
    [],
    frequentItems,
    absoluteMinSupport,
    mapper,
    logger,
  );
}
