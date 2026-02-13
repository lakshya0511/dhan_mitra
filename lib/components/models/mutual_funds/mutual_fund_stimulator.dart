import 'dart:math';

class MutualFundSimulator {
  final Random _random = Random();

  Map<String, double> nextNAV(double lastNAV) {
    // MF less volatile than stocks: ±0.4%
    final double deltaPercent =
        (_random.nextDouble() * 0.8) - 0.4;

    final double newNAV =
        lastNAV * (1 + deltaPercent / 100);

    final double change = newNAV - lastNAV;
    final double changePercent =
        (change / lastNAV) * 100;

    return {
      'nav': double.parse(newNAV.toStringAsFixed(2)),
      'change': double.parse(change.toStringAsFixed(2)),
      'changePercent':
      double.parse(changePercent.toStringAsFixed(2)),
    };
  }
}
