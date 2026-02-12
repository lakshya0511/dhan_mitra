import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> submitFeedback({
    required String message,
  }) async {
    final uid = _auth.currentUser!.uid;

    final userDoc =
    await _db.collection('users').doc(uid).get();

    final userData =
        userDoc.data() as Map<String, dynamic>? ?? {};

    await _db.collection('feedback').add({
      'uid': uid,
      'name': userData['name'] ?? '',
      'email': userData['email'] ?? '',
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
