import 'package:collection/collection.dart';

/// Represents an association rule: antecedent => consequent.
///
/// An association rule suggests a relationship between two sets of items.
/// For example, `{bread, butter} => {milk}` implies that customers who buy
/// bread and butter are also likely to buy milk.
class AssociationRule<T> {
  /// The antecedent (left-hand side) of the rule.
  final Set<T> antecedent;

  /// The consequent (right-hand side) of the rule.
  final Set<T> consequent;

  /// The support of the full itemset (antecedent ∪ consequent).
  ///
  /// Support is the proportion of transactions that contain the itemset.
  /// Range: 0.0 to 1.0.
  final double support;

  /// The confidence of the rule.
  ///
  /// Confidence is the measure of how often the consequent appears in
  /// transactions that contain the antecedent.
  /// It is calculated as: `support(antecedent ∪ consequent) / support(antecedent)`.
  /// Range: 0.0 to 1.0. A higher confidence indicates a stronger rule.
  final double confidence;

  /// The lift of the rule.
  ///
  /// Lift measures how much more likely the consequent is to be purchased when
  /// the antecedent is purchased, compared to its likelihood of being purchased
  /// independently.
  /// It is calculated as: `confidence / support(consequent)`.
  /// - Lift > 1 suggests a positive correlation.
  /// - Lift = 1 suggests independence.
  /// - Lift < 1 suggests a negative correlation.
  final double lift;

  /// The leverage of the rule.
  ///
  /// Leverage measures the difference between the frequency of the antecedent
  /// and consequent appearing together and the frequency that would be
  /// expected if they were independent.
  /// A value of 0 indicates independence.
  final double leverage;

  /// The conviction of the rule.
  ///
  /// Conviction measures the dependency of the consequent on the antecedent.
  /// A high conviction value means that the consequent is highly dependent on
  /// the antecedent. For example, a conviction of 1.5 suggests that the rule
  /// would be incorrect 50% more often if the association was purely random.
  final double conviction;

  /// Cached itemset to avoid repeated union operations.
  late final Set<T> _itemset = antecedent.union(consequent);

  /// Cached hash code for better performance in collections.
  late final int _hashCode = _computeHashCode();

  /// Creates a new [AssociationRule].
  AssociationRule({
    required this.antecedent,
    required this.consequent,
    required this.support,
    required this.confidence,
    required this.lift,
    required this.leverage,
    required this.conviction,
  }) {
    assert(antecedent.isNotEmpty, 'Antecedent cannot be empty');
    assert(consequent.isNotEmpty, 'Consequent cannot be empty');
    assert(support >= 0.0 && support <= 1.0, 'Support must be between 0 and 1');
    assert(confidence >= 0.0 && confidence <= 1.0,
        'Confidence must be between 0 and 1');
  }

  /// Returns the full itemset (antecedent and consequent combined).
  Set<T> get itemset => _itemset;

  @override
  String toString() {
    final anteStr = '{${antecedent.join(', ')}}';
    final consStr = '{${consequent.join(', ')}}';
    return '$anteStr => $consStr';
  }

  /// Formats the rule with its key metrics for easy interpretation.
  String formatWithMetrics() {
    final convStr = conviction.isInfinite ? '∞' : conviction.toStringAsFixed(3);
    return '${toString()} '
        '[sup: ${support.toStringAsFixed(3)}, '
        'conf: ${confidence.toStringAsFixed(3)}, '
        'lift: ${lift.toStringAsFixed(2)}, '
        'lev: ${leverage.toStringAsFixed(3)}, '
        'conv: $convStr]';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AssociationRule<T>) return false;

    // Use SetEquality for proper set comparison
    const setEq = SetEquality();
    return setEq.equals(antecedent, other.antecedent) &&
        setEq.equals(consequent, other.consequent);
  }

  @override
  int get hashCode => _hashCode;

  int _computeHashCode() {
    const setEq = SetEquality();
    return Object.hash(
      setEq.hash(antecedent),
      setEq.hash(consequent),
    );
  }

  /// Compares rules by confidence (descending order).
  static int compareByConfidence<T>(
          AssociationRule<T> a, AssociationRule<T> b) =>
      b.confidence.compareTo(a.confidence);

  /// Compares rules by lift (descending order).
  static int compareByLift<T>(AssociationRule<T> a, AssociationRule<T> b) =>
      b.lift.compareTo(a.lift);

  /// Compares rules by support (descending order).
  static int compareBySupport<T>(AssociationRule<T> a, AssociationRule<T> b) =>
      b.support.compareTo(a.support);
}
