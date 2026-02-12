import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../components/models/trading/trading_database.dart';

class BuySellSheet extends StatefulWidget {
  final String symbol;
  final double price; // rupees

  const BuySellSheet({
    super.key,
    required this.symbol,
    required this.price,
  });

  @override
  State<BuySellSheet> createState() => _BuySellSheetState();
}

class _BuySellSheetState extends State<BuySellSheet> {
  final TextEditingController _qtyController = TextEditingController();
  bool loading = false;

  final TradingService _trading = TradingService();

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Widget coin(double size) => SvgPicture.asset(
    'assets/icons/gold_coin.svg',
    height: size,
    width: size,
  );

  Future<void> _buy() async {
    final int? qty = int.tryParse(_qtyController.text);
    if (qty == null || qty <= 0) return;

    setState(() => loading = true);

    try {
      await _trading.buyStock(
        symbol: widget.symbol,
        quantity: qty,
        price: widget.price, // rupees
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final int qty = int.tryParse(_qtyController.text) ?? 0;

    // Ensure safe double math
    final double total = qty * widget.price;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Symbol
            Text(
              widget.symbol,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(height: 8),

            // Current Price
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Current Price: ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                coin(16),
                const SizedBox(width: 4),
                Text(
                  widget.price.toStringAsFixed(0),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quantity Input
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Quantity to Buy',
                hintText: '0',
                prefixIcon:
                Icon(Icons.shopping_basket_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // Order Total
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Total',
                    style: theme.textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      coin(18),
                      const SizedBox(width: 6),
                      Text(
                        total.toStringAsFixed(0),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buy Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: loading || qty <= 0
                    ? null
                    : _buy,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'PLACE BUY ORDER',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight:
                    FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
