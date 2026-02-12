import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  final CollectionReference users =
  FirebaseFirestore.instance.collection('users');

  // ================= USER PROFILE =================

  Future<void> createOrUpdateUser({
    required String name,
    required String email,
    required String phone,
    required String city,
    required String gender,
  }) async {
    await users.doc(uid).set({
      // Identity
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'gender':gender,
      'photoUrl': null,

      // User Type
      'userType': 'professional',

      // Role & Status
      'role': 'user',
      'status': 'active',

      // Onboarding
      'onboarding': {
        'completed': false,
        'step': 1,
        'profileStrength': 30,
      },

      // Wallet
      'wallet': {
        'balance': 0,
        'points': 0,
        'locked': false,
        'redeemedOffers': [],
      },

      // Trading
      'trading': {
        'unlocked': false,
        'unlockedAt': null,
      },

      // Portfolio
      'portfolio': {},

      // Compliance
      'consents': {
        'termsAccepted': true,
        'privacyAccepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      },

      // Metadata
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


  // ================= STREAMS =================

  Stream<DocumentSnapshot> userStream() {
    return users.doc(uid).snapshots();
  }
  Stream<double> walletBalanceStream() {
    return users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0.0;

      return ((doc['wallet']?['balance'] ?? 0) as num).toDouble();
    });
  }
  Stream<int> pointsStream() {
    return users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 0;
      return (doc['wallet']?['points'] ?? 0) as int;
    });
  }

  Stream<String> roleStream() {
    return users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return 'user';
      return (doc['role'] ?? 'user') as String;
    });
  }

  // ================= WALLET =================

  Future<void> creditWallet({
    required int amount,
    required String reason,
    String? referenceId,
  }) async {
    final userRef = users.doc(uid);
    final txnRef = userRef.collection('wallet_transactions').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw Exception("User not found");

      final wallet = snapshot['wallet'];
      if (wallet['locked'] == true) {
        throw Exception("Wallet locked");
      }

      transaction.update(userRef, {
        'wallet.balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(txnRef, {
        'type': 'credit',
        'amount': amount,
        'reason': reason,
        'referenceId': referenceId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> debitWallet({
    required int amount,
    required String reason,
    String? referenceId,
  }) async {
    final userRef = users.doc(uid);
    final txnRef = userRef.collection('wallet_transactions').doc();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw Exception("User not found");

      final wallet = snapshot['wallet'];
      final int balance = wallet['balance'] ?? 0;

      if (wallet['locked'] == true || balance < amount) {
        throw Exception("Insufficient balance");
      }

      transaction.update(userRef, {
        'wallet.balance': FieldValue.increment(-amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(txnRef, {
        'type': 'debit',
        'amount': amount,
        'reason': reason,
        'referenceId': referenceId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<QuerySnapshot> walletTransactionsStream() {
    return users
        .doc(uid)
        .collection('wallet_transactions')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ================= REWARDS (NEW) =================

  Future<void> claimReward({
    required String rewardId,
    required int costPoints,
    required int paisaReward,
  }) async {
    final userRef = users.doc(uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      if (!snap.exists) throw Exception("User not found");

      final wallet = Map<String, dynamic>.from(snap['wallet']);
      final int points = wallet['points'] ?? 0;
      final List redeemed =
      List<String>.from(wallet['redeemedOffers'] ?? []);

      if (redeemed.contains(rewardId)) {
        throw Exception("Reward already claimed");
      }

      if (points < costPoints) {
        throw Exception("Not enough points");
      }

      redeemed.add(rewardId);

      tx.update(userRef, {
        'wallet.points': FieldValue.increment(-costPoints),
        'wallet.balance': FieldValue.increment(paisaReward),
        'wallet.redeemedOffers': redeemed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
