## 1.0.3

- **BREAKING CHANGE**: The core mining API has been redesigned to support true memory-efficient streaming. The `FPGrowth.mine` method signature has changed from `mine(Iterable<List<T>>)` to `mine(Stream<List<T>> Function() streamProvider)`. This requires users to pass a function that provides a new transaction stream for each of the algorithm's two passes. The `StreamProcessor` class has been removed. See the README for updated usage.
- **Major Performance & Memory Refactoring**: Overhauled the core architecture to handle massive datasets efficiently.
- feat(api): Added `FPGrowth.mineFromList()` convenience method for easy processing of in-memory transaction lists.
- feat(api): Added `runFPGrowthOnCsv()` top-level function for directly mining CSV files with low memory usage (not available on web).
- refactor(core): Replaced in-memory processing with a **two-pass streaming model**, drastically reducing memory consumption by accepting a stream provider.
- refactor(core): Implemented a **weighted FP-Tree** for conditional tree generation, avoiding the costly duplication of transaction paths in memory.
- refactor(rules): Replaced the brute-force subset generation with an efficient **Apriori-style algorithm** for creating association rules, significantly speeding up the process for large itemsets.
- refactor(core): Implemented a fixed-size **Isolate Pool** for parallel mining, eliminating the overhead of spawning new isolates for each task and enabling true, efficient parallelism.
- chore(tests): Updated the entire test suite to align with the new stream-provider API and ensure correctness after the major refactoring.
- chore(docs): Updated documentation to reflect the new architectural changes and convenience APIs.

## 1.0.2

- test(property): Add property-based tests for input order independence and support monotonicity
- fix(core): Fix determinism issue by enforcing stable sorting for equal-frequency items
- test(stress): Add stress and scale tests (10k, 100k, single large transaction)
- docs(benchmarks): Update performance figures using compiled executables instead of dart run
- docs(readme): Update README with CLI usage and performance benchmarks
- chore(changelog): Add 1.0.2 release notes

## 1.0.1

- docs(readme): Update README with CLI usage and performance benchmarks
- refactor(fp-growth): Extract parallel mining to platform modules
  Move isolate-based parallel mining into a dedicated `parallel_runner.dart` file.
  Provide a web-specific `parallel_runner_web.dart` that falls back to single-threaded execution.
  Adjust `fp_growth.dart` to use conditional imports for platform-aware parallelism and promote internal helper functions for reuse.
- chore(changelog): Add 1.0.1 release notes

## 1.0.0

- Initial release of the **fp_growth** package.
- Implemented the full FP-Growth algorithm for frequent itemset mining.
- Added association rule generation with **Support**, **Confidence**, and **Lift** metrics.
- Introduced internal integer-item mapping for improved performance.
- Implemented **single-path optimization** in recursive mining.
- Added a CSV data adapter for loading transaction datasets.
- Developed a Command-Line Interface (CLI) for effortless dataset analysis.
- Integrated a flexible and extensible logging system.
- Refactored and reorganized the project structure for better maintainability.
- Enhanced association rules with additional metrics: **Leverage** and **Conviction**.
