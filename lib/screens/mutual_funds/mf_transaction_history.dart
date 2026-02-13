import 'package:dhan_mitra/components/models/mutual_funds/mutual_fund_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class MFTransactionHistoryPage extends StatelessWidget {
  const MFTransactionHistoryPage({super.key});

  Widget coin(double size) => SvgPicture.asset(
    'assets/icons/gold_coin.svg',
    height: size,
    width: size,
  );

  String formatAmount(num value) {
    return NumberFormat('#,##0', 'en_IN').format(value);
  }

  Future<void> _clearTransactions(BuildContext context) async {
    final service = MutualFundService();
    final snapshot = await service.transactionStream().first;

    if (snapshot.docs.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear Transactions?"),
        content: const Text(
            "This will permanently delete all mutual fund transaction history."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Transaction history cleared"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = MutualFundService();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mutual Fund Transactions"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: "Clear All",
            onPressed: () => _clearTransactions(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.transactionStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    "No transactions yet",
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data =
              docs[i].data() as Map<String, dynamic>;

              final bool isBuy = data['type'] == 'buy';
              final Color actionColor =
              isBuy ? Colors.green : Colors.red;

              final double nav =
                  (data['nav'] as num?)?.toDouble() ?? 0.0;

              final double units =
                  (data['units'] as num?)?.toDouble() ?? 0.0;

              final double amount =
                  (data['amount'] as num?)?.toDouble() ?? 0.0;

              String dateStr = "";
              if (data['createdAt'] != null) {
                final date =
                (data['createdAt'] as Timestamp).toDate();
                dateStr =
                    DateFormat('MMM dd, hh:mm a').format(date);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),

                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: actionColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isBuy
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: actionColor,
                    ),
                  ),

                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['fundId'] ?? "Fund",
                          style: theme.textTheme.titleMedium
                              ?.copyWith(
                              fontWeight:
                              FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2),
                        decoration: BoxDecoration(
                          color: actionColor
                              .withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(6),
                        ),
                        child: Text(
                          isBuy ? "BUY" : "SELL",
                          style: theme.textTheme
                              .labelSmall
                              ?.copyWith(
                            color: actionColor,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  subtitle: Padding(
                    padding:
                    const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${units.toStringAsFixed(4)} units @ NAV",
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            coin(14),
                            const SizedBox(width: 4),
                            Text(formatAmount(nav)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: theme.textTheme
                              .labelSmall
                              ?.copyWith(
                            color:
                            cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  trailing: SizedBox(
                    width: 120,
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            Text(
                              isBuy ? "-" : "+",
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                color: actionColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            coin(14),
                            const SizedBox(width: 4),
                            Text(
                              formatAmount(amount),
                              style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                color: actionColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBuy
                              ? "Invested"
                              : "Redeemed",
                          style: theme.textTheme
                              .labelSmall
                              ?.copyWith(
                            color: cs.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
