import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:fp_growth/fp_growth_io.dart';

/// Benchmarks in-memory FP-Growth execution using [FPGrowth.mineFromList]
class FPGrowthInMemoryCsvBenchmark extends AsyncBenchmarkBase {
  final String filePath;
  final double minSupport;
  final int parallelism;
  late List<List<String>> transactions;
  late FPGrowth<String> fp;

  FPGrowthInMemoryCsvBenchmark(
    this.filePath,
    this.minSupport, {
    this.parallelism = 1,
  }) : super('FPGrowth.mineFromList (In-Memory, Parallelism: $parallelism)');

  @override
  Future<void> setup() async {
    final file = File(filePath);
    final lines = await file.readAsLines();
    transactions = lines.map((line) => line.split(',')).toList();
    fp = FPGrowth<String>(minSupport: minSupport, parallelism: parallelism);
  }

  @override
  Future<void> run() async {
    await fp.mineFromList(transactions);
  }
}

/// Benchmarks streaming FP-Growth execution using [FPGrowth.mineFromCsv]
class FPGrowthStreamingCsvBenchmark extends AsyncBenchmarkBase {
  final String filePath;
  final double minSupport;
  final int parallelism;
  late FPGrowth<String> fp;

  FPGrowthStreamingCsvBenchmark(
    this.filePath,
    this.minSupport, {
    this.parallelism = 1,
  }) : super('FPGrowth.mineFromCsv (CSV Stream, Parallelism: $parallelism)');

  @override
  Future<void> setup() async {
    fp = FPGrowth<String>(minSupport: minSupport, parallelism: parallelism);
  }

  @override
  Future<void> run() async {
    await fp.mineFromCsv(filePath);
  }
}

/// Benchmarks streaming FP-Growth execution using custom stream provider and [FPGrowth.mine]
class FPGrowthCustomStreamCsvBenchmark extends AsyncBenchmarkBase {
  final String filePath;
  final double minSupport;
  final int parallelism;
  late FPGrowth<String> fp;
  late File file;

  FPGrowthCustomStreamCsvBenchmark(
    this.filePath,
    this.minSupport, {
    this.parallelism = 1,
  }) : super(
          'FPGrowth.mine (Custom Stream Provider, Parallelism: $parallelism)',
        );

  @override
  Future<void> setup() async {
    file = File(filePath);
    fp = FPGrowth<String>(minSupport: minSupport, parallelism: parallelism);
  }

  Stream<List<String>> streamProvider() {
    return file
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .map((line) => line.split(','));
  }

  @override
  Future<void> run() async {
    await fp.mine(streamProvider);
  }
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print(
        'Usage: dart run bin/api_benchmark_test.dart <csv_file> [min_support]');
    exit(1);
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!file.existsSync()) {
    print('Error: File not found: $filePath');
    exit(1);
  }

  double minSupport = 0.05;
  if (args.length > 1) {
    minSupport = double.tryParse(args[1]) ?? 0.05;
  }

  print('==================================================');
  print('🧪 RUNNING FP-GROWTH BENCHMARKS USING BENCHMARK_HARNESS');
  print('📂 Dataset: $filePath');
  print('📊 Min Support: $minSupport');
  print('==================================================\n');

  print('Running In-Memory Benchmark (Single-threaded)...');
  await FPGrowthInMemoryCsvBenchmark(filePath, minSupport, parallelism: 1)
      .report();

  print('\nRunning In-Memory Benchmark (Parallelism: 4)...');
  await FPGrowthInMemoryCsvBenchmark(filePath, minSupport, parallelism: 4)
      .report();

  print('\nRunning CSV Streaming Benchmark (Single-threaded)...');
  await FPGrowthStreamingCsvBenchmark(filePath, minSupport, parallelism: 1)
      .report();

  print('\nRunning CSV Streaming Benchmark (Parallelism: 4)...');
  await FPGrowthStreamingCsvBenchmark(filePath, minSupport, parallelism: 4)
      .report();

  print('\nRunning Custom Stream Benchmark (Single-threaded)...');
  await FPGrowthCustomStreamCsvBenchmark(filePath, minSupport, parallelism: 1)
      .report();

  print('\nRunning Custom Stream Benchmark (Parallelism: 4)...');
  await FPGrowthCustomStreamCsvBenchmark(filePath, minSupport, parallelism: 4)
      .report();

  print('\n==================================================');
  print('🏁 ALL BENCHMARKS COMPLETE.');
  print('==================================================');
}
