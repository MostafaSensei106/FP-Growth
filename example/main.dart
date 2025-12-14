import 'dart:async';
import 'package:fp_growth/fp_growth.dart';
import 'package:fp_growth/src/utils/exporter.dart';

// A standard example demonstrating the basic usage of FPGrowth.
Future<void> runStandardExample() async {
  print('--- Running Standard FP-Growth Example ---');

  // 1. Define your transactions
  final transactions = [
    ['bread', 'milk'],
    ['bread', 'diaper', 'beer', 'eggs'],
    ['milk', 'diaper', 'beer', 'cola'],
    ['bread', 'milk', 'diaper', 'beer'],
    ['bread', 'milk', 'diaper', 'cola'],
  ];
  final totalTransactions = transactions.length;
  print('Total transactions: $totalTransactions\n');

  // 2. Instantiate FPGrowth with minimum support
  final fpGrowth = FPGrowth<String>(minSupport: 3);

  // 3. Add transactions and mine for frequent itemsets
  fpGrowth.addTransactions(transactions);
  final frequentItemsets = await fpGrowth.mineFrequentItemsets();

  print('Found ${frequentItemsets.length} frequent itemsets (minSupport: 3):');
  frequentItemsets.forEach((itemset, support) {
    final supportPercent = (support / totalTransactions * 100).toStringAsFixed(
      1,
    );
    print('  {${itemset.join(', ')}} - Support: $support ($supportPercent%)');
  });
  print('-------------------------\n');

  // 4. Generate association rules with minimum confidence
  final ruleGenerator = RuleGenerator<String>(
    minConfidence: 0.7, // 70%
    frequentItemsets: frequentItemsets,
    totalTransactions: totalTransactions,
  );
  final rules = ruleGenerator.generateRules();

  print('Found ${rules.length} association rules (minConfidence: 70%):');
  for (var rule in rules) {
    print('  ${rule.formatWithMetrics()}');
  }
  print('-------------------------\n');

  // 5. Export results to different formats
  print('--- Result Exporting Examples ---');
  final itemsetsAsText = exportFrequentItemsetsToText(frequentItemsets);
  final rulesAsJson = exportRulesToJson(rules);

  print('Frequent Itemsets (Formatted Text):\n$itemsetsAsText');
  print('Association Rules (JSON):\n$rulesAsJson');
  print('-------------------------\n');
}

// An example showing how to process a stream of transactions.
Future<void> runStreamExample() async {
  print('--- Running Stream Processing Example ---');

  // 1. Create a stream of transactions
  final transactionStream = Stream.fromIterable([
    ['a', 'b'],
    ['b', 'c', 'd'],
    ['a', 'c', 'd', 'e'],
  ]);

  // 2. Instantiate FPGrowth and the StreamProcessor
  final fpGrowth = FPGrowth<String>(minSupport: 2);
  final streamProcessor = StreamProcessor(fpGrowth);

  // 3. Process the stream
  await streamProcessor.process(transactionStream);
  print('Stream processing complete.');

  // 4. Mine the frequent itemsets from the processed transactions
  final frequentItemsets = await fpGrowth.mineFrequentItemsets();
  final totalTransactions = fpGrowth.transactionCount;

  print(
    'Found ${frequentItemsets.length} frequent itemsets from stream (minSupport: 2):',
  );
  frequentItemsets.forEach((itemset, support) {
    final supportPercent = (support / totalTransactions * 100).toStringAsFixed(
      1,
    );
    print('  {${itemset.join(', ')}} - Support: $support ($supportPercent%)');
  });
  print('-------------------------\n');
}

Future<void> main() async {
  await runStandardExample();
  await runStreamExample();
}
