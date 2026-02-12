import 'dart:math';

class MarketSimulator {
  final Random _random = Random();

  Map<String, double> nextTick(double lastPrice) {
    // realistic micro-movement: ±0.8%
    final double deltaPercent =
        (_random.nextDouble() * 1.6) - 0.8;

    final double newPrice =
        lastPrice * (1 + deltaPercent / 100);

    final double change = newPrice - lastPrice;
    final double changePercent =
        (change / lastPrice) * 100;

    return {
      'price': double.parse(newPrice.toStringAsFixed(2)),
      'change': double.parse(change.toStringAsFixed(2)),
      'changePercent':
      double.parse(changePercent.toStringAsFixed(2)),
    };
  }
}
