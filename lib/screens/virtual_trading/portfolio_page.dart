import 'package:dhan_mitra/screens/virtual_trading/transaction_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../components/models/trading/trading_database.dart';
import 'sell_sheet.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  String query = '';

  String formatQuantity(int qty) {
    if (qty == 1) return "1 stock";
    return "$qty stocks";
  }

  Widget coin(double size) => SvgPicture.asset(
    'assets/icons/gold_coin.svg',
    height: size,
    width: size,
  );

  @override
  Widget build(BuildContext context) {
    final TradingService trading = TradingService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portfolio'),
        actions: [
          IconButton(
            tooltip: "Transaction History",
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TransactionHistoryPage(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search holdings',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) =>
                  setState(() => query = v.toUpperCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: trading.portfolioStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No holdings yet'));
                }

                final holdings =
                snapshot.data!.values.where((h) {
                  return (h['symbol'] as String)
                      .contains(query);
                }).toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: holdings.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final h = holdings[index];
                    final int quantity = h['quantity'];

                    final double avgBuyPrice =
                    (h['avgBuyPrice'] as num).toDouble();
                    final double investedAmount =
                    (h['investedAmount'] as num).toDouble();

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                        side: BorderSide(
                            color: colorScheme
                                .outlineVariant),
                      ),
                      child: ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8),
                        title: Row(
                          children: [
                            Text(
                              h['symbol'],
                              style: theme
                                  .textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                  horizontal:
                                  8,
                                  vertical:
                                  3),
                              decoration:
                              BoxDecoration(
                                color: colorScheme
                                    .secondaryContainer,
                                borderRadius:
                                BorderRadius
                                    .circular(6),
                              ),
                              child: Text(
                                formatQuantity(
                                    quantity),
                                style: theme
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                  color: colorScheme
                                      .onSecondaryContainer,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Avg Buy
                        subtitle: Padding(
                          padding:
                          const EdgeInsets
                              .only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                'Avg Buy: ',
                                style: theme
                                    .textTheme
                                    .bodySmall,
                              ),
                              coin(14),
                              const SizedBox(width: 4),
                              Text(
                                avgBuyPrice
                                    .toStringAsFixed(0),
                                style: theme
                                    .textTheme
                                    .bodySmall,
                              ),
                            ],
                          ),
                        ),

                        // Invested
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
                              MainAxisSize.min,
                              children: [
                                coin(16),
                                const SizedBox(width: 4),
                                Text(
                                  investedAmount
                                      .toStringAsFixed(0),
                                  style: theme
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                    color: colorScheme
                                        .primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Invested',
                              style: theme
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                color: colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            shape:
                            const RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .vertical(
                                top: Radius.circular(
                                    20),
                              ),
                            ),
                            builder: (_) =>
                                SellSheet(
                                  symbol: h['symbol'],
                                  avgBuyPrice:
                                  avgBuyPrice,
                                  maxQuantity:
                                  quantity,
                                ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
