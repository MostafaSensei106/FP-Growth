library;

// Core FP-Growth algorithm interface.
export 'src/core/fp_growth.dart';

// Association rule generation and data structures.
export 'src/rules/association_rule.dart';
export 'src/rules/rule_generator.dart';

// Data adapters and helpers.
export 'src/utils/io_adapters.dart';
export 'src/utils/file_runner.dart'
    if (dart.library.html) 'src/utils/file_runner_noop.dart';
