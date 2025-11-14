import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:fp_growth/fp_growth.dart';
import 'package:fp_growth/src/utils/exporter.dart';
import 'package:fp_growth/src/utils/logger.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('input',
        abbr: 'i', help: 'Path to the input CSV file.', mandatory: true)
    ..addOption('minSupport',
        abbr: 's',
        help:
            'Minimum support threshold (e.g., 0.05 for 5% or 5 for an absolute count).',
        defaultsTo: '0.05')
    ..addOption('minConfidence',
        abbr: 'c',
        help: 'Minimum confidence threshold for association rules.',
        defaultsTo: '0.7')
    ..addOption('log-level',
        help:
            'Set the logging level (debug, info, warning, error, critical, none).',
        defaultsTo: 'info')
    ..addOption('output-file',
        abbr: 'o', help: 'Path to an output file to save results.')
    ..addOption('output-format',
        abbr: 'f', help: 'Output format (json or csv).', defaultsTo: 'json');

  try {
    final argResults = parser.parse(arguments);

    final inputFile = File(argResults['input']);
    if (!inputFile.existsSync()) {
      print('Error: Input file not found at ${inputFile.path}');
      exit(1);
    }

    final minSupport = double.parse(argResults['minSupport']);
    final minConfidence = double.parse(argResults['minConfidence']);

    // Parse log level
    final logLevelString = argResults['log-level'].toString().toLowerCase();
    LogLevel logLevel;
    switch (logLevelString) {
      case 'debug':
        logLevel = LogLevel.debug;
        break;
      case 'info':
        logLevel = LogLevel.info;
        break;
      case 'warning':
        logLevel = LogLevel.warning;
        break;
      case 'error':
        logLevel = LogLevel.error;
        break;
      case 'critical':
        logLevel = LogLevel.critical;
        break;
      case 'none':
        logLevel = LogLevel.none;
        break;
      default:
        print(
            'Warning: Invalid log level "$logLevelString". Defaulting to "info".');
        logLevel = LogLevel.info;
    }
    final logger = Logger(initialLevel: logLevel);

    logger.info('Reading transactions from ${inputFile.path}...');
    final csvContent = inputFile.readAsStringSync();
    final transactions = transactionsFromCsv(csvContent);
    final totalTransactions = transactions.length;
    logger.info('Found $totalTransactions transactions.');

    logger.info('Mining frequent itemsets with minSupport: $minSupport...');
    final fpGrowth = FPGrowth<String>(minSupport: minSupport, logger: logger);
    fpGrowth.addTransactions(transactions);
    final frequentItemsetsFuture = fpGrowth.mineFrequentItemsets();
    final frequentItemsets = await frequentItemsetsFuture;
    logger.info('Found ${frequentItemsets.length} frequent itemsets.');
    print('-' * 20); // Print separator
    frequentItemsets.forEach((itemset, support) {
      final supportPercent =
          (support / totalTransactions * 100).toStringAsFixed(2);
      print('{${itemset.join(', ')}} - Support: $support ($supportPercent%)');
    });
    print('-' * 20);

    logger.info(
        'Generating association rules with minConfidence: $minConfidence...');
    final ruleGenerator = RuleGenerator<String>(
      minConfidence: minConfidence,
      frequentItemsets: frequentItemsets,
      totalTransactions: totalTransactions,
    );
    final rules = ruleGenerator.generateRules();
    logger.info('Found ${rules.length} association rules.');
    print('-' * 20);
    for (var rule in rules) {
      print(rule.formatWithMetrics());
    }
    print('-' * 20);

    // Handle output to file
    final outputFile = argResults['output-file'];
    if (outputFile != null) {
      final outputFormat = argResults['output-format'].toString().toLowerCase();
      String outputContent;

      if (outputFormat == 'json') {
        final String frequentItemsetsJson =
            exportFrequentItemsetsToJson(frequentItemsets);
        final String rulesJson = exportRulesToJson(rules);

        // Combine into a single JSON object for better structure
        final Map<String, dynamic> combinedResults = {
          'frequentItemsets': jsonDecode(frequentItemsetsJson),
          'associationRules': jsonDecode(rulesJson),
        };
        outputContent = JsonEncoder.withIndent('  ').convert(combinedResults);
      } else if (outputFormat == 'csv') {
        final String itemsetsCsv =
            exportFrequentItemsetsToCsv(frequentItemsets);
        final String rulesCsv = exportRulesToCsv(rules);
        outputContent =
            'Frequent Itemsets:\n$itemsetsCsv\n\nAssociation Rules:\n$rulesCsv';
      } else {
        logger.error(
            'Unsupported output format: $outputFormat. Supported formats are "json" and "csv".');
        exit(1);
      }

      File(outputFile).writeAsStringSync(outputContent);
      logger.info(
          'Results successfully written to $outputFile in $outputFormat format.');
    }
  } on ArgParserException catch (e) {
    print('Error parsing arguments: ${e.message}');
    print('\nUsage:');
    print(parser.usage);
    exit(1);
  } on FormatException catch (e) {
    print('Error parsing numeric arguments: ${e.message}');
    print('\nUsage:');
    print(parser.usage);
    exit(1);
  } catch (e) {
    print('An unexpected error occurred: $e');
    exit(1);
  }
}
