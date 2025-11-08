import 'package:fpgrowth_dart/src/utils/io_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('IO Adapters', () {
    test('correctly parses a simple CSV string', () {
      final csv = 'a,b,c\n'
          'd,e\n'
          'f';
      final expected = [
        ['a', 'b', 'c'],
        ['d', 'e'],
        ['f'],
      ];
      final result = transactionsFromCsv(csv);
      expect(result, equals(expected));
    });

    test('handles empty lines', () {
      final csv = 'a,b\n\nd,e';
      final expected = [
        ['a', 'b'],
        [],
        ['d', 'e'],
      ];
      final result = transactionsFromCsv(csv);
      expect(result, equals(expected));
    });

    test('handles CSV with quotes', () {
      final csv = '"a","b"\n"c,d","e"';
      final expected = [
        ['a', 'b'],
        ['c,d', 'e'],
      ];
      final result = transactionsFromCsv(csv);
      expect(result, equals(expected));
    });

    test('handles empty input', () {
      final csv = '';
      final expected = <List<String>>[];
      final result = transactionsFromCsv(csv);
      expect(result, equals(expected));
    });
  });
}
