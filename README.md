<h1 align="center">FP-Growth for Dart</h1>
<p align="center">
  <img src="https://socialify.git.ci/MostafaSensei106/fp_growth/image?description=1&font=KoHo&language=1&logo=https%3A%2F%2Fraw.githubusercontent.com%2FMostafaSensei106%2Ffp_growth%2Fmain%2F.github%2Flogo.svg&owner=1&pattern=Floating+Cogs&theme=Dark" alt="fpgrowth_dart Banner">
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

- **Parallel Processing**: Harnesses the power of multiple CPU cores by using **Isolates** to parallelize the mining process, significantly speeding up analysis on large datasets.
- **Stream Processing**: Built to handle massive datasets that don't fit in memory. The `StreamProcessor` allows you to process transaction data as a stream, ensuring a low and constant memory footprint.
- **Memory Efficiency**: Employs internal integer mapping for items to dramatically reduce memory usage and improve processing speed.

### ⚙️ Utilities

- **CSV Data Adapter**: Easily load transactional data directly from CSV files.
- **Data Exporters**: Export frequent itemsets and association rules to `JSON`, `CSV`, or formatted `Text`.
- **Command-Line Interface (CLI)**: A powerful and user-friendly CLI tool for performing analysis directly from your terminal, now with support for streaming large files and multiple output formats.

---

## 📦 Installation

1.  Add this to your package's `pubspec.yaml` file:

    ```yaml
    dependencies:
      fp_growth: ^1.0.0 # Replace with the latest version
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

### Quick Start

Import the library and start mining patterns in just a few lines of code.

```dart
import 'package:fp_growth/fp_growth.dart';

Future<void> main() async {
  // 1. Define your transactions
  final transactions = [
    ['bread', 'milk'],
    ['bread', 'diaper', 'beer', 'eggs'],
    ['milk', 'diaper', 'beer', 'cola'],
    ['bread', 'milk', 'diaper', 'beer'],
    ['bread', 'milk', 'diaper', 'cola'],
  ];
  final totalTransactions = transactions.length;

  // 2. Instantiate FPGrowth with a minimum support threshold
  // minSupport can be a percentage (0.0-1.0) or an absolute count (e.g., 3).
  final fpGrowth = FPGrowth<String>(minSupport: 3);

  // 3. Add transactions and mine for frequent itemsets
  fpGrowth.addTransactions(transactions);
  final frequentItemsets = await fpGrowth.mineFrequentItemsets();

  print('Frequent Itemsets:');
  frequentItemsets.forEach((itemset, support) {
    final supportPercent = (support / totalTransactions * 100).toStringAsFixed(1);
    print('  {${itemset.join(', ')}} - Support: $support ($supportPercent%)');
  });

  // 4. Generate association rules with a minimum confidence threshold
  final ruleGenerator = RuleGenerator<String>(
    minConfidence: 0.7, // 70% minimum confidence
    frequentItemsets: frequentItemsets,
    totalTransactions: totalTransactions,
  );

  final rules = ruleGenerator.generateRules();

  print('\nAssociation Rules:');
  for (final rule in rules) {
    // formatWithMetrics() provides a readable output with all key metrics.
    print('  ${rule.formatWithMetrics()}');
  }
}
```

### Streaming Data

For large datasets, use the `StreamProcessor` to avoid loading the entire file into memory.

```dart
import 'dart:async';
import 'package:fp_growth/fp_growth.dart';

Future<void> runStreamExample() async {
  // 1. Create a stream of transactions (e.g., from a file)
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

  print('Found ${frequentItemsets.length} frequent itemsets from stream.');
  // ...and generate rules as in the standard example.
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
