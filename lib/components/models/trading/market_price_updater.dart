import 'package:cloud_firestore/cloud_firestore.dart';
import 'market_simulator.dart';

class MarketPriceUpdater {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MarketSimulator _simulator = MarketSimulator();

  CollectionReference get _pricesRef =>
      _db.collection('market_prices');

  DocumentReference get _metaRef =>
      _db.collection('market_meta').doc('status');

  /// 🔥 Update only if cooldown passed
  Future<void> maybeUpdateMarket() async {
    final metaSnap = await _metaRef.get();
    final now = DateTime.now();

    if (metaSnap.exists) {
      final Timestamp lastTs = metaSnap['lastUpdatedAt'];
      final lastUpdate = lastTs.toDate();

      if (now.difference(lastUpdate).inSeconds < 15) return;
    }

    await _updateMarketPrices();

    await _metaRef.set({
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔄 Update all stocks from Firestore
  Future<void> _updateMarketPrices() async {
    final stocksSnap =
    await _db.collection('stocks').get();

    for (final stockDoc in stocksSnap.docs) {
      await _updateSingleStock(stockDoc);
    }
  }

  /// 📈 Simulated update
  Future<void> _updateSingleStock(
      QueryDocumentSnapshot stockDoc,
      ) async {
    final symbol = stockDoc['symbol'];

    final priceDoc = _pricesRef.doc(symbol);
    final priceSnap = await priceDoc.get();

    if (!priceSnap.exists) return;

    final double lastPrice =
    (priceSnap['price'] as num).toDouble();

    final tick = _simulator.nextTick(lastPrice);

    await priceDoc.set({
      'price': tick['price'],
      'change': tick['change'],
      'changePercent': tick['changePercent'],
      'updatedAt': FieldValue.serverTimestamp(),
      'source': 'simulated_market',
    }, SetOptions(merge: true));
  }
}
