import 'dart:io';
import 'package:fp_growth/fp_growth.dart';
import 'package:fp_growth/src/utils/logger.dart';

/// A convenience function to run the FP-Growth algorithm directly on a CSV file.
///
/// This function handles file reading, stream creation, and running the mining
/// process. It is not available on the web platform.
///
/// [filePath] is the path to the CSV file.
/// [minSupport] is the minimum support threshold.
/// [parallelism] is the number of isolates to use for parallel processing.
/// [logger] is an optional logger instance.
///
/// Returns a record containing the frequent itemsets and the total transaction count.
Future<(Map<List<String>, int>, int)> runFPGrowthOnCsv(
  String filePath, {
  required double minSupport,
  int parallelism = 1,
  Logger? logger,
}) {
  final fpGrowth = FPGrowth<String>(
    minSupport: minSupport,
    parallelism: parallelism,
    logger: logger,
  );

  // This function provides a new, fresh stream every time it's called.
  Stream<List<String>> streamProvider() =>
      transactionsFromCsv(File(filePath).openRead());

  return fpGrowth.mine(streamProvider);
}
