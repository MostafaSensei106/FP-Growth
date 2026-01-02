import 'dart:io';
import 'dart:convert';
import 'package:fp_growth/fp_growth.dart';

// Helper for formatting Output
String formatSize(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';

void main(List<String> args) async {
  if (args.isEmpty) {
    print(
      'Usage: dart compile exe benchmark_all.dart -o bench && ./bench <csv_file>',
    );
    exit(1);
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!file.existsSync()) {
    print('Error: File not found.');
    exit(1);
  }

  print('==================================================');
  print('🧪 STARTING COMPREHENSIVE BENCHMARK');
  print('📂 Dataset: $filePath');
  print('==================================================\n');

  // ---------------------------------------------------------
  // SCENARIO 1: mineFromList (Memory Heavy)
  // ---------------------------------------------------------
  print('--- [Test 1] In-Memory List (mineFromList) ---');
  print('Loading file into RAM first (Prep time)...');

  // Pre-load data to treat it as "Already in Memory"
  final lines = await file.readAsLines();
  final transactions = lines
      .map((line) => line.split(',')) // Simple CSV split
      .toList();

  print('Data Loaded. Starting Algorithm Timer...');

  final sw1 = Stopwatch()..start();
  final memStart1 = ProcessInfo.currentRss;

  final fp1 = FPGrowth<String>(
    minSupport: 50,
    parallelism: Platform.numberOfProcessors,
  );
  final (res1, count1) = await fp1.mineFromList(transactions);

  sw1.stop();
  final memEnd1 = ProcessInfo.currentRss;

  print('✅ Result: ${res1.length} itemsets found.');
  print('⏱️  Time: ${sw1.elapsedMilliseconds} ms');
  print(
    '💾 Memory Delta: ${formatSize(memEnd1 - memStart1)} (Excludes initial data load)',
  );
  print('--------------------------------------------------\n');

  // ---------------------------------------------------------
  // SCENARIO 2: runFPGrowthOnCsv (Low Memory / Streaming)
  // ---------------------------------------------------------
  print('--- [Test 2] CSV Streaming (runFPGrowthOnCsv) ---');
  // Trigger GC logic is hard in Dart, so just assume steady state or restart process ideally.

  final sw2 = Stopwatch()..start();
  final memStart2 = ProcessInfo.currentRss;

  final (res2, count2) = await runFPGrowthOnCsv(
    filePath,
    minSupport: 50,
    parallelism: Platform.numberOfProcessors,
  );

  sw2.stop();
  final memEnd2 = ProcessInfo.currentRss;

  print('✅ Result: ${res2.length} itemsets found.');
  print('⏱️  Time: ${sw2.elapsedMilliseconds} ms');
  print(
    '💾 Memory Delta: ${formatSize(memEnd2 - memStart2)} (Very Low footprint)',
  );
  print('--------------------------------------------------\n');

  // ---------------------------------------------------------
  // SCENARIO 3: Custom Stream Provider (Advanced)
  // ---------------------------------------------------------
  print('--- [Test 3] Custom Stream Provider (mine generic) ---');

  // Define the provider logic
  Stream<List<String>> streamProvider() {
    return file
        .openRead()
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .map((line) => line.split(','));
  }

  final sw3 = Stopwatch()..start();

  final fp3 = FPGrowth<String>(
    minSupport: 50,
    parallelism: Platform.numberOfProcessors,
  );
  final (res3, count3) = await fp3.mine(streamProvider); // Passing the function

  sw3.stop();

  print('✅ Result: ${res3.length} itemsets found.');
  print('⏱️  Time: ${sw3.elapsedMilliseconds} ms');
  print('💾 Memory Delta: N/A');
  print('--------------------------------------------------\n');

  print('🏁 ALL TESTS COMPLETE.');
}
