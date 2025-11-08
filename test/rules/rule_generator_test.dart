import 'package:collection/collection.dart';
import 'package:fpgrowth_dart/fpgrowth_dart.dart';
import 'package:test/test.dart';

void main() {
  group('RuleGenerator', () {
    // These tests validate that the output of FPGrowth is correctly consumed.
    late Map<List<String>, int> frequentItemsets;
    const totalTransactions = 5;

    setUp(() {
      frequentItemsets = {
        ['bread']: 4,
        ['milk']: 4,
        ['diaper']: 4,
        ['beer']: 3,
        ['bread', 'milk']: 3,
        ['bread', 'diaper']: 3,
        ['milk', 'diaper']: 3,
        ['diaper', 'beer']: 3,
        ['bread', 'milk', 'diaper']: 2,
      };
    });

    test('generates correct rules with minConfidence', () {
      final generator = RuleGenerator<String>(
        minConfidence: 0.7,
        frequentItemsets: frequentItemsets,
        totalTransactions: totalTransactions,
      );
      final rules = generator.generateRules();

      // Rule: {bread} => {milk}
      // support({bread}) = 4/5 = 0.8
      // support({milk}) = 4/5 = 0.8
      // support({bread, milk}) = 3/5 = 0.6
      // confidence = 0.6 / 0.8 = 0.75
      // lift = 0.75 / 0.8 = 0.9375
      // leverage = 0.6 - (0.8 * 0.8) = -0.04
      // conviction = (1 - 0.8) / (1 - 0.75) = 0.8
      final rule1 = rules.firstWhereOrNull(
        (r) =>
            const SetEquality().equals(r.antecedent, {'bread'}) &&
            const SetEquality().equals(r.consequent, {'milk'}),
      );
      expect(rule1, isNotNull);
      expect(rule1!.confidence, closeTo(0.75, 0.001));
      expect(rule1.support, closeTo(0.6, 0.001));
      expect(rule1.lift, closeTo(0.9375, 0.001));
      expect(rule1.leverage, closeTo(-0.04, 0.001));
      expect(rule1.conviction, closeTo(0.8, 0.001));

      // Rule: {beer} => {diaper}
      // support({beer}) = 3/5 = 0.6
      // support({diaper}) = 4/5 = 0.8
      // support({beer, diaper}) = 3/5 = 0.6
      // confidence = 0.6 / 0.6 = 1.0
      // lift = 1.0 / 0.8 = 1.25
      // leverage = 0.6 - (0.6 * 0.8) = 0.12
      // conviction = infinity
      final rule2 = rules.firstWhereOrNull(
        (r) =>
            const SetEquality().equals(r.antecedent, {'beer'}) &&
            const SetEquality().equals(r.consequent, {'diaper'}),
      );
      expect(rule2, isNotNull);
      expect(rule2!.confidence, closeTo(1.0, 0.001));
      expect(rule2.support, closeTo(0.6, 0.001));
      expect(rule2.lift, closeTo(1.25, 0.001));
      expect(rule2.leverage, closeTo(0.12, 0.001));
      expect(rule2.conviction, double.infinity);

      // Total number of generated rules with >= 0.7 confidence
      expect(rules.length, equals(8));
    });

    test('generates no rules when confidence threshold is too high', () {
      final generator = RuleGenerator<String>(
        minConfidence: 1.01,
        frequentItemsets: frequentItemsets,
        totalTransactions: totalTransactions,
      );
      final rules = generator.generateRules();
      expect(rules, isEmpty);
    });
  });
}
