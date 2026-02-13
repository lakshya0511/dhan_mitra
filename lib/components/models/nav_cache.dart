import 'package:cloud_firestore/cloud_firestore.dart';

class NavCache {
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  static Map<String, double> _navMap = {};
  static DateTime? _lastFetch;

  static Future<void> loadNAVs() async {
    // 🔥 Prevent frequent reads
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!) <
            const Duration(minutes: 10)) {
      return;
    }

    final snap =
    await _db.collection('mf_nav').get();

    _navMap = {
      for (var doc in snap.docs)
        doc.id:
        (doc['nav'] as num).toDouble()
    };

    _lastFetch = DateTime.now();
  }

  static double? getNAV(String fundId) {
    return _navMap[fundId];
  }
}
