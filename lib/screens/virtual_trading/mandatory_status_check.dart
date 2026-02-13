import 'package:dhan_mitra/screens/practice_dashboard.dart';
import 'package:dhan_mitra/screens/virtual_trading/trading_home.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Learning/finance_sections_page.dart';
import '../Learning/lesson_detail_page.dart';
import '../Profile.dart';
import '../dashboard.dart';

class MandatoryStatusPage extends StatefulWidget {
  const MandatoryStatusPage({super.key});

  @override
  State<MandatoryStatusPage> createState() => _MandatoryStatusPageState();
}

class _MandatoryStatusPageState extends State<MandatoryStatusPage> {
  bool _unlocking = false;

  Future<void> _unlockTradingAndRedirect() async {
    if (_unlocking) return;
    _unlocking = true;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userRef =
    FirebaseFirestore.instance.collection('users').doc(uid);

    final snap = await userRef.get();
    final userData = snap.data() ?? {};

    // Prevent re-unlocking if already unlocked
    if (userData['trading']?['unlocked'] == true) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PracticeDashboardPage()),
      );
      return;
    }

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final freshSnap = await txn.get(userRef);
      final freshData = freshSnap.data() ?? {};

      if (freshData['trading']?['unlocked'] == true) return;

      txn.update(userRef, {
        'trading.unlocked': true,
        'trading.unlockedAt': FieldValue.serverTimestamp(),
        'wallet.balance': FieldValue.increment(10000),
      });
    });


    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PracticeDashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mandatory Progress"),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lessons')
            .where('isMandatory', isEqualTo: true)
            .snapshots(),
        builder: (context, lessonSnap) {
          if (!lessonSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final mandatoryLessons = lessonSnap.data!.docs;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData =
                  userSnap.data!.data() as Map<String, dynamic>? ?? {};

              final Map<String, dynamic> progress =
              Map<String, dynamic>.from(userData['lessonProgress'] ?? {});

              // ================= CORRECT COMPLETION CHECK =================

              final pendingLessons = mandatoryLessons.where((lessonDoc) {
                final lessonId = lessonDoc.id;
                final lessonProgress = progress[lessonId];

                // Not started
                if (lessonProgress == null) return true;

                // Not fully completed
                if (lessonProgress['completedAt'] == null) return true;

                return false;
              }).toList();

              final bool allCompleted =
                  mandatoryLessons.isNotEmpty &&
                      pendingLessons.isEmpty;

              if (allCompleted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _unlockTradingAndRedirect();
                });
              }

              // ================= UI =================

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allCompleted) ...[
                      const Spacer(),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer
                                    .withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 80,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Trading Unlocked 🎉",
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Redirecting you to the market…",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(
                                color:
                                colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),
                    ] else ...[
                      Row(
                        children: [
                          Icon(Icons.pending_actions_rounded,
                              color: colorScheme.primary,
                              size: 28),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Action Required",
                                style: theme
                                    .textTheme.titleLarge
                                    ?.copyWith(
                                    fontWeight:
                                    FontWeight.bold),
                              ),
                              Text(
                                "${pendingLessons.length} lessons remaining to unlock virtual trading",
                                style: theme
                                    .textTheme.bodyMedium
                                    ?.copyWith(
                                    color: colorScheme
                                        .onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Padding(
                        padding:
                        EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: pendingLessons.length,
                          itemBuilder: (context, index) {
                            final lessonDoc =
                            pendingLessons[index];
                            final lessonData =
                            lessonDoc.data()
                            as Map<String, dynamic>;

                            return Container(
                              margin:
                              const EdgeInsets.only(
                                  bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius:
                                BorderRadius.circular(
                                    16),
                                border: Border.all(
                                    color: colorScheme
                                        .outlineVariant),
                              ),
                              child: ListTile(
                                contentPadding:
                                const EdgeInsets.all(12),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorScheme
                                        .errorContainer
                                        .withOpacity(0.2),
                                    borderRadius:
                                    BorderRadius.circular(
                                        12),
                                  ),
                                  child: Icon(
                                      Icons.lock_clock_rounded,
                                      color:
                                      colorScheme.error),
                                ),
                                title: Text(
                                  lessonData['title'] ??
                                      'Untitled Lesson',
                                  style: theme
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                      fontWeight:
                                      FontWeight
                                          .bold),
                                ),
                                subtitle: Text(
                                  "Complete to unlock trading",
                                  style: theme
                                      .textTheme.bodySmall
                                      ?.copyWith(
                                      color: colorScheme
                                          .onSurfaceVariant),
                                ),
                                trailing: Icon(
                                  Icons
                                      .arrow_forward_ios_rounded,
                                  size: 16,
                                  color:
                                  colorScheme.outline,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          LessonDetailPage(
                                            lessonId:
                                            lessonDoc.id,
                                            lessonData:
                                            lessonData,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home),
              label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.school),
              label: "Lessons"),
          NavigationDestination(
              icon: Icon(Icons.trending_up),
              label: "Trading"),
          NavigationDestination(
              icon: Icon(Icons.person),
              label: "Profile"),
        ],
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                  const FinanceSectionsPage()),
            );
          } else if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                  const DashboardPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                  const ProfilePage()),
            );
          }
        },
      ),
    );
  }
}
