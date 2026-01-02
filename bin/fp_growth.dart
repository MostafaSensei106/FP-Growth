import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:fp_growth/fp_growth.dart';
import 'package:fp_growth/src/utils/exporter.dart';
import 'package:fp_growth/src/utils/logger.dart';

Future<void> main(List<String> arguments) async {
  final parser = _createArgParser();
  try {
    final argResults = parser.parse(arguments);
    await _runFPGrowth(argResults);
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
  } catch (e, s) {
    print('An unexpected error occurred: $e');
    print('Stack trace:\n$s');
    exit(1);
  }
}

ArgParser _createArgParser() {
  return ArgParser()
    ..addOption(
      'input',
      abbr: 'i',
      help: 'Path to the input CSV file.',
      mandatory: true,
    )
    ..addOption(
      'minSupport',
      abbr: 's',
      help:
          'Minimum support threshold (e.g., 0.05 for 5% or 5 for an absolute count).',
      defaultsTo: '0.05',
    )
    ..addOption(
      'minConfidence',
      abbr: 'c',
      help: 'Minimum confidence threshold for association rules.',
      defaultsTo: '0.7',
    )
    ..addOption(
      'log-level',
      help:
          'Set the logging level (debug, info, warning, error, critical, none).',
      defaultsTo: 'info',
    )
    ..addOption(
      'output-file',
      abbr: 'o',
      help: 'Path to an output file to save results.',
    )
    ..addOption(
      'output-format',
      abbr: 'f',
      help: 'Output format (json or csv).',
      defaultsTo: 'json',
    )
    ..addOption(
      'parallelism',
      abbr: 'p',
      help: 'Number of isolates to use for parallel processing.',
      defaultsTo: '1',
    );
}

LogLevel _parseLogLevel(
  String levelStr, {
  LogLevel defaultLevel = LogLevel.info,
}) {
  const levelMap = {
    'debug': LogLevel.debug,
    'info': LogLevel.info,
    'warning': LogLevel.warning,
    'error': LogLevel.error,
    'critical': LogLevel.critical,
    'none': LogLevel.none,
  };
  final level = levelMap[levelStr.toLowerCase()];
  if (level == null) {
    print(
      'Warning: Invalid log level "$levelStr". Defaulting to "${defaultLevel.name}".',
    );
    return defaultLevel;
  }
  return level;
}

Future<void> _runFPGrowth(ArgResults argResults) async {
  final inputFile = argResults['input'];
  final minSupport = double.parse(argResults['minSupport']);
  final minConfidence = double.parse(argResults['minConfidence']);
  final parallelism = int.parse(argResults['parallelism']);
  final logger = Logger(initialLevel: _parseLogLevel(argResults['log-level']));

  logger.info('Mining frequent itemsets from $inputFile...');

  // Use the high-level convenience function for processing CSV files.
  final (frequentItemsets, totalTransactions) = await runFPGrowthOnCsv(
    inputFile,
    minSupport: minSupport,
    parallelism: parallelism,
    logger: logger,
  );

  logger.info('Found ${frequentItemsets.length} frequent itemsets.');

  if (totalTransactions == 0) {
    print('No transactions found to process.');
    return;
  }

  print('-' * 20);
  frequentItemsets.forEach((itemset, support) {
    final supportPercent = (support / totalTransactions * 100).toStringAsFixed(
      2,
    );
    print('{${itemset.join(', ')}} - Support: $support ($supportPercent%)');
  });
  print('-' * 20);

  logger.info(
    'Generating association rules with minConfidence: $minConfidence...',
  );
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

  final outputFile = argResults['output-file'];
  if (outputFile != null) {
    await _writeOutput(
      outputFile,
      argResults['output-format'],
      frequentItemsets,
      rules,
      logger,
    );
  }
}

Future<void> _writeOutput(
  String path,
  String format,
  Map<List<String>, int> frequentItemsets,
  List<AssociationRule<String>> rules,
  Logger logger,
) async {
  String outputContent;
  final outputFormat = format.toLowerCase();

  if (outputFormat == 'json') {
    final combinedResults = {
      'frequentItemsets': frequentItemsetsToJsonEncodable(frequentItemsets),
      'associationRules': rulesToJsonEncodable(rules),
    };
    outputContent = JsonEncoder.withIndent('  ').convert(combinedResults);
  } else if (outputFormat == 'csv') {
    final itemsetsCsv = exportFrequentItemsetsToCsv(frequentItemsets);
    final rulesCsv = exportRulesToCsv(rules);
    outputContent =
        'Frequent Itemsets:\n$itemsetsCsv\n\nAssociation Rules:\n$rulesCsv';
  } else {
    logger.error(
      'Unsupported output format: $format. Supported formats are "json" and "csv".',
    );
    exit(1);
  }

  await File(path).writeAsString(outputContent);
  logger.info('Results successfully written to $path in $format format.');
}
