import 'dart:async';
import '../core/fp_growth.dart';

/// A class that processes transactions from a stream and adds them to an
/// [FPGrowth] instance.
///
/// This is useful for handling large datasets that may not fit into memory
/// all at once, or for processing data from a real-time source.
class StreamProcessor<T> {
  /// The FP-Growth instance to which transactions will be added.
  final FPGrowth<T> fpGrowth;

  /// Creates a stream processor that pipes transactions into the given
  /// [fpGrowth] instance.
  StreamProcessor(this.fpGrowth);

  /// Consumes the given [transactionStream] and adds each transaction
  /// to the [FPGrowth] instance.
  ///
  /// Returns a [Future] that completes when the stream has been fully consumed.
  Future<void> process(Stream<List<T>> transactionStream) async {
    await for (final transaction in transactionStream) {
      fpGrowth.addTransactions([transaction]);
    }
  }
}
