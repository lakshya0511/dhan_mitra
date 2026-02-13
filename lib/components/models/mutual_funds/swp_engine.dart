import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dhan_mitra/components/models/nav_cache.dart';
import 'mutual_fund_database.dart';

class SWPEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> processSWP() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);

    // 🔥 Fetch active SWPs
    final swpSnap = await userRef
        .collection('mf_swp')
        .where('isActive', isEqualTo: true)
        .get();

    if (swpSnap.docs.isEmpty) {
      await userRef.update({
        'mfSwpStats.activeCount': 0,
      });
      return;
    }

    final now = DateTime.now();

    // 🔥 Load NAV cache once
    await NavCache.loadNAVs();

    // 🔥 Fetch portfolio ONCE
    final userSnap = await userRef.get();
    final portfolio =
    Map<String, dynamic>.from(userSnap.data()?['mfPortfolio'] ?? {});

    double totalDeltaWithdrawn = 0;

    for (final doc in swpSnap.docs) {
      final data = doc.data();

      final String? fundId = data['fundId'];
      final int? amount = (data['amount'] as num?)?.toInt();
      final int frequencySeconds =
          (data['frequencySeconds'] as num?)?.toInt() ?? 30;

      final int totalWithdrawals =
          (data['totalWithdrawals'] as num?)?.toInt() ?? 0;

      final int completed =
          (data['withdrawalsCompleted'] as num?)?.toInt() ?? 0;

      final int streak =
          (data['withdrawalStreak'] as num?)?.toInt() ?? 0;

      final Timestamp? lastTs = data['lastExecutedAt'];

      if (fundId == null ||
          amount == null ||
          totalWithdrawals <= 0) {
        continue;
      }

      // 🔴 Stop if already completed
      if (completed >= totalWithdrawals) {
        await doc.reference.update({
          'isActive': false,
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        continue;
      }

      // ⏳ Time condition
      if (lastTs != null) {
        final secondsPassed =
            now.difference(lastTs.toDate()).inSeconds;

        if (secondsPassed < frequencySeconds) {
          continue;
        }
      }

      // 🔥 Get NAV
      final nav = NavCache.getNAV(fundId);
      if (nav == null || nav <= 0) continue;

      final double unitsToSell = amount / nav;

      // ====================================================
      // 🔒 HOLDING VALIDATION (CRITICAL FIX)
      // ====================================================

      final holding = portfolio[fundId];

      if (holding == null) {
        // ❌ No holdings → Stop SWP permanently
        await doc.reference.update({
          'isActive': false,
          'stoppedReason': 'No holdings available',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        continue;
      }

      final double availableUnits =
          (holding['units'] as num?)?.toDouble() ?? 0;

      if (availableUnits < unitsToSell) {
        // ❌ Not enough units → Stop SWP permanently
        await doc.reference.update({
          'isActive': false,
          'stoppedReason': 'Insufficient units',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        continue;
      }

      // ====================================================
      // ✅ SAFE TO EXECUTE SWP
      // ====================================================

      try {
        await MutualFundService().sellFund(
          fundId: fundId,
          units: unitsToSell,
        );

        totalDeltaWithdrawn += amount;

        final updatedCompleted = completed + 1;
        final updatedStreak = streak + 1;

        await doc.reference.update({
          'withdrawalsCompleted': updatedCompleted,
          'totalWithdrawn': FieldValue.increment(amount),
          'withdrawalStreak': updatedStreak,
          'lastExecutedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': updatedCompleted < totalWithdrawals,
        });

        // 🎖 BADGES
        if (updatedCompleted == 5) {
          await userRef.collection('badges').doc('swp_bronze').set({
            'title': 'Bronze Income Builder',
            'earnedAt': FieldValue.serverTimestamp(),
          });
        }

        if (updatedCompleted == 10) {
          await userRef.collection('badges').doc('swp_silver').set({
            'title': 'Silver Income Strategist',
            'earnedAt': FieldValue.serverTimestamp(),
          });
        }

        if (updatedCompleted == totalWithdrawals) {
          await userRef.collection('badges').doc('swp_completed').set({
            'title': 'SWP Master',
            'earnedAt': FieldValue.serverTimestamp(),
          });
        }

      } catch (e) {
        // 🔒 Unexpected error
        await doc.reference.update({
          'withdrawalStreak': 0,
          'missedWithdrawals': FieldValue.increment(1),
          'lastMissedAt': FieldValue.serverTimestamp(),
          'lastError': e.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // 🔥 Update summary once
    if (totalDeltaWithdrawn > 0) {
      await userRef.update({
        'mfSwpStats.totalWithdrawn':
        FieldValue.increment(totalDeltaWithdrawn),
      });
    }

    // 🔥 Recalculate active count once
    final activeSnap = await userRef
        .collection('mf_swp')
        .where('isActive', isEqualTo: true)
        .get();

    await userRef.update({
      'mfSwpStats.activeCount': activeSnap.docs.length,
    });
  }
}
