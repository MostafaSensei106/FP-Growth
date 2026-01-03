import 'package:fp_growth/src/rules/association_rule.dart';
import 'package:test/test.dart';

void main() {
  group('AssociationRule', () {
    final ruleA = AssociationRule<String>(
      antecedent: {'bread'},
      consequent: {'milk'},
      support: 0.6,
      confidence: 0.75,
      lift: 1.25,
      leverage: 0.12,
      conviction: 2.0,
    );

    final ruleB = AssociationRule<String>(
      antecedent: {'milk'},
      consequent: {'bread'},
      support: 0.6,
      confidence: 0.75,
      lift: 1.25,
      leverage: 0.12,
      conviction: 2.0,
    );

    final ruleC = AssociationRule<String>(
      antecedent: {'bread', 'butter'},
      consequent: {'milk'},
      support: 0.4,
      confidence: 0.8,
      lift: 1.33,
      leverage: 0.1,
      conviction: 2.5,
    );

    final ruleSameAsA = AssociationRule<String>(
      antecedent: {'bread'},
      consequent: {'milk'},
      support: 1.0, // different metrics
      confidence: 1.0,
      lift: 1.0,
      leverage: 1.0,
      conviction: 1.0,
    );

    group('Constructor and Properties', () {
      test('initializes properties correctly', () {
        expect(ruleA.antecedent, equals({'bread'}));
        expect(ruleA.consequent, equals({'milk'}));
        expect(ruleA.support, equals(0.6));
        expect(ruleA.confidence, equals(0.75));
        expect(ruleA.lift, equals(1.25));
        expect(ruleA.leverage, equals(0.12));
        expect(ruleA.conviction, equals(2.0));
      });

      test('itemset getter returns the correct union', () {
        expect(ruleA.itemset, equals({'bread', 'milk'}));
        expect(ruleC.itemset, equals({'bread', 'butter', 'milk'}));
      });

      test('throws assertion error for invalid inputs', () {
        // Empty antecedent
        expect(
            () => AssociationRule<String>(
                antecedent: {},
                consequent: {'a'},
                support: 0,
                confidence: 0,
                lift: 0,
                leverage: 0,
                conviction: 0),
            throwsA(isA<AssertionError>()));
        // Empty consequent
        expect(
            () => AssociationRule<String>(
                antecedent: {'a'},
                consequent: {},
                support: 0,
                confidence: 0,
                lift: 0,
                leverage: 0,
                conviction: 0),
            throwsA(isA<AssertionError>()));
        // Invalid support
        expect(
            () => AssociationRule<String>(
                antecedent: {'a'},
                consequent: {'b'},
                support: -0.1,
                confidence: 0,
                lift: 0,
                leverage: 0,
                conviction: 0),
            throwsA(isA<AssertionError>()));
        // Invalid confidence
        expect(
            () => AssociationRule<String>(
                antecedent: {'a'},
                consequent: {'b'},
                support: 0,
                confidence: 1.1,
                lift: 0,
                leverage: 0,
                conviction: 0),
            throwsA(isA<AssertionError>()));
      });
    });

    group('Equality and HashCode', () {
      test('== operator returns true for rules with same sets', () {
        expect(ruleA == ruleSameAsA, isTrue);
      });

      test('== operator returns false for rules with different sets', () {
        expect(ruleA == ruleB, isFalse);
        expect(ruleA == ruleC, isFalse);
      });

      test('hashCode is consistent with equality', () {
        expect(ruleA.hashCode, equals(ruleSameAsA.hashCode));
        expect(ruleA.hashCode, isNot(equals(ruleB.hashCode)));
      });

      test('works correctly in a Set', () {
        final rules = {ruleA, ruleB, ruleC, ruleSameAsA};
        expect(rules.length, equals(3));
        expect(rules, containsAll({ruleA, ruleB, ruleC}));
      });
    });

    group('String Formatting', () {
      test('toString() produces correct format', () {
        expect(ruleA.toString(), equals('{bread} => {milk}'));
        expect(ruleC.toString(), equals('{bread, butter} => {milk}'));
      });

      test('formatWithMetrics() produces correct format', () {
        expect(ruleA.formatWithMetrics(),
            equals('{bread} => {milk} [sup: 0.600, conf: 0.750, lift: 1.25, lev: 0.120, conv: 2.000]'));
      });

      test('formatWithMetrics() handles infinite conviction', () {
        final ruleWithInf = AssociationRule<String>(
            antecedent: {'a'},
            consequent: {'b'},
            support: 0.5,
            confidence: 1.0,
            lift: 1.0,
            leverage: 0.0,
            conviction: double.infinity);
        expect(ruleWithInf.formatWithMetrics(),
            contains('conv: \u221e')); // infinity symbol
      });
    });

    group('Static Comparators', () {
      final r1 = AssociationRule(antecedent: {'a'}, consequent: {'b'}, support: 0.5, confidence: 0.8, lift: 1.2, leverage: 0, conviction: 0);
      final r2 = AssociationRule(antecedent: {'c'}, consequent: {'d'}, support: 0.6, confidence: 0.7, lift: 1.5, leverage: 0, conviction: 0);
      final r3 = AssociationRule(antecedent: {'e'}, consequent: {'f'}, support: 0.5, confidence: 0.8, lift: 1.1, leverage: 0, conviction: 0);
      
      test('compareByConfidence sorts correctly (desc)', () {
        final rules = [r2, r1, r3];
        rules.sort(AssociationRule.compareByConfidence);
        expect(rules, orderedEquals([r1, r3, r2])); // 0.8, 0.8, 0.7
      });

      test('compareByLift sorts correctly (desc)', () {
        final rules = [r1, r3, r2];
        rules.sort(AssociationRule.compareByLift);
        expect(rules, orderedEquals([r2, r1, r3])); // 1.5, 1.2, 1.1
      });

      test('compareBySupport sorts correctly (desc)', () {
        final rules = [r1, r2, r3];
        rules.sort(AssociationRule.compareBySupport);
        expect(rules, orderedEquals([r2, r1, r3])); // 0.6, 0.5, 0.5
      });
    });

    group('Generic Types', () {
      test('works with integer item types', () {
        final intRule = AssociationRule<int>(
          antecedent: {1, 2},
          consequent: {3},
          support: 0.5,
          confidence: 0.5,
          lift: 1.0,
          leverage: 0.0,
          conviction: 1.0,
        );

        expect(intRule.itemset, equals({1, 2, 3}));
        expect(intRule.toString(), equals('{1, 2} => {3}'));
      });

      test('works with custom object item types', () {
        final item1 = _TestItem('A');
        final item2 = _TestItem('B');
        final item3 = _TestItem('C');

        final objRule = AssociationRule<_TestItem>(
          antecedent: {item1},
          consequent: {item2, item3},
          support: 0.5,
          confidence: 0.5,
          lift: 1.0,
          leverage: 0.0,
          conviction: 1.0,
        );

        expect(objRule.itemset, equals({item1, item2, item3}));
        expect(objRule.toString(), equals('{Item A} => {Item B, Item C}'));
      });
    });
  });
}

class _TestItem {
  final String name;
  _TestItem(this.name);

  @override
  String toString() => 'Item $name';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestItem &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}
