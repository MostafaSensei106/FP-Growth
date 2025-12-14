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
