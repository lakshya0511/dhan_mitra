import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../components/models/trading/trading_database.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  String formatAmount(num amount) {
    return NumberFormat('#,##0', 'en_IN')
        .format(amount.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final trading = TradingService();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction History"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: trading.tradeHistoryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator());
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64,
                      color: cs.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    "No transactions yet",
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(
                        color:
                        cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
              docs[index].data()
              as Map<String, dynamic>;

              final bool isBuy =
                  data['type'] == 'buy';
              final Color actionColor =
              isBuy ? Colors.green : Colors.red;

              // Safe numeric conversions
              final double price =
                  (data['price'] as num?)
                      ?.toDouble() ??
                      0.0;
              final double totalAmount =
                  (data['totalAmount']
                  as num?)
                      ?.toDouble() ??
                      0.0;
              final int quantity =
                  (data['quantity'] as num?)
                      ?.toInt() ??
                      0;

              String dateStr = "";
              if (data['createdAt'] != null) {
                final date =
                (data['createdAt']
                as Timestamp)
                    .toDate();
                dateStr = DateFormat(
                    'MMM dd, hh:mm a')
                    .format(date);
              }

              return Container(
                margin: const EdgeInsets.only(
                    bottom: 12),
                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(16),
                  border: Border.all(
                      color: cs.outlineVariant),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: actionColor
                          .withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(
                          12),
                    ),
                    child: Icon(
                      isBuy
                          ? Icons
                          .trending_up_rounded
                          : Icons
                          .trending_down_rounded,
                      color: actionColor,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        data['symbol'] ??
                            "STOCK",
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                            fontWeight:
                            FontWeight
                                .bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                            horizontal:
                            6,
                            vertical:
                            2),
                        decoration:
                        BoxDecoration(
                          color: actionColor
                              .withOpacity(
                              0.1),
                          borderRadius:
                          BorderRadius
                              .circular(
                              4),
                        ),
                        child: Text(
                          isBuy
                              ? "BUY"
                              : "SELL",
                          style: theme
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                            color:
                            actionColor,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "$quantity stocks @ ",
                            style: theme
                                .textTheme
                                .bodyMedium,
                          ),
                          SvgPicture.asset(
                            'assets/icons/gold_coin.svg',
                            height: 14,
                            width: 14,
                          ),
                          const SizedBox(
                              width: 4),
                          Text(
                            formatAmount(
                                price),
                            style: theme
                                .textTheme
                                .bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: theme
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                            color: cs
                                .onSurfaceVariant),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .end,
                    children: [
                      Row(
                        mainAxisSize:
                        MainAxisSize
                            .min,
                        children: [
                          Text(
                            isBuy
                                ? "-"
                                : "+",
                            style: theme
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight:
                              FontWeight
                                  .bold,
                              color:
                              actionColor,
                            ),
                          ),
                          const SizedBox(
                              width: 4),
                          Text(
                            formatAmount(
                                totalAmount),
                            style: theme
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight:
                              FontWeight
                                  .bold,
                              color:
                              actionColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isBuy
                            ? "Spent"
                            : "Received",
                        style: theme
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                            color:
                            cs.outline),
                      ),
                    ],
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
