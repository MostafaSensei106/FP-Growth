import 'package:fp_growth/fp_growth.dart';

Future<void> main() async {
  // 1. Define your transactions
  // This could come from a database, a file, or any other source.
  final transactions = [
    ['bread', 'milk'],
    ['bread', 'diaper', 'beer', 'eggs'],
    ['milk', 'diaper', 'beer', 'cola'],
    ['bread', 'milk', 'diaper', 'beer'],
    ['bread', 'milk', 'diaper', 'cola'],
  ];
  final totalTransactions = transactions.length;

  print('--- FP-Growth Example ---');
  print('Total transactions: $totalTransactions');
  print('-------------------------\n');

  // 2. Instantiate FPGrowth
  // You can use a relative support (e.g., 0.6 for 60%) or an
  // absolute support count (e.g., 3).
  final fpGrowth = FPGrowth<String>(minSupport: 3);

  // 3. Add transactions and mine for frequent itemsets
  fpGrowth.addTransactions(transactions);
  final frequentItemsets = fpGrowth.mineFrequentItemsets();

  print(
      'Found ${(await frequentItemsets).length} frequent itemsets with minimum support of 3:');
  (await frequentItemsets).forEach((itemset, support) {
    final supportPercent =
        (support / totalTransactions * 100).toStringAsFixed(1);
    print('  {${itemset.join(', ')}} - Support: $support ($supportPercent%)');
  });
  print('-------------------------\n');

  // 4. Generate association rules
  // You can set a minimum confidence threshold.
  final ruleGenerator = RuleGenerator<String>(
    minConfidence: 0.7, // 70% minimum confidence
    frequentItemsets: await frequentItemsets,
    totalTransactions: totalTransactions,
  );

  final rules = ruleGenerator.generateRules();

  print(
      'Found ${rules.length} association rules with minimum confidence of 70%:');
  for (var rule in rules) {
    // formatWithMetrics() provides a readable output with all key metrics.
    print('  ${rule.formatWithMetrics()}');
  }
  print('-------------------------');
}
