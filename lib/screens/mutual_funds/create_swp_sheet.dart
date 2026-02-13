import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateSWPSheet extends StatefulWidget {
  final String fundId;

  const CreateSWPSheet({
    super.key,
    required this.fundId,
  });

  @override
  State<CreateSWPSheet> createState() =>
      _CreateSWPSheetState();
}

class _CreateSWPSheetState
    extends State<CreateSWPSheet> {

  final TextEditingController _amount =
  TextEditingController();

  final TextEditingController _duration =
  TextEditingController();

  bool loading = false;

  Future<void> _createSWP() async {

    final int? amount =
    int.tryParse(_amount.text);

    final int? totalWithdrawals =
    int.tryParse(_duration.text);

    if (amount == null ||
        amount <= 0 ||
        totalWithdrawals == null ||
        totalWithdrawals <= 0) {

      _showError("Enter valid amount and duration");
      return;
    }

    setState(() => loading = true);

    try {

      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      final userRef =
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid);

      final userSnap = await userRef.get();

      final userData =
          userSnap.data() as Map<String, dynamic>? ?? {};

      final portfolio =
      Map<String, dynamic>.from(
          userData['mfPortfolio'] ?? {});

      final holding =
      portfolio[widget.fundId];

      // 🔒 VALIDATION 1: Fund exists
      if (holding == null) {
        _showError("No holdings available for this fund");
        setState(() => loading = false);
        return;
      }

      final double availableUnits =
          (holding['units'] as num?)?.toDouble() ?? 0;

      // 🔒 VALIDATION 2: Units > 0
      if (availableUnits <= 0) {
        _showError("You don't own any units of this fund");
        setState(() => loading = false);
        return;
      }

      // 🔒 OPTIONAL VALIDATION 3:
      // Prevent unrealistic withdrawal setup
      final double currentNAV =
          (holding['avgPrice'] as num?)?.toDouble() ?? 0;

      if (currentNAV <= 0) {
        _showError("Invalid NAV data");
        setState(() => loading = false);
        return;
      }

      final double totalValue =
          availableUnits * currentNAV;

      final int totalPlanned =
          amount * totalWithdrawals;

      if (totalPlanned > totalValue) {
        _showError(
            "Total planned withdrawal exceeds portfolio value");
        setState(() => loading = false);
        return;
      }

      // =================================================
      // ✅ CREATE SWP
      // =================================================

      await userRef
          .collection('mf_swp')
          .add({

        // Core
        'fundId': widget.fundId,
        'amount': amount,
        'frequencySeconds': 30,

        // Installments
        'totalWithdrawals': totalWithdrawals,
        'withdrawalsCompleted': 0,

        // Tracking
        'totalWithdrawn': 0,
        'withdrawalStreak': 0,
        'missedWithdrawals': 0,

        'isActive': true,
        'lastExecutedAt': null,
        'lastError': null,
        'stoppedReason': null,

        // Meta
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);

    } catch (e) {

      _showError("Failed to create SWP");

    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {

    final int amount =
        int.tryParse(_amount.text) ?? 0;

    final int duration =
        int.tryParse(_duration.text) ?? 0;

    final int totalPlanned =
        amount * duration;

    return Padding(
      padding: EdgeInsets.only(
        bottom:
        MediaQuery.of(context)
            .viewInsets
            .bottom + 16,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [

            const Text(
              "Start SWP",
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Fund: ${widget.fundId}",
              style: const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _amount,
              keyboardType:
              TextInputType.number,
              decoration:
              const InputDecoration(
                labelText:
                "Withdrawal Amount (₹)",
              ),
              onChanged: (_) =>
                  setState(() {}),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _duration,
              keyboardType:
              TextInputType.number,
              decoration:
              const InputDecoration(
                labelText:
                "Number of Withdrawals",
              ),
              onChanged: (_) =>
                  setState(() {}),
            ),

            const SizedBox(height: 16),

            if (amount > 0 &&
                duration > 0)
              Container(
                padding:
                const EdgeInsets.all(12),
                decoration:
                BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(
                      12),
                  color: Colors.grey
                      .withOpacity(0.08),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    const Text(
                      "Total Planned Withdrawal",
                      style: TextStyle(
                          fontWeight:
                          FontWeight
                              .bold),
                    ),
                    const SizedBox(
                        height: 6),
                    Text(
                      "₹ $totalPlanned",
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                loading
                    ? null
                    : _createSWP,
                child: loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Text(
                    "CREATE SWP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
