import 'package:dhan_mitra/components/models/mutual_funds/mutual_fund_database.dart';
import 'package:dhan_mitra/screens/mutual_funds/create_sip_sheet.dart';
import 'package:dhan_mitra/screens/mutual_funds/create_swp_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BuyFundSheet extends StatefulWidget {
  final String fundId;
  final double nav;

  const BuyFundSheet({
    super.key,
    required this.fundId,
    required this.nav,
  });

  @override
  State<BuyFundSheet> createState() => _BuyFundSheetState();
}

class _BuyFundSheetState extends State<BuyFundSheet> {
  final TextEditingController _amountController =
  TextEditingController();

  final MutualFundService _service =
  MutualFundService();

  bool loading = false;

  Widget coin(double size) => SvgPicture.asset(
    'assets/icons/gold_coin.svg',
    height: size,
    width: size,
  );

  Future<void> _buy() async {
    final int? amt =
    int.tryParse(_amountController.text);

    if (amt == null || amt <= 0) return;

    setState(() => loading = true);

    try {
      await _service.buyFund(
        fundId: widget.fundId,
        amount: amt,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll("Exception: ", ""),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final int amount =
        int.tryParse(_amountController.text) ?? 0;

    final double units =
    amount > 0 ? amount / widget.nav : 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom:
        MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            // 🔥 FUND NAME
            Text(
              widget.fundId,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                const Text("Current NAV: "),
                coin(14),
                const SizedBox(width: 4),
                Text(
                  widget.nav.toStringAsFixed(2),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= INVEST SECTION =================

            TextField(
              controller: _amountController,
              keyboardType:
              TextInputType.number,
              decoration: const InputDecoration(
                labelText:
                "Investment Amount (₹)",
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text("Estimated Units"),
                Text(
                  units.toStringAsFixed(4),
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                loading ? null : _buy,
                child: loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text("INVEST NOW"),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // ================= SIP / SWP =================

            Text(
              "Advanced Options",
              style: theme.textTheme.titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [

                // START SIP
                Expanded(
                  child: OutlinedButton.icon(
                    icon:
                    const Icon(Icons.repeat),
                    label:
                    const Text("Start SIP"),
                    onPressed: () {
                      Navigator.pop(context);

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled:
                        true,
                        shape:
                        const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) =>
                            CreateSIPSheet(
                              fundId:
                              widget.fundId,
                            ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // START SWP
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                        Icons.money_off),
                    label:
                    const Text("Start SWP"),
                    onPressed: () {
                      Navigator.pop(context);

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled:
                        true,
                        shape:
                        const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) =>
                            CreateSWPSheet(
                              fundId:
                              widget.fundId,
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
