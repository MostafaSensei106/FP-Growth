import 'dart:convert';
import 'package:fp_growth/src/utils/io_adapters.dart';
import 'package:test/test.dart';

void main() {
  group('transactionsFromCsv', () {
    Stream<List<int>> stringToStream(String input) {
      return Stream.value(utf8.encode(input));
    }

    test('parses a simple CSV correctly', () async {
      final csv = 'a,b,c\nd,e\nf';
      final stream = stringToStream(csv);
      final result = await transactionsFromCsv(stream).toList();

      expect(result, [
        ['a', 'b', 'c'],
        ['d', 'e'],
        ['f']
      ]);
    });

    test('handles quoted fields with commas', () async {
      final csv = '"a,b",c\nd,"e,f"';
      final stream = stringToStream(csv);
      final result = await transactionsFromCsv(stream).toList();

      expect(result, [
        ['a,b', 'c'],
        ['d', 'e,f']
      ]);
    });

    test('trims whitespace from fields', () async {
      final csv = ' a , b,c \n " d " , "e" ';
      final stream = stringToStream(csv);
      final result = await transactionsFromCsv(stream).toList();

      expect(result, [
        ['a', 'b', 'c'],
        ['d', 'e']
      ]);
    });

    test('ignores empty lines', () async {
      final csv = 'a,b\n\nc,d\n';
      final stream = stringToStream(csv);
      final result = await transactionsFromCsv(stream).toList();

      expect(result, [
        ['a', 'b'],
        ['c', 'd']
      ]);
    });

    test('handles different delimiters', () async {
      final csv = 'a;b;c\nd;e';
      final stream = stringToStream(csv);
      final result =
          await transactionsFromCsv(stream, fieldDelimiter: ';').toList();

      expect(result, [
        ['a', 'b', 'c'],
        ['d', 'e']
      ]);
    });

    test('handles different end-of-line characters', () async {
      final csv = 'a,b\r\nc,d';
      final stream = stringToStream(csv);
      final result = await transactionsFromCsv(stream).toList();

      expect(result, [
        ['a', 'b'],
        ['c', 'd']
      ]);
    });

    test('handles a mix of simple and complex lines', () async {
      final csv = 'a,b,c\n"x,y",z\n1,2,3';
      final stream = stringToStream(csv);
      final result = await transactionsFromCsv(stream).toList();

      expect(result, [
        ['a', 'b', 'c'],
        ['x,y', 'z'],
        ['1', '2', '3']
      ]);
    });

    test('returns an empty list for an empty stream', () async {
      final stream = Stream<List<int>>.empty();
      final result = await transactionsFromCsv(stream).toList();
      expect(result, isEmpty);
    });

    test('handles a stream with only an empty line', () async {
      final stream = stringToStream('\n');
      final result = await transactionsFromCsv(stream).toList();
      expect(result, isEmpty);
    });
  });
}
