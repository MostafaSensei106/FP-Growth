import 'package:fp_growth/fp_growth.dart';
import 'package:fp_growth/src/utils/exporter.dart';
import 'package:test/test.dart';

void main() {
  group('Text Exporter', () {
    final frequentItemsets = {
      ['c']: 5,
      ['a', 'b']: 2,
      ['a']: 3,
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
        confidence: 0.8, // higher confidence
        lift: 1.4,
        leverage: 0.2,
        conviction: double.infinity,
      ),
      AssociationRule<String>(
        antecedent: {'c'},
        consequent: {'d'},
        support: 0.9, // higher support
        confidence: 0.5,
        lift: 2.0, // higher lift
        leverage: 0.3,
        conviction: 1.8,
      ),
    ];

    group('exportFrequentItemsetsToText', () {
      test('exports with default sorting (by support)', () {
        final text = exportFrequentItemsetsToText(frequentItemsets);
        final lines = text.trim().split('\n');

        expect(lines[0], equals('Frequent Itemsets:'));
        expect(lines[1], equals('=' * 50));
        expect(lines[2], contains('{c} => Support: 5'));
        expect(lines[3], contains('{a} => Support: 3'));
        expect(lines[4], contains('{a, b} => Support: 2'));
      });

      test('exports without sorting', () {
        final text =
            exportFrequentItemsetsToText(frequentItemsets, sortBySupport: false);
        final lines = text.trim().split('\n');

        // Order is determined by the original map's iteration order
        expect(lines[2], contains('{c} => Support: 5'));
        expect(lines[3], contains('{a, b} => Support: 2'));
        expect(lines[4], contains('{a} => Support: 3'));
      });
    });

    group('exportRulesToText', () {
      test('exports with default sorting (by confidence)', () {
        final text = exportRulesToText(rules);
        final lines = text.trim().split('\n');

        expect(lines[0], equals('Association Rules:'));
        expect(lines[1], equals('=' * 80));
        expect(lines[2], contains('1. {b} => {a}')); // conf: 0.8
        expect(lines[3], contains('2. {a} => {b}')); // conf: 0.6
        expect(lines[4], contains('3. {c} => {d}')); // conf: 0.5
      });

      test('exports sorting by lift', () {
        final text = exportRulesToText(rules, sortBy: 'lift');
        final lines = text.trim().split('\n');

        expect(lines[2], contains('1. {c} => {d}')); // lift: 2.0
        expect(lines[3], contains('2. {b} => {a}')); // lift: 1.4
        expect(lines[4], contains('3. {a} => {b}')); // lift: 1.2
      });

      test('exports sorting by support', () {
        final text = exportRulesToText(rules, sortBy: 'support');
        final lines = text.trim().split('\n');

        expect(lines[2], contains('1. {c} => {d}')); // sup: 0.9
        expect(lines[3], contains('2. {a} => {b}')); // sup: 0.5
        expect(lines[4], contains('3. {b} => {a}')); // sup: 0.5
      });

      test('formats rule with infinity correctly', () {
        final text = exportRulesToText(rules);
        expect(text, contains('conv: \u221e')); // infinity symbol
      });
    });
  });
}
