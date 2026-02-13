import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dhan_mitra/components/models/nav_cache.dart';
import 'package:firebase_auth/firebase_auth.dart';


class MutualFundService {
  final String uid =
      FirebaseAuth.instance.currentUser!.uid;

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  late final DocumentReference<Map<String, dynamic>>
  _userRef =
  _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>>
  get _txnRef =>
      _userRef.collection('mf_transactions');

  // =====================================================
  // ===================== BUY FUND ======================
  // =====================================================

  Future<void> buyFund({
    required String fundId,
    required int amount,
  }) async {
    if (amount <= 0) {
      throw Exception("Invalid investment amount");
    }

    // 🔥 Load NAV cache once (10 min throttle)
    await NavCache.loadNAVs();

    final nav = NavCache.getNAV(fundId);

    if (nav == null) {
      throw Exception("Fund not found");
    }

    final double units = amount / nav;

    await _db.runTransaction((txn) async {
      final userSnap =
      await txn.get(_userRef);

      if (!userSnap.exists) {
        throw Exception("User not found");
      }

      final userData = userSnap.data()!;
      final wallet =
      Map<String, dynamic>.from(
          userData['wallet'] ?? {});

      final bool locked =
          wallet['locked'] ?? false;

      final int balance =
          (wallet['balance'] as num?)
              ?.toInt() ??
              0;

      if (locked) {
        throw Exception("Wallet locked");
      }

      if (balance < amount) {
        throw Exception(
            "Insufficient balance");
      }

      final holding =
      userData['mfPortfolio']?[fundId];

      // 🔒 LOCK WALLET
      txn.update(_userRef, {
        'wallet.locked': true,
      });

      if (holding == null) {
        txn.update(_userRef, {
          'wallet.balance':
          FieldValue.increment(-amount),
          'mfPortfolio.$fundId': {
            'fundId': fundId,
            'units': double.parse(
                units.toStringAsFixed(4)),
            'investedAmount':
            amount.toDouble(),
            'updatedAt':
            FieldValue.serverTimestamp(),
          },
        });
      } else {
        txn.update(_userRef, {
          'wallet.balance':
          FieldValue.increment(-amount),
          'mfPortfolio.$fundId.units':
          FieldValue.increment(
              double.parse(
                  units.toStringAsFixed(4))),
          'mfPortfolio.$fundId.investedAmount':
          FieldValue.increment(amount),
          'mfPortfolio.$fundId.updatedAt':
          FieldValue.serverTimestamp(),
        });
      }

      // 🔓 UNLOCK WALLET
      txn.update(_userRef, {
        'wallet.locked': false,
        'updatedAt':
        FieldValue.serverTimestamp(),
      });

      txn.set(_txnRef.doc(), {
        'type': 'buy',
        'fundId': fundId,
        'amount': amount,
        'nav': nav,
        'units': double.parse(
            units.toStringAsFixed(4)),
        'createdAt':
        FieldValue.serverTimestamp(),
      });
    });
  }

  // =====================================================
  // ===================== SELL FUND =====================
  // =====================================================

  Future<void> sellFund({
    required String fundId,
    required double units,
  }) async {
    if (units <= 0) {
      throw Exception("Invalid units");
    }

    await NavCache.loadNAVs();

    final nav = NavCache.getNAV(fundId);

    if (nav == null) {
      throw Exception("Fund not found");
    }

    final double redeemAmount =
        units * nav;

    await _db.runTransaction((txn) async {
      final userSnap =
      await txn.get(_userRef);

      if (!userSnap.exists) {
        throw Exception("User not found");
      }

      final userData = userSnap.data()!;
      final holding =
      userData['mfPortfolio']?[fundId];

      if (holding == null) {
        throw Exception(
            "No holdings found");
      }

      final double oldUnits =
      (holding['units'] as num)
          .toDouble();

      if (units > oldUnits) {
        throw Exception(
            "Not enough units");
      }

      final double remainingUnits =
          oldUnits - units;

      if (remainingUnits <= 0.0001) {
        txn.update(_userRef, {
          'mfPortfolio.$fundId':
          FieldValue.delete(),
        });
      } else {
        txn.update(_userRef, {
          'mfPortfolio.$fundId.units':
          double.parse(
              remainingUnits
                  .toStringAsFixed(4)),
          'mfPortfolio.$fundId.updatedAt':
          FieldValue.serverTimestamp(),
        });
      }

      txn.update(_userRef, {
        'wallet.balance':
        FieldValue.increment(
            redeemAmount.round()),
        'updatedAt':
        FieldValue.serverTimestamp(),
      });

      txn.set(_txnRef.doc(), {
        'type': 'sell',
        'fundId': fundId,
        'units': double.parse(
            units.toStringAsFixed(4)),
        'nav': nav,
        'amount': double.parse(
            redeemAmount
                .toStringAsFixed(2)),
        'createdAt':
        FieldValue.serverTimestamp(),
      });
    });
  }

  // =====================================================
  // ======================= STREAMS =====================
  // =====================================================

  Stream<Map<String, dynamic>>
  portfolioStream() {
    return _userRef.snapshots().map((doc) {
      if (!doc.exists) return {};
      return Map<String, dynamic>.from(
          doc.data()?['mfPortfolio'] ?? {});
    });
  }

  Stream<QuerySnapshot<
      Map<String, dynamic>>>
  transactionStream() {
    return _txnRef
        .orderBy('createdAt',
        descending: true)
        .snapshots();
  }
}
