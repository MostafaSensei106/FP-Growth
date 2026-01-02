import 'dart:convert';
import '../../fp_growth.dart';

/// Converts a map of frequent itemsets into a JSON-encodable list of maps.
///
/// Each map in the list represents an itemset and contains an 'itemset' key
/// (a list of strings) and a 'support' key (an integer).
List<Map<String, dynamic>> frequentItemsetsToJsonEncodable<T>(
  Map<List<T>, int> itemsets,
) {
  return itemsets.entries
      .map(
        (entry) => {
          'itemset': entry.key.map((e) => e.toString()).toList(),
          'support': entry.value,
        },
      )
      .toList();
}

/// Exports frequent itemsets to a JSON string.
///
/// [itemsets] is a map where keys are frequent itemsets (List  < T > ) and values are their support counts.
/// Returns a JSON string representing the itemsets.
String exportFrequentItemsetsToJson<T>(Map<List<T>, int> itemsets) {
  return jsonEncode(frequentItemsetsToJsonEncodable(itemsets));
}

/// Exports frequent itemsets to a CSV string.
///
/// [itemsets] is a map where keys are frequent itemsets (List< T >) and values are their support counts.
/// [delimiter] is the delimiter used to separate items within an itemset. Defaults to ';'.
/// Returns a CSV string representing the itemsets.
String exportFrequentItemsetsToCsv<T>(
  Map<List<T>, int> itemsets, {
  String delimiter = ';',
}) {
  final buffer = StringBuffer('Itemset,Support\n');

  for (final entry in itemsets.entries) {
    final itemsetStr = entry.key.map((e) => e.toString()).join(delimiter);
    buffer.writeln('"$itemsetStr",${entry.value}');
  }

  return buffer.toString();
}

/// Converts a list of association rules into a JSON-encodable list of maps.
///
// Each map contains keys for 'antecedent', 'consequent', and the rule's
/// metrics ('support', 'confidence', 'lift', 'leverage', 'conviction').
List<Map<String, dynamic>> rulesToJsonEncodable<T>(
  List<AssociationRule<T>> rules,
) {
  return rules
      .map(
        (rule) => {
          'antecedent': rule.antecedent.map((e) => e.toString()).toList(),
          'consequent': rule.consequent.map((e) => e.toString()).toList(),
          'support': rule.support,
          'confidence': rule.confidence,
          'lift': rule.lift,
          'leverage': rule.leverage,
          'conviction': rule.conviction.isInfinite ? null : rule.conviction,
        },
      )
      .toList();
}

/// Exports association rules to a JSON string.
///
/// [rules] is a list of AssociationRule< T > objects.
/// Returns a JSON string representing the rules.
String exportRulesToJson<T>(List<AssociationRule<T>> rules) {
  return jsonEncode(rulesToJsonEncodable(rules));
}

/// Exports association rules to a CSV string.
///
/// [rules] is a list of AssociationRule< T > objects.
/// [delimiter] is the delimiter used to separate items within sets. Defaults to ';'.
/// Returns a CSV string representing the rules.
String exportRulesToCsv<T>(
  List<AssociationRule<T>> rules, {
  String delimiter = ';',
}) {
  final buffer = StringBuffer(
    'Antecedent,Consequent,Support,Confidence,Lift,Leverage,Conviction\n',
  );

  for (final rule in rules) {
    final antecedentStr = rule.antecedent
        .map((e) => e.toString())
        .join(delimiter);
    final consequentStr = rule.consequent
        .map((e) => e.toString())
        .join(delimiter);
    final convictionStr = rule.conviction.isInfinite
        ? 'INF'
        : rule.conviction.toString();

    buffer.writeln(
      '"$antecedentStr",'
      '"$consequentStr",'
      '${rule.support},'
      '${rule.confidence},'
      '${rule.lift},'
      '${rule.leverage},'
      '$convictionStr',
    );
  }

  return buffer.toString();
}

/// Exports frequent itemsets to a formatted text string.
///
/// [itemsets] is a map where keys are frequent itemsets and values are support counts.
/// [sortBySupport] if true, sorts itemsets by support (descending). Defaults to true.
/// Returns a formatted text string.
String exportFrequentItemsetsToText<T>(
  Map<List<T>, int> itemsets, {
  bool sortBySupport = true,
}) {
  final buffer = StringBuffer('Frequent Itemsets:\n');
  buffer.writeln('=' * 50);

  final entries = itemsets.entries.toList();
  if (sortBySupport) {
    entries.sort((a, b) => b.value.compareTo(a.value));
  }

  for (final entry in entries) {
    final itemsetStr = '{${entry.key.join(', ')}}';
    buffer.writeln('$itemsetStr => Support: ${entry.value}');
  }

  return buffer.toString();
}

/// Exports association rules to a formatted text string.
///
/// [rules] is a list of AssociationRule< T > objects.
/// [sortBy] determines the sorting criteria: 'confidence', 'lift', or 'support'. Defaults to 'confidence'.
/// Returns a formatted text string.
String exportRulesToText<T>(
  List<AssociationRule<T>> rules, {
  String sortBy = 'confidence',
}) {
  final buffer = StringBuffer('Association Rules:\n');
  buffer.writeln('=' * 80);

  final sortedRules = List<AssociationRule<T>>.from(rules);
  switch (sortBy.toLowerCase()) {
    case 'lift':
      sortedRules.sort(AssociationRule.compareByLift);
      break;
    case 'support':
      sortedRules.sort(AssociationRule.compareBySupport);
      break;
    case 'confidence':
    default:
      sortedRules.sort(AssociationRule.compareByConfidence);
  }

  for (var i = 0; i < sortedRules.length; i++) {
    buffer.writeln('${i + 1}. ${sortedRules[i].formatWithMetrics()}');
  }

  return buffer.toString();
}
