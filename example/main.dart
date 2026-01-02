import 'dart:async';
import 'dart:io';
import 'package:fp_growth/fp_growth.dart';

/// Example 1: Processing a simple, in-memory list of transactions.
/// This is the easiest way to get started if your data is already in a List.
Future<void> runInMemoryExample() async {
  print('--- Example 1: Running on an In-Memory List ---');

  // 1. Define your transactions
  final transactions = [
    ['bread', 'milk'],
    ['bread', 'diaper', 'beer', 'eggs'],
    ['milk', 'diaper', 'beer', 'cola'],
    ['bread', 'milk', 'diaper', 'beer'],
    ['bread', 'milk', 'diaper', 'cola'],
  ];

  // 2. Instantiate FPGrowth
  final fpGrowth = FPGrowth<String>(minSupport: 3);

  // 3. Use the `mineFromList` convenience method
  final (frequentItemsets, totalTransactions) = await fpGrowth.mineFromList(
    transactions,
  );

  print(
    'Found ${frequentItemsets.length} frequent itemsets in $totalTransactions transactions (minSupport: 3):',
  );
  frequentItemsets.forEach((itemset, support) {
    print('  {${itemset.join(', ')}} - Support: $support');
  });
  print('--------------------------------------------------\n');

  // 4. Generate and display association rules
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
  print('--------------------------------------------------\n');
}

/// Example 2: Processing a large CSV file using the recommended helper.
/// This is the best approach for large files as it streams data with low memory usage.
Future<void> runFileStreamExample() async {
  print('--- Example 2: Running on a Large CSV File ---');

  // 1. Create a dummy CSV file for the example
  final filePath = 'transactions.csv';
  final file = File(filePath);
  await file.writeAsString('a,b,c\na,b\nb,c\na,c\nd,e,f');

  print('Created dummy file: $filePath');
  print('Mining frequent itemsets with minSupport: 2...');

  // 2. Use the `runFPGrowthOnCsv` top-level function
  // It handles file reading, stream management, and mining in one call.
  final (itemsets, count) = await runFPGrowthOnCsv(filePath, minSupport: 2);

  print('Found ${itemsets.length} frequent itemsets in $count transactions.');
  itemsets.forEach((itemset, support) {
    print('  {${itemset.join(', ')}} - Support: $support');
  });

  // Clean up the dummy file
  await file.delete();
  print('--------------------------------------------------\n');
}

/// Example 3: Using a custom stream provider for advanced use cases.
/// This gives you maximum flexibility for custom data sources.
Future<void> runCustomStreamExample() async {
  print('--- Example 3: Using a Custom Stream Provider ---');

  // 1. Define a function that provides a new stream on each call.
  // This is essential for the two-pass algorithm.
  Stream<List<String>> streamProvider() => Stream.fromIterable([
    ['x', 'y', 'z'],
    ['x', 'y'],
    ['y', 'z'],
    ['x', 'z', 'w'],
  ]);

  // 2. Instantiate FPGrowth and pass the stream provider to the core `mine` method.
  final fpGrowth = FPGrowth<String>(minSupport: 2);
  final (frequentItemsets, totalTransactions) = await fpGrowth.mine(
    streamProvider,
  );

  print(
    'Found ${frequentItemsets.length} frequent itemsets in $totalTransactions transactions (minSupport: 2):',
  );
  frequentItemsets.forEach((itemset, support) {
    print('  {${itemset.join(', ')}} - Support: $support');
  });
  print('--------------------------------------------------\n');
}

Future<void> main() async {
  await runInMemoryExample();
  await runFileStreamExample();
  await runCustomStreamExample();
}
