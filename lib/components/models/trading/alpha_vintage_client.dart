import 'dart:convert';
import 'package:http/http.dart' as http;
import 'market_price_model.dart';

class AlphaVantageClient {
  static const String _baseUrl =
      'https://www.alphavantage.co/query';

  static const String _apiKey =
      'YOUR_ALPHA_VANTAGE_API_KEY';

  Future<MarketPrice?> fetchPrice(String symbol) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl'
            '?function=GLOBAL_QUOTE'
            '&symbol=$symbol'
            '&apikey=$_apiKey',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final quote = data['Global Quote'];
      if (quote == null || quote.isEmpty) return null;

      final price =
      double.tryParse(quote['05. price'] ?? '');
      final change =
      double.tryParse(quote['09. change'] ?? '');
      final changePercentRaw =
          quote['10. change percent'] ?? '0%';

      if (price == null || change == null) return null;

      final changePercent = double.tryParse(
        changePercentRaw.replaceAll('%', ''),
      ) ??
          0;

      return MarketPrice(
        symbol: symbol,
        price: price,
        change: change,
        changePercent: changePercent,
      );
    } catch (_) {
      return null;
    }
  }
}
