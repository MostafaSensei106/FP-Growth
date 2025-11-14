<h1 align="center">FP-Growth</h1>
<p align="center">
  <!-- No image available yet, placeholder or remove -->
  <!-- <img src="https://socialify.git.ci/MostafaSensei106/Radix_Pulse/image?custom_language=Dart&font=KoHo&language=1&logo=https%3A%2F%2Favatars.githubusercontent.com%2Fu%2F138288138%3Fv%3D4&name=1&owner=1&pattern=Floating+Cogs&theme=Light" alt="fpgrowth_dart Banner"> -->
</p>

<p align="center">
  <strong>A high-performance Dart library for FP-Growth algorithm and association rule mining.</strong><br>
  Efficiently discover frequent patterns and generate insightful association rules from your data.
</p>

<p align="center">
  <a href="#about">About</a> •
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage-examples">Usage</a> •
  <a href="#technologies">Technologies</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

---

## About

Welcome to **FP-Growth** — a robust and efficient Dart library for implementing the FP-Growth algorithm. This library is designed to help you discover frequent itemsets and generate association rules from transactional datasets. It's an essential tool for tasks like market basket analysis, user behavior prediction, and understanding relationships within large data collections. Built with performance and ease of use in mind, `FP-Growth` provides a comprehensive solution for pattern mining in Dart and Flutter applications.

---

## Features

### 🌟 Core Algorithm & Functionality

- **FP-Growth Algorithm**: A complete and optimized implementation of the Frequent Pattern Growth algorithm.
- **FP-Tree Construction**: Efficiently builds a compressed FP-Tree to represent transactional data.
- **Header Table**: Utilizes a header table for quick access and traversal of item nodes within the tree.
- **Optimized Mining**: Features a recursive mining approach with dynamic pruning and a **single-path optimization** for faster pattern discovery.
- **Association Rule Generation**: Extracts all possible association rules from frequent itemsets.
  - Calculates key metrics: `Support`, `Confidence`, `Lift`, `Leverage`, and `Conviction`.

### 🛠️ Performance & Utilities

- **Memory Efficiency**: Employs internal integer mapping for items to significantly reduce memory footprint and improve processing speed.
- **CSV Data Adapter**: Easily load transactional data directly from CSV files.
- **Command-Line Interface (CLI)**: A powerful and user-friendly CLI tool for performing analysis directly from your terminal.

---

## Installation

### 📦 Add to your project

1.  Add this to your package's `pubspec.yaml` file:

    ```yaml
    dependencies:
      fp_growth: ^1.0.0 # Replace with the latest version
    ```

2.  Install it from your terminal:

    ```bash
    dart pub get
    ```

    or

    ```bash
    flutter pub get
    ```

---

## 🚀 Quick Start

Import the library and start mining patterns.

```dart
import 'package:fp_growth/fp_growth.dart';

void main() {
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
  final frequentItemsets = fpGrowth.mineFrequentItemsets();

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
  rules.forEach((rule) {
    // formatWithMetrics() provides a readable output with all key metrics.
    print('  ${rule.formatWithMetrics()}');
  });
}
```

---

## 📋 CLI Usage

The `fp_growth` package includes a command-line interface (CLI) tool for quick analysis of CSV files without writing any Dart code.

### Prerequisites

Create a CSV file (e.g., `transactions.csv`) where each line represents a transaction, and items within the transaction are comma-separated.

```csv
itemA,itemB,itemC
itemB,itemD
itemA,itemC,itemE
```

### Running the CLI

Execute the CLI tool using `dart run`:

```bash
dart run fp_growth --input transactions.csv --minSupport 0.6 --minConfidence 0.7
```

### Options

- `--input` or `-i`: (Mandatory) Path to the input CSV file.
- `--minSupport` or `-s`: Minimum support threshold. Can be a percentage (e.g., `0.05`) or an absolute count (e.g., `3`). Defaults to `0.05`.
- `--minConfidence` or `-c`: Minimum confidence threshold for association rules. Defaults to `0.7`.

The CLI will output the discovered frequent itemsets and association rules directly to your console.

---

## Technologies

| Technology        | Description                                                               |
| ----------------- | ------------------------------------------------------------------------- |
| 🧠 **Dart**       | [dart.dev](https://dart.dev) — The core language for the library.         |
| 📦 **args**       | `package:args` — Used for parsing command-line arguments in the CLI tool. |
| 📄 **csv**        | `package:csv` — Provides robust CSV parsing capabilities for data input.  |
| 📚 **collection** | `package:collection` — Provides utility functions for collections.        |

---

## Contributing

Contributions are welcome! Here’s how to get started:

1.  Fork the repository.
2.  Create a new branch:
    `git checkout -b feature/YourFeature`
3.  Commit your changes:
    `git commit -m "Add amazing feature"`
4.  Push to your branch:
    `git push origin feature/YourFeature`
5.  Open a pull request.

> 💡 Please read our [Contributing Guidelines](./CONTRIBUTING.md) and open an issue first for major feature ideas or changes.

---

## License

This project is licensed under the **GPL-V3.0 License**.
See the [LICENSE](LICENSE) file for full details.

<p align="center">
  Made with ❤️ by <a href="https://github.com/MostafaSensei106">MostafaSensei106</a>
</p>
