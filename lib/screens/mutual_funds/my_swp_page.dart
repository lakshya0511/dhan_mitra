import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dhan_mitra/components/models/mutual_funds/engine_runner.dart';

class MySWPPage extends StatefulWidget {
  const MySWPPage({super.key});

  @override
  State<MySWPPage> createState() => _MySWPPageState();
}

class _MySWPPageState extends State<MySWPPage> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      FinancialEngineRunner.runOnce();
    });
  }

  Future<void> _clearCompletedSWPs(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mf_swp')
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snap.docs) {
      final data = doc.data();

      final completed =
      (data['withdrawalsCompleted'] ?? 0) as int;
      final total =
      (data['totalWithdrawals'] ?? 1) as int;
      final isActive =
      (data['isActive'] ?? false) as bool;

      final isCompleted = completed >= total;
      final isStopped = !isActive && !isCompleted;

      if (isCompleted || isStopped) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completed/Stopped SWPs cleared"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My SWPs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear Completed / Stopped",
            onPressed: () => _clearCompletedSWPs(context),
          )
        ],
      ),

      // 🔥 First listen to user portfolio
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, userSnap) {

          if (!userSnap.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          final userData =
              userSnap.data!.data() as Map<String, dynamic>? ?? {};

          final portfolio =
          Map<String, dynamic>.from(userData['mfPortfolio'] ?? {});

          // 🔥 Then listen to SWPs
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('mf_swp')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {

              if (!snap.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Center(
                    child: Text("No SWPs started yet"));
              }

              int activeCount = 0;
              int completedCount = 0;

              for (var doc in docs) {
                final data =
                doc.data() as Map<String, dynamic>;

                final completed =
                (data['withdrawalsCompleted'] ?? 0) as int;

                final total =
                (data['totalWithdrawals'] ?? 1) as int;

                final isActive =
                (data['isActive'] ?? false) as bool;

                final fundId = data['fundId'];

                final holding = portfolio[fundId];
                final hasUnits = holding != null &&
                    ((holding['units'] as num?)?.toDouble() ?? 0) > 0;

                if (completed >= total) {
                  completedCount++;
                } else if (isActive && hasUnits) {
                  activeCount++;
                }
              }

              return Column(
                children: [

                  // ================= FLASH CARDS =================

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _flashCard(
                          context,
                          title: "Active SWPs",
                          value: activeCount.toString(),
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        _flashCard(
                          context,
                          title: "Completed SWPs",
                          value: completedCount.toString(),
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),

                  // ================= SWP LIST =================

                  Expanded(
                    child: ListView.builder(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {

                        final data =
                        docs[i].data() as Map<String, dynamic>;

                        final fundId = data['fundId'];

                        final completed =
                        (data['withdrawalsCompleted'] ?? 0) as int;

                        final total =
                        (data['totalWithdrawals'] ?? 1) as int;

                        final totalWithdrawn =
                            data['totalWithdrawn'] ?? 0;

                        final streak =
                            data['withdrawalStreak'] ?? 0;

                        final isActive =
                        (data['isActive'] ?? false) as bool;

                        final holding = portfolio[fundId];
                        final hasUnits = holding != null &&
                            ((holding['units'] as num?)?.toDouble() ?? 0) > 0;

                        final bool isCompleted =
                            completed >= total;

                        final bool isStopped =
                            !isActive && !isCompleted;

                        final progress =
                        total == 0 ? 0.0 : completed / total;

                        Color statusColor;
                        String statusText;

                        if (isCompleted) {
                          statusColor = Colors.green;
                          statusText = "COMPLETED";
                        } else if (!hasUnits) {
                          statusColor = Colors.red;
                          statusText = "NO UNITS";
                        } else if (isStopped) {
                          statusColor = Colors.orange;
                          statusText = "STOPPED";
                        } else {
                          statusColor = Colors.blue;
                          statusText = "ACTIVE";
                        }

                        return Container(
                          margin:
                          const EdgeInsets.only(bottom: 14),
                          padding:
                          const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius:
                            BorderRadius.circular(16),
                            border: Border.all(
                                color: cs.outlineVariant),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      fundId,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  _statusChip(
                                      statusText,
                                      statusColor),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                  "₹ ${data['amount']} per withdrawal"),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor:
                                cs.surfaceVariant,
                                valueColor:
                                AlwaysStoppedAnimation(
                                    statusColor),
                              ),
                              const SizedBox(height: 6),
                              Text("$completed / $total withdrawals"),
                              const SizedBox(height: 6),
                              Text(
                                  "Total Withdrawn: ₹$totalWithdrawn"),
                              Text("🔥 Streak: $streak"),
                              const SizedBox(height: 12),

                              if (isActive &&
                                  !isCompleted &&
                                  hasUnits)
                                Align(
                                  alignment:
                                  Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      docs[i]
                                          .reference
                                          .update({
                                        'isActive': false,
                                        'stoppedAt':
                                        FieldValue.serverTimestamp(),
                                      });
                                    },
                                    child: const Text(
                                      "STOP SWP",
                                      style: TextStyle(
                                          color: Colors.red),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _flashCard(BuildContext context,
      {required String title,
        required String value,
        required Color color}) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius:
          BorderRadius.circular(16),
          color: color.withOpacity(0.08),
        ),
        child: Column(
          children: [
            Text(title,
                style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius:
        BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
