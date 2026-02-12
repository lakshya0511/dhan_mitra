import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LearningService {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late final DocumentReference _userRef =
  _db.collection('users').doc(uid);

  // ================= INTERNAL =================

  Future<DocumentSnapshot<Map<String, dynamic>>> _getUserSnap() {
    return _userRef.get()
    as Future<DocumentSnapshot<Map<String, dynamic>>>;
  }

  /// Source of truth for lesson points
  Future<int> _getLessonPoints(String lessonId) async {
    final snap =
    await _db.collection('lessons').doc(lessonId).get();
    if (!snap.exists) return 0;

    final data = snap.data()!;
    return (data['points'] as num?)?.toInt() ?? 0;
  }

  // ================= WALLET TRANSACTION =================

  Future<void> _applyPaisa({
    required int amount,
    required String reason,
    required String referenceId,
  }) async {
    /*
    if (amount == 0) return;

    final txnRef =
    _userRef.collection('wallet_transactions').doc();

    await _db.runTransaction((txn) async {
      final snap = await txn.get(_userRef);
      if (!snap.exists) return;

      final wallet = snap['wallet'];
      if (wallet['locked'] == true) {
        throw Exception('Wallet is locked');
      }

      txn.update(_userRef, {
        'wallet.balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      txn.set(txnRef, {
        'type': amount > 0 ? 'credit' : 'debit',
        'amount': amount.abs(),
        'reason': reason,
        'referenceId': referenceId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    */
    return;
  }

  // ================= LESSON INIT =================

  Future<void> initLesson({
    required String lessonId,
    required String sectionId,
    required int totalVideoSeconds,
    required bool isMandatory,
    required int points,
  }) async {
    final snap = await _getUserSnap();
    if (!snap.exists) return;

    final data = snap.data()!;
    final lessonProgress =
        data['lessonProgress'] as Map<String, dynamic>? ?? {};

    if (lessonProgress.containsKey(lessonId)) return;

    await _userRef.update({
      'lessonProgress.$lessonId': {
        'lessonId': lessonId,
        'sectionId': sectionId,
        'isMandatory': isMandatory,
        'pointsCredited': false,
        'startedAt': FieldValue.serverTimestamp(),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
        'video': {
          'watchedSeconds': 0,
          'totalSeconds': totalVideoSeconds,
          'isCompleted': false,
        },
        'quiz': {
          'answers': {},
          'reflections': {},
        },
        'score': null,
        'completedAt': null,
      }
    });
  }

  // ================= VIDEO PROGRESS (FIXED PROPERLY) =================

  Future<void> updateVideoProgress({
    required String lessonId,
    required int watchedSeconds,
    required int totalSeconds,
  }) async {
    final snap = await _getUserSnap();
    if (!snap.exists) return;

    final data = snap.data()!;
    final lesson = data['lessonProgress']?[lessonId];
    if (lesson == null) return;

    final video = lesson['video'];
    if (video == null) return;

    final int previous =
    (video['watchedSeconds'] ?? 0) as int;

    final int safeWatched =
    watchedSeconds > previous ? watchedSeconds : previous;

    // ✅ COMPLETE ONLY WHEN FULL VIDEO IS WATCHED
    final bool completed =
        totalSeconds > 0 && safeWatched >= totalSeconds;

    await _userRef.update({
      'lessonProgress.$lessonId.video.watchedSeconds':
      safeWatched,
      'lessonProgress.$lessonId.video.isCompleted':
      completed,
      'lessonProgress.$lessonId.lastUpdatedAt':
      FieldValue.serverTimestamp(),
      if (completed)
        'lessonProgress.$lessonId.video.completedAt':
        FieldValue.serverTimestamp(),
    });
  }

  // ================= DECISION ANSWER =================

  Future<void> saveDecisionAnswer({
    required String lessonId,
    required String questionId,
    required String selectedOption,
    required String outcomeText,
    required int paisaAmount,
  }) async {
    final snap = await _getUserSnap();
    if (!snap.exists) return;

    final data = snap.data()!;
    final answers =
        data['lessonProgress']?[lessonId]?['quiz']?['answers'] ?? {};

    if (answers.containsKey(questionId)) return;

    await _userRef.update({
      'lessonProgress.$lessonId.quiz.answers.$questionId': {
        'type': 'decision',
        'selectedOption': selectedOption,
        'outcome': outcomeText,
        'paisa': paisaAmount,
        'answeredAt': FieldValue.serverTimestamp(),
      },
      'lessonProgress.$lessonId.lastUpdatedAt':
      FieldValue.serverTimestamp(),
    });
  }

  // ================= DECISION REFLECTION =================

  Future<void> saveDecisionReflection({
    required String lessonId,
    required String questionId,
    required String answer,
  }) async {
    final snap = await _getUserSnap();
    if (!snap.exists) return;

    final data = snap.data()!;
    final reflections =
        data['lessonProgress']?[lessonId]?['quiz']?['reflections'] ?? {};

    if (reflections.containsKey(questionId)) return;

    await _userRef.update({
      'lessonProgress.$lessonId.quiz.reflections.$questionId': {
        'userAnswer': answer,
        'answeredAt': FieldValue.serverTimestamp(),
      },
      'lessonProgress.$lessonId.lastUpdatedAt':
      FieldValue.serverTimestamp(),
    });
  }

  // ================= COMPLETE LESSON =================

  Future<void> completeLesson({
    required String lessonId,
    required int obtainedScore,
    required int totalScore,
  }) async {
    await _db.runTransaction((txn) async {
      final snap = await txn.get(_userRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final lesson = data['lessonProgress']?[lessonId];
      if (lesson == null || lesson['score'] != null) return;

      final int percentage =
      totalScore == 0
          ? 0
          : ((obtainedScore / totalScore) * 100).round();

      txn.update(_userRef, {
        'lessonProgress.$lessonId.score': {
          'obtained': obtainedScore,
          'total': totalScore,
          'percentage': percentage,
        },
        'lessonProgress.$lessonId.completedAt':
        FieldValue.serverTimestamp(),
        'lessonProgress.$lessonId.lastUpdatedAt':
        FieldValue.serverTimestamp(),
      });
    });

    final int lessonPoints =
    await _getLessonPoints(lessonId);
    if (lessonPoints <= 0) return;

    await _db.runTransaction((txn) async {
      final snap = await txn.get(_userRef);
      if (!snap.exists) return;

      final lesson =
      snap['lessonProgress']?[lessonId];
      if (lesson == null ||
          lesson['pointsCredited'] == true) return;

      txn.update(_userRef, {
        'wallet.points':
        FieldValue.increment(lessonPoints),
        'lessonProgress.$lessonId.pointsCredited': true,
      });
    });
  }

  // ================= CHECKS =================

  Future<bool> isLessonCompleted(String lessonId) async {
    final snap = await _getUserSnap();
    final data = snap.data();
    return data?['lessonProgress']?[lessonId]?['score'] != null;
  }

  Future<bool> isMandatoryLessonCompleted(String lessonId) async {
    final snap = await _getUserSnap();
    final data = snap.data();
    final lesson = data?['lessonProgress']?[lessonId];
    if (lesson == null) return false;

    return lesson['isMandatory'] == true &&
        lesson['completedAt'] != null;
  }

  // ================= 🆕 GET QUIZ PROGRESS (ADDED) =================
  // Used by QuizPage to resume partially completed lessons
  // DOES NOT modify any existing logic or structure

  Future<Map<String, dynamic>> getLessonQuizProgress(String lessonId) async {
    final snap = await _getUserSnap();
    if (!snap.exists) return {
      'answers': {},
      'reflections': {},
    };

    final data = snap.data();
    final lesson = data?['lessonProgress']?[lessonId];

    if (lesson == null) {
      return {
        'answers': {},
        'reflections': {},
      };
    }

    final answers =
    Map<String, dynamic>.from(lesson['quiz']?['answers'] ?? {});

    final reflections =
    Map<String, dynamic>.from(lesson['quiz']?['reflections'] ?? {});

    return {
      'answers': answers,
      'reflections': reflections,
    };
  }
}
