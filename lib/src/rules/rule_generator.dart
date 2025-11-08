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
        final subsets = _findSubsets(itemset);
        for (final subset in subsets) {
          final antecedent = subset.toSet();
          final consequent = itemset.toSet()..removeAll(antecedent);

          if (antecedent.isNotEmpty && consequent.isNotEmpty) {
            final rule = _createRule(antecedent, consequent);
            if (rule != null && rule.confidence >= minConfidence) {
              rules.add(rule);
            }
          }
        }
      }
    }

    return rules;
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
      return null;
    }

    final itemsetSupport = itemsetSupportCount / totalTransactions;
    final antecedentSupport = antecedentSupportCount / totalTransactions;
    final consequentSupport = consequentSupportCount / totalTransactions;

    final confidence = itemsetSupport / antecedentSupport;
    final lift = confidence / consequentSupport;
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

  /// Finds all non-empty, proper subsets of a given itemset.
  List<List<T>> _findSubsets(List<T> itemset) {
    final List<List<T>> subsets = [];
    final int n = itemset.length;

    // Iterate from 1 to 2^n - 2 to get all non-empty proper subsets.
    for (int i = 1; i < (1 << n) - 1; i++) {
      final List<T> subset = [];
      for (int j = 0; j < n; j++) {
        if ((i >> j) & 1 == 1) {
          subset.add(itemset[j]);
        }
      }
      subsets.add(subset);
    }

    return subsets;
  }
}
