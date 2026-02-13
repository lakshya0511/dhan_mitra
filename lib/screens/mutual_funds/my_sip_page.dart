import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dhan_mitra/components/models/mutual_funds/engine_runner.dart';

class MySIPPage extends StatefulWidget {
  const MySIPPage({super.key});

  @override
  State<MySIPPage> createState() => _MySIPPageState();
}

class _MySIPPageState extends State<MySIPPage> {

  @override
  void initState() {
    super.initState();

    // 🔥 Run engine once when page opens
    Future.microtask(() {
      FinancialEngineRunner.runOnce();
    });
  }

  Future<void> _clearCompletedSIPs(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mf_sip')
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snap.docs) {
      final data = doc.data();

      final completed =
      (data['installmentsCompleted'] ?? 0) as int;
      final total =
      (data['totalInstallments'] ?? 1) as int;
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
          content: Text("Completed/Stopped SIPs cleared"),
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
        title: const Text("My SIPs"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear Completed / Stopped",
            onPressed: () => _clearCompletedSIPs(context),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('mf_sip')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
                child: Text("No SIPs started yet"));
          }

          int activeCount = 0;
          int completedCount = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final completed =
            (data['installmentsCompleted'] ?? 0) as int;
            final total =
            (data['totalInstallments'] ?? 1) as int;
            final isActive =
            (data['isActive'] ?? false) as bool;

            if (completed >= total) {
              completedCount++;
            } else if (isActive) {
              activeCount++;
            }
          }

          return Column(
            children: [

              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _flashCard(
                      context,
                      title: "Active SIPs",
                      value: activeCount.toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _flashCard(
                      context,
                      title: "Completed SIPs",
                      value: completedCount.toString(),
                      color: Colors.green,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data =
                    docs[i].data() as Map<String, dynamic>;

                    final completed =
                    (data['installmentsCompleted'] ?? 0) as int;

                    final total =
                    (data['totalInstallments'] ?? 1) as int;

                    final totalInvested =
                        data['totalInvested'] ?? 0;

                    final streak =
                        data['sipStreak'] ?? 0;

                    final isActive =
                    (data['isActive'] ?? false) as bool;

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
                    } else if (isStopped) {
                      statusColor = Colors.orange;
                      statusText = "STOPPED";
                    } else {
                      statusColor = Colors.blue;
                      statusText = "ACTIVE";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outlineVariant),
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
                                  data['fundId'],
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _statusChip(statusText, statusColor),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                              "₹ ${data['amount']} per installment"),
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
                          Text("$completed / $total installments"),
                          const SizedBox(height: 6),
                          Text("Total Invested: ₹$totalInvested"),
                          Text("🔥 Streak: $streak"),
                          const SizedBox(height: 12),
                          if (isActive && !isCompleted)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  docs[i].reference.update({
                                    'isActive': false,
                                    'stoppedAt':
                                    FieldValue.serverTimestamp(),
                                  });
                                },
                                child: const Text(
                                  "STOP SIP",
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
          borderRadius: BorderRadius.circular(16),
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
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
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
