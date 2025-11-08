import 'package:csv/csv.dart';

/// Parses a CSV string into a list of transactions.
///
/// Each row in the CSV is treated as a transaction, and each cell in the row
/// is an item in the transaction.
///
/// Example:
/// a,b,c
/// a,d
///
/// becomes:
/// [
///   ['a', 'b', 'c'],
///   ['a', 'd']
/// ]
List<List<String>> transactionsFromCsv(String csvContent) {
  final converter = CsvToListConverter(
    eol: '\n',
    shouldParseNumbers: false, // Treat all values as strings
  );
  final List<List<dynamic>> csvRows = converter.convert(csvContent);

  // Post-process to handle empty lines correctly
  return csvRows.map((row) {
    if (row.length == 1 && row.first == '') {
      return <String>[];
    }
    return row.map((item) => item.toString()).toList();
  }).toList();
}
