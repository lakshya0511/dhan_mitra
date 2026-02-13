import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mutual_fund_database.dart';

class SIPEngine {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> processSIPs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = _db.collection('users').doc(user.uid);

    final sipSnap = await userRef
        .collection('mf_sip')
        .where('isActive', isEqualTo: true)
        .get();

    final now = DateTime.now();

    int totalExecutedAmount = 0;

    for (final doc in sipSnap.docs) {
      final data = doc.data();

      final String? fundId = data['fundId'];
      final int? amount = (data['amount'] as num?)?.toInt();
      final int frequencySeconds =
          (data['frequencySeconds'] as num?)?.toInt() ?? 30;

      final int totalInstallments =
          (data['totalInstallments'] as num?)?.toInt() ?? 0;

      final int completed =
          (data['installmentsCompleted'] as num?)?.toInt() ?? 0;

      final int streak =
          (data['sipStreak'] as num?)?.toInt() ?? 0;

      final Timestamp? lastTs = data['lastExecutedAt'];

      if (fundId == null || amount == null || totalInstallments <= 0) {
        continue;
      }

      // 🔴 Auto stop if completed
      if (completed >= totalInstallments) {
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

      try {
        await MutualFundService().buyFund(
          fundId: fundId,
          amount: amount,
        );

        totalExecutedAmount += amount;

        final updatedCompleted = completed + 1;
        final updatedStreak = streak + 1;

        await doc.reference.update({
          'installmentsCompleted': updatedCompleted,
          'totalInvested': FieldValue.increment(amount),
          'sipStreak': updatedStreak,
          'lastExecutedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': updatedCompleted < totalInstallments,
        });

        // 🎖 Badges
        if (updatedCompleted == 5) {
          await userRef.collection('badges').doc('sip_bronze').set({
            'title': 'Bronze Investor',
            'earnedAt': FieldValue.serverTimestamp(),
          });
        }

        if (updatedCompleted == 10) {
          await userRef.collection('badges').doc('sip_silver').set({
            'title': 'Silver Wealth Builder',
            'earnedAt': FieldValue.serverTimestamp(),
          });
        }

        if (updatedCompleted == totalInstallments) {
          await userRef.collection('badges').doc('sip_completed').set({
            'title': 'SIP Master',
            'earnedAt': FieldValue.serverTimestamp(),
          });
        }

      } catch (e) {
        await doc.reference.update({
          'sipStreak': 0,
          'missedInstallments': FieldValue.increment(1),
          'lastMissedAt': FieldValue.serverTimestamp(),
          'lastError': e.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // 🔥 Update user summary ONCE
    if (totalExecutedAmount > 0) {
      await userRef.update({
        'mfSipStats.totalInvested':
        FieldValue.increment(totalExecutedAmount),
      });
    }

    // 🔥 Recalculate active count ONCE
    final activeSnap = await userRef
        .collection('mf_sip')
        .where('isActive', isEqualTo: true)
        .get();

    await userRef.update({
      'mfSipStats.activeCount': activeSnap.docs.length,
    });
  }
}
