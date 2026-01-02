import 'dart:collection';
import 'package:collection/collection.dart';
import 'association_rule.dart';

/// Generates association rules from a set of frequent itemsets.
///
/// This class takes the output of the FP-Growth algorithm (frequent itemsets
/// and their support counts) and generates association rules that meet a
/// minimum confidence threshold.
class RuleGenerator<T> {
  /// The minimum confidence threshold for a rule to be considered valid.
  ///
  /// Confidence is the probability of seeing the consequent in a transaction
  /// that also contains the antecedent.
  /// Range: 0.0 to 1.0.
  final double minConfidence;

  /// A map of frequent itemsets to their support counts.
  final Map<List<T>, int> frequentItemsets;

  /// The total number of transactions processed.
  final int totalTransactions;

  /// A map to quickly look up the support of any frequent itemset.
  final Map<Set<T>, int> _supportCache = HashMap<Set<T>, int>(
    equals: const SetEquality().equals,
    hashCode: const SetEquality().hash,
  );

  /// Creates a new [RuleGenerator].
  ///
  /// [minConfidence] is the minimum confidence for rules.
  /// [frequentItemsets] is the map of frequent itemsets to their support counts.
  /// [totalTransactions] is the total number of original transactions.
  RuleGenerator({
    required this.minConfidence,
    required this.frequentItemsets,
    required this.totalTransactions,
  }) {
    // Populate the support cache for efficient lookups.
    for (final entry in frequentItemsets.entries) {
      _supportCache[entry.key.toSet()] = entry.value;
    }
  }

  /// Generates all possible association rules that meet the `minConfidence`.
  ///
  /// Returns a list of [AssociationRule] objects.
  List<AssociationRule<T>> generateRules() {
    final List<AssociationRule<T>> rules = [];
    for (final itemset in frequentItemsets.keys) {
      if (itemset.length > 1) {
        _generateRulesForItemset(itemset.toSet(), rules);
      }
    }
    return rules;
  }

  /// Generates rules for a single frequent itemset using an Apriori-style approach.
  void _generateRulesForItemset(
    Set<T> itemset,
    List<AssociationRule<T>> rules,
  ) {
    if (itemset.length < 2) return;

    // Start with consequents of size 1
    var levelOneConsequents = itemset
        .map((item) => {item})
        .toList(growable: false);

    // This list will hold confident consequents from the current level (k)
    // to generate candidates for the next level (k+1).
    var confidentConsequents = <Set<T>>[];

    for (final consequent in levelOneConsequents) {
      final antecedent = itemset.difference(consequent);
      final rule = _createRule(antecedent, consequent);
      if (rule != null && rule.confidence >= minConfidence) {
        rules.add(rule);
        confidentConsequents.add(consequent);
      }
    }

    // Iteratively generate larger consequents
    for (int k = 1; k < itemset.length - 1; k++) {
      if (confidentConsequents.isEmpty) break;

      final nextLevelCandidates = _generateNextLevelConsequents(
        confidentConsequents,
      );
      final nextConfidentConsequents = <Set<T>>[];

      for (final consequent in nextLevelCandidates) {
        // Anti-monotonicity pruning: if a (k)-consequent was not confident,
        // any (k+1)-super-consequent will also not be confident.
        // We ensure all subsets of the new candidate were in the previous confident list.
        final allSubsetsWereConfident =
            k == 1 ||
            consequent.every(
              (item) => confidentConsequents.any(
                (c) => c.containsAll(consequent.difference({item})),
              ),
            );

        if (allSubsetsWereConfident) {
          final antecedent = itemset.difference(consequent);
          final rule = _createRule(antecedent, consequent);

          if (rule != null && rule.confidence >= minConfidence) {
            rules.add(rule);
            nextConfidentConsequents.add(consequent);
          }
        }
      }
      confidentConsequents = nextConfidentConsequents;
    }
  }

  /// Generates (k+1)-itemset candidates from confident k-itemsets.
  List<Set<T>> _generateNextLevelConsequents(List<Set<T>> consequents) {
    final candidates = HashSet<Set<T>>(
      equals: const SetEquality().equals,
      hashCode: const SetEquality().hash,
    );

    for (int i = 0; i < consequents.length; i++) {
      for (int j = i + 1; j < consequents.length; j++) {
        final c1 = consequents[i];
        final c2 = consequents[j];

        // Join step: if two sets share all but one item, their union is a candidate.
        final union = c1.union(c2);
        if (union.length == c1.length + 1) {
          candidates.add(union);
        }
      }
    }
    return candidates.toList(growable: false);
  }

  /// Creates a single association rule from an antecedent and consequent.
  ///
  /// Calculates support, confidence, and lift. Returns `null` if the
  /// support for any part of the rule cannot be found.
  AssociationRule<T>? _createRule(Set<T> antecedent, Set<T> consequent) {
    final itemset = antecedent.union(consequent);

    final itemsetSupportCount = _supportCache[itemset];
    final antecedentSupportCount = _supportCache[antecedent];
    final consequentSupportCount = _supportCache[consequent];

    if (itemsetSupportCount == null ||
        antecedentSupportCount == null ||
        consequentSupportCount == null) {
      // This can happen if a subset of a frequent itemset is not frequent,
      // which should not occur with a correct FP-Growth implementation.
      // However, we check for safety.
      return null;
    }

    final itemsetSupport = itemsetSupportCount / totalTransactions;
    final antecedentSupport = antecedentSupportCount / totalTransactions;
    final consequentSupport = consequentSupportCount / totalTransactions;

    // Confidence must be calculated carefully to avoid division by zero.
    if (antecedentSupport == 0) return null;
    final confidence = itemsetSupport / antecedentSupport;

    // If confidence is below the threshold, we could stop early, but the
    // calling function handles this.

    final lift = (consequentSupport == 0)
        ? 0.0
        : confidence / consequentSupport;
    final leverage = itemsetSupport - (antecedentSupport * consequentSupport);

    // Conviction is undefined if confidence is 1.
    final conviction = (confidence >= 1.0)
        ? double.infinity
        : (1 - consequentSupport) / (1 - confidence);

    return AssociationRule<T>(
      antecedent: antecedent,
      consequent: consequent,
      support: itemsetSupport,
      confidence: confidence,
      lift: lift,
      leverage: leverage,
      conviction: conviction,
    );
  }
}
