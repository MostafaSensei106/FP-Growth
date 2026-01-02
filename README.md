<h1 align="center">FP-Growth</h1>
<p align="center">
  <img src="https://socialify.git.ci/MostafaSensei106/FP-Growth/image?font=KoHo&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F138288138%3Fv%3D4&name=1&owner=1&pattern=Floating+Cogs&theme=Light" alt="Banner">
</p>

<p align="center">
  <strong>A high-performance Dart library for the FP-Growth algorithm and association rule mining.</strong><br>
  Efficiently discover frequent patterns and generate insightful association rules from your data.
</p>

<p align="center">
  <a href="#-about">About</a> •
  <a href="#-features">Features</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-cli-usage">CLI</a> •
  <a href="#-contributing">Contributing</a> •
  <a href="#-license">License</a>
</p>

---

## 📖 About

Welcome to **FP-Growth for Dart** — a robust and efficient library for implementing the FP-Growth algorithm. This package is designed to help you discover frequent itemsets and generate association rules from transactional datasets. It's an essential tool for tasks like market basket analysis, user behavior prediction, and understanding relationships within large data collections.

Built with performance and ease of use in mind, `fp_growth` provides a comprehensive, scalable, and parallelized solution for pattern mining in Dart and Flutter applications.

---

## ✨ Features

### Core Algorithm & Functionality

- **FP-Growth Algorithm**: A complete and optimized implementation of the Frequent Pattern Growth algorithm.
- **FP-Tree Construction**: Efficiently builds a compressed FP-Tree to represent transactional data.
- **Header Table**: Utilizes a header table for quick access and traversal of item nodes within the tree.
- **Optimized Mining**: Features a recursive mining approach with dynamic pruning and a **single-path optimization** for faster pattern discovery.
- **Association Rule Generation**: Extracts all possible association rules from frequent itemsets.
  - Calculates key metrics: `Support`, `Confidence`, `Lift`, `Leverage`, and `Conviction`.

### 🛠️ Performance & Scalability

- **Parallel Processing**: Harnesses the power of multiple CPU cores by using a **fixed-size Isolate Pool** to parallelize the mining process, efficiently speeding up analysis on large datasets without the overhead of spawning new isolates for every task.
- **Memory-Optimized Two-Pass Architecture**: Built to handle massive datasets. The algorithm processes transactions in two efficient passes, calculating frequencies first and then building the FP-Tree, without holding the entire transaction list in memory during the recursive mining process. This design drastically reduces peak memory usage.
- **Efficient Data Structures**: Employs internal integer mapping for items and uses weighted conditional FP-Trees to dramatically reduce memory usage and improve processing speed during recursive mining steps.

### ⚙️ Utilities

- **CSV Data Adapter**: Easily load transactional data directly from CSV files using modern stream-based parsers.
- **Data Exporters**: Export frequent itemsets and association rules to `JSON`, `CSV`, or formatted `Text`.
- **Command-Line Interface (CLI)**: A powerful and user-friendly CLI tool for performing analysis directly from your terminal, with support for parallelism, large files, and multiple output formats.

---

## 📦 Installation

1.  Add this to your package's `pubspec.yaml` file:

    ```yaml
    dependencies:
      fp_growth: ^1.0.3 # Replace with the latest version
    ```

2.  Install it from your terminal:

    ```bash
    dart pub get
    ```

    or for Flutter projects:

    ```bash
    flutter pub get
    ```

---

## 🚀 Usage

This library provides a two-step process for market basket analysis:

1.  **Mine Frequent Itemsets**: Discover which groups of items appear together frequently.
2.  **Generate Association Rules**: Create rules (`{A} => {B}`) from those itemsets to uncover actionable insights.

### 1. Mining Frequent Itemsets

First, find frequent itemsets from your data source.

> **Which mining API should I use?**
>
> - **In-memory `List`?** ➡️ Use `fpGrowth.mineFromList()` (easiest).
> - **CSV file?** ➡️ Use `fpGrowth.mineFromCsv()` (recommended for large files).
> - **Database or custom source?** ➡️ Use `fpGrowth.mine()` with a stream provider (advanced).

#### Example: From an In-Memory List

```dart
import 'package:fp_growth/fp_growth.dart';

final transactions = [
  ['bread', 'milk'],
  ['bread', 'diaper', 'beer', 'eggs'],
  ['milk', 'diaper', 'beer', 'cola'],
];

// Instantiate FPGrowth and find itemsets with a minimum support of 2.
final fpGrowth = FPGrowth<String>(minSupport: 2);
final (frequentItemsets, totalTransactions) = await fpGrowth.mineFromList(transactions);

// frequentItemsets is a Map<List<String>, int>
// totalTransactions is an int
```

### 2. Generating Association Rules

Once you have the frequent itemsets, you can generate association rules. The `RuleGenerator` class takes the frequent itemsets and the total transaction count to calculate metrics like confidence and lift.

```dart
import 'package:fp_growth/fp_growth.dart';

// (Continuing from the previous example...)

// 1. Setup the RuleGenerator
final generator = RuleGenerator<String>(
  minConfidence: 0.7, // 70%
  frequentItemsets: frequentItemsets,
  totalTransactions: totalTransactions,
);

// 2. Generate the rules
final rules = generator.generateRules();

// 3. Print the rules and their metrics
for (final rule in rules) {
  print(rule.formatWithMetrics());
  // Example Output:
  // {beer} => {diaper} [sup: 0.667, conf: 1.000, lift: 1.50, lev: 0.222, conv: ∞]
}
```

### Other Data Sources

#### From a CSV File

For large files, `mineFromCsv` is the most memory-efficient option. It requires importing `package:fp_growth/fp_growth_io.dart` and is not available on the web.

```dart
import 'dart:io';
import 'package:fp_growth/fp_growth_io.dart'; // Note the IO-specific import!

Future<void> processLargeFile(String filePath) async {
  final fpGrowth = FPGrowth<String>(
    minSupport: 500,
    parallelism: Platform.numberOfProcessors,
  );

  final (itemsets, count) = await fpGrowth.mineFromCsv(filePath);

  // Now you can generate rules with the `itemsets` and `count`.
  print('Found ${itemsets.length} frequent itemsets in $count transactions.');
}
```

#### From a Custom Stream

For databases or other custom sources, use the core `mine` method with a **stream provider function** (`Stream<List<T>> Function()`). This function must return a _new stream_ each time it's called.

```dart
import 'dart:async';
import 'package:fp_growth/fp_growth.dart';

Future<void> useCustomStream() async {
  Stream<List<String>> streamProvider() => Stream.fromIterable([
    ['a', 'b', 'c'], ['a', 'b'], ['b', 'c'], ['a', 'c'],
  ]);

  final fpGrowth = FPGrowth<String>(minSupport: 2);
  final (itemsets, count) = await fpGrowth.mine(streamProvider);

  // Generate rules with the `itemsets` and `count`.
  print('Found ${itemsets.length} itemsets in $count transactions.');
}
```

---

## 📋 CLI Usage

The `fp_growth` package includes a command-line interface (CLI) tool for quick analysis of CSV files without writing any Dart code. It's designed to handle large files by streaming data.

### Prerequisites

Create a CSV file (e.g., `data.csv`) where each line represents a transaction, and items are comma-separated.

```csv
bread,milk
bread,diaper,beer,eggs
milk,diaper,beer,cola
```

### Running the CLI

Execute the CLI tool using `dart run`. You can specify the minimum support, confidence, and an output file.

```bash
# Run analysis and print to console
dart run fp_growth --input data.csv --minSupport 0.6 --minConfidence 0.7

# Save results to a JSON file
dart run fp_growth -i data.csv -s 3 -c 0.7 -o results.json -f json

# Save results to a CSV file
dart run fp_growth -i data.csv -s 3 -c 0.7 --output-file results.csv --output-format csv
```

### Options

| Flag              | Abbreviation | Description                                                               | Default |
| ----------------- | ------------ | ------------------------------------------------------------------------- | ------- |
| `--input`         | `-i`         | (Mandatory) Path to the input CSV file.                                   |         |
| `--minSupport`    | `-s`         | Minimum support as a percentage (`0.05`) or an absolute count (`5`).      | `0.05`  |
| `--minConfidence` | `-c`         | Minimum confidence threshold for association rules.                       | `0.7`   |
| `--output-file`   | `-o`         | Path to an output file to save results.                                   | `null`  |
| `--output-format` | `-f`         | Output format (`json` or `csv`). Only used if `output-file` is specified. | `json`  |
| `--log-level`     |              | Set the logging level (`debug`, `info`, `warning`, `error`, `none`).      | `info`  |
| `--parallelism`   | `-p`         | Number of isolates to use for parallel processing.                        | `1`     |

---

## ⚡ Performance

The `fp_growth` library is optimized for both speed and memory efficiency. The following benchmarks were run on an **AMD Ryzen™ 7 5800H (16 Threads)** with a dataset of **1,000,000 transactions** and a minimum support of 0.05. The results highlight the performance improvements of the new implementation (v1.0.3) compared to the older version (v1.0.2).

**Old Benchmark (v1.0.2):**

**Averaged Execution Time:** ~2.73 seconds (single-threaded, file-based).

### 🚀 New Benchmark Results (v1.0.3)

| API Method                        | Execution Time | Speed vs. v1.0.2 | Memory Usage (Delta) | Notes                                                 |
| --------------------------------- | -------------- | ---------------- | -------------------- | ----------------------------------------------------- |
| **In-Memory (`mineFromList`)**    | **1.46 s**     | **1.87× faster** | **+28.4 MB**         | Fastest execution, requires full dataset in RAM.      |
| **CSV Streaming (`mineFromCsv`)** | **2.32 s**     | **1.18× faster** | **-0.70 MB**         | Minimal memory footprint, ideal for very large files. |
| **Custom Stream (`mine`)**        | **1.82 s**     | **1.50× faster** | Not measured         | Flexible streaming for custom data sources.           |

---

## 🤝 Contributing

Contributions are welcome! Here’s how to get started:

1.  Fork the repository.
2.  Create a new branch:
    `git checkout -b feature/YourFeature`
3.  Commit your changes:
    `git commit -m "Add amazing feature"`
4.  Push to your branch:
    `git push origin feature/YourFeature`
5.  Open a pull request.

> 💡 Please read our (soon-to-be-added) **Contributing Guidelines** and open an issue first for major feature ideas or changes.

---

## 📜 License

This project is licensed under the **GPL-3.0 License**.
See the [LICENSE](LICENSE) file for full details.

<p align="center">
  Made with ❤️ by <a href="https://github.com/MostafaSensei106">MostafaSensei106</a>
</p>
