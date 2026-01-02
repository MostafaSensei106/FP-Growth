import 'dart:io';

import 'package:fp_growth/fp_growth.dart';

/// Extension to add File I/O capabilities to [FPGrowth].
///
/// This allows keeping the core library web-compatible. To use these methods,
/// you must import this file separately:
/// ```dart
/// import 'package:fp_growth/fp_growth_io.dart';
/// ```
extension FPGrowthIO on FPGrowth<String> {
  /// Mines frequent itemsets directly from a CSV file using the current
  /// instance configuration (`minSupport`, `parallelism`, etc.).
  ///
  /// [filePath] is the path to the CSV file.
  /// Throws a [FileSystemException] if the file is not found.
  ///
  /// This method is not available on the web platform.
  Future<(Map<List<String>, int>, int)> mineFromCsv(String filePath) {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw FileSystemException('File not found', filePath);
    }

    // Reuse the generic mine() method with a file stream provider.
    // The provider creates a new stream for each pass of the algorithm.
    return mine(() => transactionsFromCsv(file.openRead()));
  }
}
