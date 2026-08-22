<h1 align="center">FP-Growth</h1>
<p align="center">
  <img src="https://socialify.git.ci/MostafaSensei106/FP-Growth/image?font=KoHo&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F138288138%3Fv%3D4&name=1&owner=1&pattern=Floating+Cogs&theme=Light" alt="Banner">
</p>

<p align="center">
  <strong>A Dart library for the FP-Growth algorithm and association rule mining.</strong><br>
  Efficiently discover frequent patterns and generate insightful association rules from your data.
</p>

<p align="center">
  <a href="#-about">About</a> •
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-cli-usage">CLI</a> •
  <a href="#-performance">Performance</a> •
  <a href="#-contributing">Contributing</a> •
  <a href="#-license">License</a>
</p>

---

## 📖 About

Welcome to **FP-Growth for Dart** — a robust, highly optimized, and type-safe implementation of the **Frequent Pattern Growth (FP-Growth)** algorithm. 

Unlike the classic Apriori algorithm, which generates candidates and scans datasets repeatedly, FP-Growth uses a compressed tree structure (the FP-Tree) to mine frequent itemsets recursively with significantly lower overhead. This makes it the industry standard for:
- **Market Basket Analysis**: Identifying products that are frequently bought together.
- **Recommendation Systems**: Discovering user behavior patterns and cross-selling opportunities.
- **Relational Data Mining**: Uncovering hidden correlations in large datasets.

Built with Dart-centric optimization, this library provides a highly scalable, memory-efficient, and parallelized solution for pattern mining across server-side Dart applications, command-line interfaces, and Flutter apps.

---

## ✨ Features

### 🧠 Core Algorithm & Mining Engine
- **Efficient FP-Tree Representation**: Uses a highly compressed prefix tree to represent transactional datasets, minimizing memory usage.
- **Header Table Traversal**: Employs a quick-access header table with linked lists for fast traversal of matching item nodes.
- **Single-Path Optimization**: Automatically detects linear prefix paths and generates subsets directly via combinatorics, bypassing deep recursive tree construction.
- **Association Rule Generation**: Extracts high-value association rules with precise metrics:
  - **Support**: Relative frequency of the combined itemset in the dataset.
  - **Confidence**: Conditional probability of the consequent given the antecedent.
  - **Lift**: Strength of the rule compared to random chance (independent purchases).
  - **Leverage**: Difference between observed support and expected independent support.
  - **Conviction**: Level of dependency of the consequent on the antecedent.

### ⚡ Performance & Scalability
- **Fixed-Size Isolate Pool**: Scales computation across multiple CPU cores on native platforms using message-based isolates, avoiding the overhead of spawning isolates dynamically.
- **Two-Pass Stream Architecture**: Processes transactions in two passes (calculating item frequencies first, then building the FP-Tree) to handle large datasets from streams or files with a minimal memory footprint.
- **Hybrid CSV Parsing Engine**: Employs a zero-dependency parser with a **Fast Path** (native string splitting when no quotes are present) and a **Robust Path** (character-by-character parsing for quoted commas).
- **Graceful Web Degradation**: Written platform-agnostically; compiles seamlessly to JavaScript/Web with single-threaded mining.

### ⚙️ Utilities & Exporters
- **Built-in Exporters**: Export frequent itemsets and association rules to structured `JSON`, `CSV`, or clean `Text` formats.
- **Rich Metric Sorting**: Sort generated association rules by `confidence`, `lift`, or `support` before exporting.
- **Interactive Command-Line Tool (CLI)**: A robust terminal runner with customizable thresholds, file formatting outputs, logging configurations, and multi-core options.

---

## 📦 Installation

1. Add `fp_growth` to your `pubspec.yaml` file:

```yaml
dependencies:
  fp_growth: ^2.1.5
```

2. Retrieve dependencies using the CLI:

```bash
# For pure Dart projects
dart pub get

# For Flutter projects
flutter pub get
```

---

## 🚀 Usage

Analyzing transactional data consists of two distinct stages:
1. **Frequent Itemset Mining**: Identifying item combinations that occur together above a specified frequency threshold.
2. **Association Rule Generation**: Formulating conditional rules (`{Antecedent} => {Consequent}`) and calculating strength metrics.

### 1. Mining Frequent Itemsets

The library provides multiple ways to mine frequent itemsets based on your data source:
* **In-Memory Lists**: Use `FPGrowth.mineFromList()` for smaller datasets already loaded in memory.
* **CSV Files**: Use `FPGrowth.mineFromCsv()` for file streams (avoids loading the entire file into memory).
* **Custom Databases/Streams**: Use the generic `FPGrowth.mine()` with a stream provider function.

#### Example: From an In-Memory List

```dart
import 'package:fp_growth/fp_growth.dart';

void main() async {
  // 1. Prepare your transactional dataset
  final transactions = [
    ['bread', 'milk'],
    ['bread', 'diaper', 'beer', 'eggs'],
    ['milk', 'diaper', 'beer', 'cola'],
    ['bread', 'milk', 'diaper', 'beer'],
    ['bread', 'milk', 'diaper', 'cola'],
  ];

  // 2. Initialize FPGrowth with a minimum support threshold.
  // Values >= 1.0 are treated as absolute counts; values between 0.0 and 1.0 are relative percentages.
  final fpGrowth = FPGrowth<String>(
    minSupport: 3, // Requires items to appear in at least 3 transactions
    parallelism: 1, // Number of isolates (threads) to use
  );

  // 3. Mine the frequent itemsets
  final (frequentItemsets, totalTransactions) = await fpGrowth.mineFromList(transactions);

  // frequentItemsets is a Map<List<String>, int> mapped to their support count
  frequentItemsets.forEach((itemset, support) {
    print('Itemset: ${itemset.join(", ")} | Support Count: $support');
  });
}
```

### 2. Generating Association Rules

Once you have mined the frequent itemsets, pass them to the `RuleGenerator` along with the total transaction count to find predictive relationships.

```dart
import 'package:fp_growth/fp_growth.dart';

void main() async {
  // (Assuming frequentItemsets and totalTransactions were retrieved as shown above)
  final frequentItemsets = {
    ['bread']: 4,
    ['milk']: 4,
    ['diaper']: 4,
    ['beer']: 3,
    ['diaper', 'beer']: 3,
    ['milk', 'diaper']: 3,
    ['bread', 'milk']: 3,
    ['bread', 'diaper']: 3,
  };
  final totalTransactions = 5;

  // 1. Initialize the rule generator with a minimum confidence threshold
  final ruleGenerator = RuleGenerator<String>(
    minConfidence: 0.75, // 75% minimum confidence
    frequentItemsets: frequentItemsets,
    totalTransactions: totalTransactions,
  );

  // 2. Generate the association rules
  final rules = ruleGenerator.generateRules();

  // 3. Format and print the rules
  for (final rule in rules) {
    print(rule.formatWithMetrics());
    // Example Output:
    // {beer} => {diaper} [sup: 0.600, conf: 1.000, lift: 1.25, lev: 0.120, conv: ∞]
  }
}
```

### Other Data Sources

#### From a CSV File (Memory-Efficient Streaming)

To run mining on large CSV files without loading them fully into memory, use `fp_growth_io.dart`. This is optimized using Dart's multi-threaded Isolates.

```dart
import 'dart:io';
import 'package:fp_growth/fp_growth_io.dart'; // Import IO-specific extensions

Future<void> main() async {
  final filePath = 'large_transactions.csv';

  // Instantiate FPGrowth. 
  // Here we use Platform.numberOfProcessors to automatically utilize all CPU cores.
  final fpGrowth = FPGrowth<String>(
    minSupport: 0.02, // 2% minimum support threshold
    parallelism: Platform.numberOfProcessors,
  );

  // Mine directly from the file path
  final (itemsets, count) = await fpGrowth.mineFromCsv(filePath);

  print('Mined ${itemsets.length} frequent itemsets from $count transactions.');
}
```

#### From a Custom Stream

If your transactions are stored in a database (e.g., SQLite, PostgreSQL) or custom data stream, provide a **stream provider function** (`Stream<List<T>> Function()`). This function must yield a fresh stream each time it's called because the algorithm requires two passes over the data.

```dart
import 'package:fp_growth/fp_growth.dart';

Future<void> main() async {
  // A stream provider returning fresh transactional streams
  Stream<List<String>> databaseStreamProvider() {
    return Stream.fromIterable([
      ['apple', 'banana'],
      ['banana', 'cherry'],
      ['apple', 'banana', 'cherry'],
      ['apple', 'cherry'],
    ]);
  }

  final fpGrowth = FPGrowth<String>(minSupport: 0.50); // 50% threshold
  final (itemsets, count) = await fpGrowth.mine(databaseStreamProvider);

  print('Mined ${itemsets.length} frequent itemsets from $count stream transactions.');
}
```

#### Serializing & Exporting Results

You can export mined itemsets and rules to JSON, CSV, or human-readable text formats:

```dart
import 'package:fp_growth/fp_growth.dart';
import 'package:fp_growth/src/utils/exporter.dart'; // Exporter utility library

void exportData(Map<List<String>, int> itemsets, List<AssociationRule<String>> rules) {
  // Export Frequent Itemsets
  final itemsetsJson = exportFrequentItemsetsToJson(itemsets);
  final itemsetsCsv = exportFrequentItemsetsToCsv(itemsets, delimiter: ';');
  final itemsetsText = exportFrequentItemsetsToText(itemsets, sortBySupport: true);

  // Export Association Rules
  final rulesJson = exportRulesToJson(rules);
  final rulesCsv = exportRulesToCsv(rules, delimiter: ';');
  final rulesText = exportRulesToText(rules, sortBy: 'lift'); // Sort by: confidence, lift, or support
}
```

---

## 📋 CLI Usage

The `fp_growth` package includes a built-in command-line tool (CLI) for executing association analysis directly on CSV transaction files.

### Prerequisites

Create a transaction dataset in CSV format (e.g., `dataset.csv`), with each line representing a single transaction of comma-separated items:

```csv
bread,milk
bread,diaper,beer,eggs
milk,diaper,beer,cola
bread,milk,diaper,beer
```

### Running the CLI

Run the command-line utility using the Dart SDK:

```bash
# Basic terminal output
dart run fp_growth --input dataset.csv --minSupport 0.2 --minConfidence 0.5

# Save the combined JSON output containing itemsets and rules
dart run fp_growth -i dataset.csv -s 0.05 -c 0.1 -o output.json -f json

# Export formatted outputs to a CSV file
dart run fp_growth -i dataset.csv -s 2 -c 0.5 -o output.csv -f csv -p 4
```

### Options

| Flag | Abbreviation | Description | Default |
| :--- | :--- | :--- | :--- |
| `--input` | `-i` | **(Mandatory)** Path to the input CSV file. | |
| `--minSupport` | `-s` | Minimum support threshold as a percentage (`0.05` for 5%) or absolute count (`5`). | `0.05` |
| `--minConfidence`| `-c` | Minimum confidence threshold for association rules. | `0.05` |
| `--parallelism` | `-p` | Number of worker isolates to spawn for parallel processing. | `1` |
| `--output-file` | `-o` | Optional file path to write results. | `null` |
| `--output-format`| `-f` | Output file format (`json` or `csv`). Used only when `--output-file` is set. | `json` |
| `--log-level` | | Set the console logger level (`debug`, `info`, `warning`, `error`, `critical`, `none`). | `info` |

---

## ⚡ Performance

The package is optimized for server environments and large data pipelines. Internally, it maps string/generic item tokens to integer IDs for rapid comparisons, pre-allocates lists, and avoids iterator allocations in critical loops.

Below are benchmark results comparing the performance of **v2.1.5** against **v2.0.1** on an **AMD Ryzen™ 7 5800H (16 Threads)** with a dataset of **1,000,000 transactions** (randomized distributions) and a minimum support of `0.05` (representing 50,000 occurrences).

### Benchmark Results (v2.1.5 vs. v2.0.1)

| API Method | v2.0.1 Execution Time | New Execution Time (Single-Thread) | New Execution Time (Parallelism: 4) | Improvement vs. v2.0.1 |
| :--- | :--- | :--- | :--- | :--- |
| **In-Memory (`mineFromList`)** | **1.46 s** | **1.12 s** | **0.92 s** | **~36.8% faster** (Sub-second execution) |
| **CSV Streaming (`mineFromCsv`)** | **2.32 s** | **1.68 s** | **1.65 s** | **~29.1% faster** |
| **Custom Stream (`mine`)** | **1.82 s** | **1.40 s** | **1.58 s** | **~23.1% faster** |

---

### Key Optimization Insights
- **Sub-Second Mining**: Using a 4-thread Isolate Pool drops the processing time for 1 million transactions below the 1-second mark (**0.92s**).
- **Stream overhead reduction**: Avoids high-level iterator overhead, implementing a lightweight custom line splitter and string-to-integer mappings.
- **Fast-Path CSV Adapter**: When processing files, lines containing no escaped quotes bypass the heavy CSV parser and use a raw string split, reducing parsing time by ~30%.
- **Zero-Allocation Pruning**: Conditional trees are constructed with direct frequency scanning, eliminating heap-allocated temporary lists.

### 🧪 Running the Benchmark Suite

A pre-packaged benchmark script is included in the project. You can run benchmarks on your own CSV datasets by executing:

```bash
# Run benchmark on a custom CSV file with an optional support count/percentage
dart compile exe test/api_benchmark_test.dart -o benchmark

./benchmark <path_to_csv_file> [min_support]
```

---

## 🤝 Contributing

Contributions are welcome! If you have suggestions, bug reports, or performance optimizations:

1.  Fork the repository.
2.  Create a new branch:
    `git checkout -b feature/YourFeature`
3.  Commit your changes:
    `git commit -m "Add amazing feature"`
4.  Push to your branch:
    `git push origin feature/YourFeature`
5.  Open a pull request.

> 💡 Please read our **[Contributing Guidelines](CONTRIBUTING.md)** and open an issue first for major feature ideas or changes.

---

## ⚖️ License

This project is dual-licensed to accommodate both open-source and commercial use cases:

1. **Open Source License**: **GPL-3.0**
   - Free to use, modify, and distribute for open-source applications.
   - Any derivative works or projects that distribute this library must also be open-sourced under the GPL-3.0 license.

2. **Commercial License**:
   - Required for integrations into proprietary, closed-source, or commercial software products.
   - Requires a commercial agreement from the copyright holder.
   - **Contact**: Mostafa Mahmoud ([mostafasensei106@gmail.com](mailto:mostafasensei106@gmail.com))

For detailed terms, please check the [LICENSE](LICENSE) file.

<p align="center">
  Made with ❤️ by <a href="https://github.com/MostafaSensei106">MostafaSensei106</a>
</p>
