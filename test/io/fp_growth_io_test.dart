import 'dart:io';
import 'package:collection/collection.dart';
import 'package:fp_growth/fp_growth_io.dart';
import 'package:test/test.dart';

// Helper to compare maps where keys are lists of items (treated as sets).
bool areItemsetMapsEqual<T>(Map<List<T>, int> map1, Map<List<T>, int> map2) {
  if (map1.length != map2.length) return false;
  final setMap1 = map1.map((key, value) => MapEntry(key.toSet(), value));
  final setMap2 = map2.map((key, value) => MapEntry(key.toSet(), value));

  for (final entry in setMap1.entries) {
    final keySet = entry.key;
    final value = entry.value;

    final matchingEntry = setMap2.entries.firstWhereOrNull(
      (e) => SetEquality().equals(e.key, keySet),
    );

    if (matchingEntry == null || matchingEntry.value != value) {
      return false;
    }
  }
  return true;
}

void main() {
  group('FPGrowthIO', () {
    late Directory tempDir;
    late File csvFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fp_growth_test_');
      csvFile = File('${tempDir.path}/transactions.csv');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'mineFromCsv correctly mines frequent itemsets from a CSV file',
      () async {
        final csvContent = ['a,b,c', 'a,b', 'b,c', 'a,c', 'a,b,c,d'].join('\n');
        await csvFile.writeAsString(csvContent);

        final fpGrowth = FPGrowth<String>(minSupport: 3);
        final (frequentItemsets, transactionCount) = await fpGrowth.mineFromCsv(
          csvFile.path,
        );

        final expected = {
          ['a']: 4,
          ['b']: 4,
          ['c']: 4,
          ['a', 'b']: 3,
          ['a', 'c']: 3,
          ['b', 'c']: 3,
          ['a', 'b', 'c']:
              2, // This has support 2, so it won't be in the output
        };

        // With minSupport 3, {a,b,c} should not be included.
        final expectedFiltered = Map<List<String>, int>.from(expected)
          ..removeWhere((key, value) => value < 3);

        expect(transactionCount, equals(5));
        expect(
          areItemsetMapsEqual(frequentItemsets, expectedFiltered),
          isTrue,
          reason: "Expected: $expectedFiltered, but got: $frequentItemsets",
        );
      },
    );

    test(
      'mineFromCsv throws FileSystemException if file does not exist',
      () async {
        final fpGrowth = FPGrowth<String>(minSupport: 2);
        final nonExistentFilePath = '${tempDir.path}/non_existent.csv';

        expect(
          () => fpGrowth.mineFromCsv(nonExistentFilePath),
          throwsA(isA<FileSystemException>()),
        );
      },
    );

    test('mineFromCsv handles CSV with quotes and extra spacing', () async {
      final csvContent = '"a", " b ",c\n"a","b"\n';
      await csvFile.writeAsString(csvContent);

      final fpGrowth = FPGrowth<String>(minSupport: 2);
      final (frequentItemsets, _) = await fpGrowth.mineFromCsv(csvFile.path);

      final expected = {
        ['a']: 2,
        ['b']: 2,
        ['a', 'b']: 2,
      };

      expect(areItemsetMapsEqual(frequentItemsets, expected), isTrue);
    });

    test('mineFromCsv handles empty lines in file', () async {
      final csvContent = 'a,b\n\na,b,c\n';
      await csvFile.writeAsString(csvContent);
      final fpGrowth = FPGrowth<String>(minSupport: 2);
      final (frequentItemsets, transactionCount) = await fpGrowth.mineFromCsv(
        csvFile.path,
      );

      final expected = {
        ['a']: 2,
        ['b']: 2,
        ['a', 'b']: 2,
      };

      expect(transactionCount, equals(2));
      expect(areItemsetMapsEqual(frequentItemsets, expected), isTrue);
    });
  });
}
