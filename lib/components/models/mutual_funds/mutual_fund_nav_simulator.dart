import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhan_mitra/components/models/mutual_funds/mutual_fund_stimulator.dart';

class MutualFundNAVUpdater {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final MutualFundSimulator _simulator =
  MutualFundSimulator();

  CollectionReference get _navRef =>
      _db.collection('mf_nav');

  Future<void> updateAllNAV() async {
    final snapshot = await _navRef.get();

    for (final doc in snapshot.docs) {
      final double lastNAV =
      (doc['nav'] as num).toDouble();

      final tick =
      _simulator.nextNAV(lastNAV);

      await doc.reference.update({
        'nav': tick['nav'],
        'change': tick['change'],
        'changePercent':
        tick['changePercent'],
        'updatedAt':
        FieldValue.serverTimestamp(),
      });
    }
  }
}
