import 'package:collection/collection.dart';
import 'package:fp_growth/fp_growth.dart';
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
        ['bread', 'milk', 'diaper']:
            2, // Support is 2, but needed for rule calculation
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
      // {bread} -> {milk} (0.75)
      // {milk} -> {bread} (0.75)
      // {bread} -> {diaper} (0.75)
      // {diaper} -> {bread} (0.75)
      // {milk} -> {diaper} (0.75)
      // {diaper} -> {milk} (0.75)
      // {beer} -> {diaper} (1.0)
      // {bread, milk} -> {diaper} (2/3 = 0.66, too low)
      // {bread, diaper} -> {milk} (2/3 = 0.66, too low)
      // {milk, diaper} -> {bread} (2/3 = 0.66, too low)
      // Let's re-calculate.
      // Support values:
      // s(b,m,d) = 2
      // s(b,m) = 3, s(d) = 4 -> conf(b,m -> d) = 2/3 = 0.66
      // s(b,d) = 3, s(m) = 4 -> conf(b,d -> m) = 2/3 = 0.66
      // s(m,d) = 3, s(b) = 4 -> conf(m,d -> b) = 2/3 = 0.66
      // s(b) = 4, s(m,d) = 3 -> conf(b -> m,d) = 2/4 = 0.5
      // s(m) = 4, s(b,d) = 3 -> conf(m -> b,d) = 2/4 = 0.5
      // s(d) = 4, s(b,m) = 3 -> conf(d -> b,m) = 2/4 = 0.5
      // So, only rules from 2-itemsets are generated.
      // {diaper} -> {beer} has conf = 3/4 = 0.75
      final rule3 = rules.firstWhereOrNull(
        (r) =>
            const SetEquality().equals(r.antecedent, {'diaper'}) &&
            const SetEquality().equals(r.consequent, {'beer'}),
      );
      expect(rule3, isNotNull);
      expect(rule3!.confidence, closeTo(0.75, 0.001));

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

    test('generates no rules from itemsets of length 1', () {
      final singleItemsets = {
        ['a']: 5,
        ['b']: 3,
      };
      final generator = RuleGenerator<String>(
        minConfidence: 0.1,
        frequentItemsets: singleItemsets,
        totalTransactions: 10,
      );
      final rules = generator.generateRules();
      expect(rules, isEmpty);
    });

    test('generates correct rules from a more complex scenario', () {
      final complexItemsets = {
        ['a']: 8,
        ['b']: 6,
        ['c']: 5,
        ['d']: 5,
        ['a', 'b']: 5,
        ['a', 'd']: 4,
        ['a', 'c']: 3,
        ['b', 'd']: 3,
        ['a', 'b', 'd']: 2,
      };
      final generator = RuleGenerator<String>(
        minConfidence: 0.6,
        frequentItemsets: complexItemsets,
        totalTransactions: 10,
      );
      final rules = generator.generateRules();

      // Check total number of rules
      // {a} -> {b} conf=5/8=0.625
      // {b} -> {a} conf=5/6=0.833
      // {a} -> {d} conf=4/8=0.5 (skip)
      // {d} -> {a} conf=4/5=0.8
      // {a} -> {c} conf=3/8=0.375 (skip)
      // {c} -> {a} conf=3/5=0.6
      // {b} -> {d} conf=3/6=0.5 (skip)
      // {d} -> {b} conf=3/5=0.6
      // {a,b} -> {d} conf=2/5=0.4 (skip)
      // {a,d} -> {b} conf=2/4=0.5 (skip)
      // {b,d} -> {a} conf=2/3=0.666
      // {a} -> {b,d} conf=2/8=0.25 (skip)
      // {b} -> {a,d} conf=2/6=0.333 (skip)
      // {d} -> {a,b} conf=2/5=0.4 (skip)
      expect(rules.length, equals(6));

      // Check a specific complex rule: {b, d} => {a}
      // support({b,d}) = 3/10 = 0.3
      // support({a}) = 8/10 = 0.8
      // support({a,b,d}) = 2/10 = 0.2
      // confidence = 0.2 / 0.3 = 0.666...
      // lift = 0.666 / 0.8 = 0.833...
      final rule = rules.firstWhereOrNull(
        (r) =>
            const SetEquality().equals(r.antecedent, {'b', 'd'}) &&
            const SetEquality().equals(r.consequent, {'a'}),
      );
      expect(rule, isNotNull);
      expect(rule!.confidence, closeTo(0.666, 0.001));
      expect(rule.support, closeTo(0.2, 0.001));
      expect(rule.lift, closeTo(0.833, 0.001));
    });
  });
}
