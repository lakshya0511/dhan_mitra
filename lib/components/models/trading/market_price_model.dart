class MarketPrice {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;

  MarketPrice({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
  });

  Map<String, dynamic> toMap() {
    return {
      'symbol': symbol,
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'source': 'alpha_vantage',
    };
  }
}
