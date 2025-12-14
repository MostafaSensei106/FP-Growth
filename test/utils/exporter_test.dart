import 'package:fp_growth/fp_growth.dart';
import 'package:fp_growth/src/utils/exporter.dart';
import 'package:test/test.dart';
import 'dart:convert'; // For jsonDecode

void main() {
  group('Exporter', () {
    final frequentItemsets = {
      ['a']: 3,
      ['b']: 4,
      ['a', 'b']: 2,
    };

    final rules = <AssociationRule<String>>[
      AssociationRule<String>(
        antecedent: {'a'},
        consequent: {'b'},
        support: 0.5,
        confidence: 0.6,
        lift: 1.2,
        leverage: 0.1,
        conviction: 1.5,
      ),
      AssociationRule<String>(
        antecedent: {'b'},
        consequent: {'a'},
        support: 0.5,
        confidence: 0.7,
        lift: 1.4,
        leverage: 0.2,
        conviction: double.infinity, // Test infinity handling
      ),
    ];

    test('exports frequent itemsets to JSON correctly', () {
      final json = exportFrequentItemsetsToJson(frequentItemsets);
      final decoded = jsonDecode(json) as List;

      expect(decoded.length, equals(3));
      expect(decoded[0]['itemset'], equals(['a']));
      expect(decoded[0]['support'], equals(3));
      expect(decoded[2]['itemset'], equals(['a', 'b']));
      expect(decoded[2]['support'], equals(2));
    });

    test('exports frequent itemsets to CSV correctly', () {
      final csv = exportFrequentItemsetsToCsv(frequentItemsets);
      final lines = csv.trim().split('\n');

      expect(lines.length, equals(4)); // Header + 3 itemsets
      expect(lines[0], equals('Itemset,Support'));
      expect(lines[1], equals('"a",3'));
      expect(lines[3], equals('"a;b",2'));
    });

    test('exports association rules to JSON correctly', () {
      final json = exportRulesToJson(rules);
      final decoded = jsonDecode(json) as List;

      expect(decoded.length, equals(2));
      expect(decoded[0]['antecedent'], equals(['a']));
      expect(decoded[0]['consequent'], equals(['b']));
      expect(decoded[0]['support'], equals(0.5));
      expect(decoded[0]['confidence'], equals(0.6));
      expect(decoded[0]['lift'], equals(1.2));
      expect(decoded[0]['leverage'], equals(0.1));
      expect(decoded[0]['conviction'], equals(1.5));

      expect(decoded[1]['antecedent'], equals(['b']));
      expect(decoded[1]['consequent'], equals(['a']));
      expect(decoded[1]['support'], equals(0.5));
      expect(decoded[1]['confidence'], equals(0.7));
      expect(decoded[1]['lift'], equals(1.4));
      expect(decoded[1]['leverage'], equals(0.2));
      expect(decoded[1]['conviction'], isNull); // Infinity should be null
    });

    test('exports association rules to CSV correctly', () {
      final csv = exportRulesToCsv(rules);
      final lines = csv.trim().split('\n');

      expect(lines.length, equals(3)); // Header + 2 rules
      expect(
        lines[0],
        equals(
          'Antecedent,Consequent,Support,Confidence,Lift,Leverage,Conviction',
        ),
      );
      expect(lines[1], equals('"a","b",0.5,0.6,1.2,0.1,1.5'));
      expect(
        lines[2],
        equals('"b","a",0.5,0.7,1.4,0.2,INF'),
      ); // Infinity should be "INF" in CSV
    });
  });
}
