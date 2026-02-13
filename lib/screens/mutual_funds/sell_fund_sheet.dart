import 'package:dhan_mitra/components/models/mutual_funds/mutual_fund_database.dart';
import 'package:flutter/material.dart';

class SellFundSheet
    extends StatefulWidget {
  final String fundId;
  final double units;

  const SellFundSheet({
    super.key,
    required this.fundId,
    required this.units,
  });

  @override
  State<SellFundSheet> createState() =>
      _SellFundSheetState();
}

class _SellFundSheetState
    extends State<SellFundSheet> {
  final TextEditingController _units =
  TextEditingController();

  final MutualFundService _service =
  MutualFundService();

  bool loading = false;

  Future<void> _sell() async {
    final double? u =
    double.tryParse(_units.text);
    if (u == null || u <= 0) return;

    setState(() => loading = true);

    try {
      await _service.sellFund(
        fundId: widget.fundId,
        units: u,
      );
      if (mounted)
        Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
            content: Text(e
                .toString()
                .replaceAll(
                "Exception: ",
                ""))),
      );
    }

    if (mounted)
      setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
        MediaQuery.of(context)
            .viewInsets
            .bottom +
            16,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Text(widget.fundId),
          const SizedBox(height: 12),
          TextField(
            controller: _units,
            keyboardType:
            TextInputType.number,
            decoration:
            InputDecoration(
              labelText:
              "Units to Sell",
              helperText:
              "Available: ${widget.units}",
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
            loading ? null : _sell,
            child: loading
                ? const CircularProgressIndicator()
                : const Text(
                "REDEEM"),
          )
        ],
      ),
    );
  }
}
