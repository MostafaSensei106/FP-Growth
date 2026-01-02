import 'dart:async';
import 'dart:convert';

/// Parses a CSV byte stream efficiently.
///
/// This implementation uses a **Hybrid Strategy**:
/// 1. **Fast Path**: If a line contains no quotes, it uses Dart's native `split`, which is extremely fast.
/// 2. **Robust Path**: If quotes are detected, it switches to a manual character parser for that line to handle escaped commas correctly.
///
/// This ensures maximum performance for standard datasets while maintaining correctness for complex ones,
/// without requiring user configuration.
Stream<List<String>> transactionsFromCsv(
  Stream<List<int>> csvStream, {
  String fieldDelimiter = ',',
  String eol = '\n',
}) {
  return csvStream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .map((line) {
        if (line.isEmpty) return const <String>[];

        // Check for quotes once.
        // If no quotes, use the native split.
        if (!line.contains('"')) {
          return line.split(fieldDelimiter).map((e) => e.trim()).toList();
        }

        return _parseComplexCsvLine(line, fieldDelimiter);
      })
      .where((row) => row.isNotEmpty);
}

/// A manual parser that handles quoted fields correctly.
/// Used only when necessary to avoid the overhead of generic libraries.
List<String> _parseComplexCsvLine(String line, String delimiter) {
  final result = <String>[];
  final buffer = StringBuffer();
  bool inQuote = false;

  for (int i = 0; i < line.length; i++) {
    final char = line[i];

    if (char == '"') {
      inQuote = !inQuote;
    } else if (char == delimiter && !inQuote) {
      result.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  result.add(buffer.toString().trim());
  return result;
}
