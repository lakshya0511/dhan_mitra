import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TradingService {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final DocumentReference _userRef =
  _db.collection('users').doc(uid);

  CollectionReference get _tradeTxnRef =>
      _userRef.collection('trade_transactions');

  // ================= AUTO UNLOCK TRADING =================
  // Call this once on dashboard load / app start

  Future<void> autoUnlockTradingIfEligible() async {
    await _db.runTransaction((txn) async {
      final snap = await txn.get(_userRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      // Already unlocked → stop
      if (data['trading']?['unlocked'] == true) return;

      final Map<String, dynamic> lessonProgress =
      Map<String, dynamic>.from(data['lessonProgress'] ?? {});

      if (lessonProgress.isEmpty) return;

      // ✅ Check all mandatory lessons completed
      final bool allMandatoryCompleted =
      lessonProgress.values.every((lesson) {
        if (lesson['isMandatory'] == true) {
          return lesson['completedAt'] != null;
        }
        return true;
      });

      if (!allMandatoryCompleted) return;

      final wallet = data['wallet'] as Map<String, dynamic>;
      final double currentBalance =
          (wallet['balance'] as num?)?.toDouble() ?? 0.0;


      txn.update(_userRef, {
        'trading': {
          'unlocked': true,
          'unlockedAt': FieldValue.serverTimestamp(),
        },
        'wallet.balance': currentBalance + 10000,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ================= BUY STOCK =================

  Future<void> buyStock({
    required String symbol,
    required int quantity,
    required double price, // paisa
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than zero');
    }

    final double totalCost = price * quantity;

    await _db.runTransaction((txn) async {
      final snap = await txn.get(_userRef);
      if (!snap.exists) {
        throw Exception('User not found');
      }

      final data = snap.data() as Map<String, dynamic>;

      if (data['trading']?['unlocked'] != true) {
        throw Exception('Trading not unlocked');
      }

      final wallet = data['wallet'] as Map<String, dynamic>;
      final double balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;


      // ❌ HARD STOP: insufficient balance
      if (balance < totalCost) {
        throw Exception('Insufficient paisa');
      }

      final Map<String, dynamic> portfolio =
      Map<String, dynamic>.from(data['portfolio'] ?? {});

      final holding =
      portfolio[symbol] as Map<String, dynamic>?;

      int newQty = quantity;
      double newInvested = totalCost;
      double avgBuyPrice = price;

      if (holding != null) {
        final int oldQty = (holding['quantity'] as num).toInt();
        final double oldInvested =
        (holding['investedAmount'] as num).toDouble();

        newQty = oldQty + quantity;
        newInvested = oldInvested + totalCost;

        // ✅ FIX: explicit int conversion
        avgBuyPrice = (newInvested / newQty);
      }
      portfolio[symbol] = {
        'symbol': symbol,
        'quantity': newQty,
        'avgBuyPrice': avgBuyPrice,
        'investedAmount': newInvested,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      txn.update(_userRef, {
        'wallet.balance': balance - totalCost,
        'portfolio': portfolio,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      txn.set(_tradeTxnRef.doc(), {
        'symbol': symbol,
        'type': 'buy',
        'quantity': quantity,
        'price': price,
        'totalAmount': totalCost,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ================= SELL STOCK =================

  Future<void> sellStock({
    required String symbol,
    required int quantity,
    required double price, // paisa
  }) async {
    if (quantity <= 0) {
      throw Exception('Quantity must be greater than zero');
    }

    final double totalAmount = price * quantity;

    await _db.runTransaction((txn) async {
      final snap = await txn.get(_userRef);
      if (!snap.exists) {
        throw Exception('User not found');
      }

      final data = snap.data() as Map<String, dynamic>;
      final Map<String, dynamic> portfolio =
      Map<String, dynamic>.from(data['portfolio'] ?? {});

      final holding =
      portfolio[symbol] as Map<String, dynamic>?;

      if (holding == null) {
        throw Exception('No holdings for $symbol');
      }

      final int oldQty = holding['quantity'];
      if (oldQty < quantity) {
        throw Exception('Not enough quantity');
      }

      final double avgBuy =
      (holding['avgBuyPrice'] as num).toDouble();
      final int remainingQty = oldQty - quantity;
      final double remainingInvested = remainingQty * avgBuy;

      if (remainingQty == 0) {
        portfolio.remove(symbol);
      } else {
        portfolio[symbol] = {
          'symbol': symbol,
          'quantity': remainingQty,
          'avgBuyPrice': avgBuy,
          'investedAmount': remainingInvested,
          'updatedAt': FieldValue.serverTimestamp(),
        };
      }

      final wallet = data['wallet'] as Map<String, dynamic>;
      final double balance = (wallet['balance'] as num?)?.toDouble() ?? 0.0;


      txn.update(_userRef, {
        'wallet.balance': balance + totalAmount,
        'portfolio': portfolio,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      txn.set(_tradeTxnRef.doc(), {
        'symbol': symbol,
        'type': 'sell',
        'quantity': quantity,
        'price': price,
        'totalAmount': totalAmount,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ================= STREAMS =================

  Stream<Map<String, dynamic>> portfolioStream() {
    return _userRef.snapshots().map((doc) {
      if (!doc.exists) return {};
      return Map<String, dynamic>.from(doc['portfolio'] ?? {});
    });
  }

  Stream<QuerySnapshot> tradeHistoryStream() {
    return _tradeTxnRef
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<bool> tradingUnlockedStream() {
    return _userRef.snapshots().map((doc) {
      if (!doc.exists) return false;
      return doc['trading']?['unlocked'] == true;
    });
  }
}
