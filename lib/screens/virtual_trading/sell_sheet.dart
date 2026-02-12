import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../components/models/trading/trading_database.dart';

class SellSheet extends StatefulWidget {
  final String symbol;
  final double avgBuyPrice; // rupees
  final int maxQuantity;

  const SellSheet({
    super.key,
    required this.symbol,
    required this.avgBuyPrice,
    required this.maxQuantity,
  });

  @override
  State<SellSheet> createState() => _SellSheetState();
}

class _SellSheetState extends State<SellSheet> {
  final TextEditingController _qtyController = TextEditingController();
  bool loading = false;

  final TradingService _trading = TradingService();

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _sell({
    required int qty,
    required double marketPrice,
  }) async {
    if (qty <= 0 || qty > widget.maxQuantity) return;

    setState(() => loading = true);

    try {
      await _trading.sellStock(
        symbol: widget.symbol,
        quantity: qty,
        price: marketPrice,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget coin(double size) => SvgPicture.asset(
    'assets/icons/gold_coin.svg',
    height: size,
    width: size,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final int qty = int.tryParse(_qtyController.text) ?? 0;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('market_prices')
          .doc(widget.symbol)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final double marketPriceRupees =
        (data['price'] as num).toDouble();
        final double marketPrice =
        (data['price'] as num).toDouble();

        final double total = qty * marketPrice;
        final double pnlPerShare =
        (marketPrice - widget.avgBuyPrice);

        final bool isProfit = pnlPerShare >= 0;
        final Color trendColor =
        isProfit ? Colors.green : Colors.red;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom:
              MediaQuery.of(context).viewInsets.bottom +
                  16,
              left: 20,
              right: 20,
              top: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin:
                  const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color:
                    colorScheme.outlineVariant,
                    borderRadius:
                    BorderRadius.circular(2),
                  ),
                ),

                Text(
                  'Sell ${widget.symbol}',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // PRICE INFO
                Container(
                  padding:
                  const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceAround,
                    children: [
                      _PriceTile(
                        label: 'Avg Buy',
                        value: widget.avgBuyPrice,
                      ),
                      Container(
                          width: 1,
                          height: 30,
                          color: colorScheme
                              .outlineVariant),
                      _PriceTile(
                        label:
                        'Current Market',
                        value:
                        marketPrice,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // PROFIT / LOSS BADGE
                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                      horizontal:
                      12,
                      vertical:
                      6),
                  decoration:
                  BoxDecoration(
                    color: trendColor
                        .withOpacity(
                        0.1),
                    borderRadius:
                    BorderRadius
                        .circular(
                        8),
                  ),
                  child: Row(
                    mainAxisSize:
                    MainAxisSize
                        .min,
                    children: [
                      Text(
                        isProfit
                            ? 'Profit per share: +'
                            : 'Loss per share: -',
                        style: theme
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                          color:
                          trendColor,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                      const SizedBox(
                          width: 6),
                      coin(14),
                      const SizedBox(
                          width: 4),
                      Text(
                        pnlPerShare
                            .abs()
                            .toStringAsFixed(0),
                        style: theme
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                          color:
                          trendColor,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller:
                  _qtyController,
                  keyboardType:
                  TextInputType
                      .number,
                  autofocus: true,
                  decoration:
                  InputDecoration(
                    labelText:
                    'Quantity',
                    hintText:
                    'Max: ${widget.maxQuantity}',
                    prefixIcon:
                    const Icon(Icons
                        .sell_outlined),
                    helperText:
                    'Available to sell: ${widget.maxQuantity}',
                  ),
                  onChanged: (_) =>
                      setState(() {}),
                ),

                const SizedBox(height: 16),

                // TOTAL CREDIT
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    Text('Total Credit',
                        style: theme
                            .textTheme
                            .titleMedium),
                    Row(
                      children: [
                        coin(18),
                        const SizedBox(
                            width: 6),
                        Text(
                          total
                              .toStringAsFixed(0),
                          style: theme
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight:
                            FontWeight
                                .bold,
                            color:
                            colorScheme
                                .primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: loading ||
                        qty <= 0 ||
                        qty >
                            widget
                                .maxQuantity
                        ? null
                        : () => _sell(
                      qty: qty,
                      marketPrice:
                      marketPrice,
                    ),
                    style: FilledButton
                        .styleFrom(
                      backgroundColor:
                      colorScheme
                          .error,
                      foregroundColor:
                      colorScheme
                          .onError,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                            12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        3,
                        color: Colors
                            .white,
                      ),
                    )
                        : const Text(
                      'PLACE SELL ORDER',
                      style: TextStyle(
                          fontWeight:
                          FontWeight
                              .bold,
                          letterSpacing:
                          1.1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PriceTile extends StatelessWidget {
  final String label;
  final double value;

  const _PriceTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall
              ?.copyWith(
            color: theme.colorScheme
                .onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/gold_coin.svg',
              height: 16,
              width: 16,
            ),
            const SizedBox(width: 4),
            Text(
              value.toStringAsFixed(0),
              style: theme
                  .textTheme.titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
