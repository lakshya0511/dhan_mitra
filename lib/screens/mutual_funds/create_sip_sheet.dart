import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateSIPSheet extends StatefulWidget {
  final String fundId;

  const CreateSIPSheet({
    super.key,
    required this.fundId,
  });

  @override
  State<CreateSIPSheet> createState() =>
      _CreateSIPSheetState();
}

class _CreateSIPSheetState
    extends State<CreateSIPSheet> {

  final TextEditingController _amount =
  TextEditingController();

  final TextEditingController _installments =
  TextEditingController(text: "12");

  int frequencySeconds = 30; // default demo

  bool loading = false;

  Future<void> _createSIP() async {
    final amount =
    int.tryParse(_amount.text);

    final totalInstallments =
    int.tryParse(_installments.text);

    if (amount == null ||
        amount <= 0 ||
        totalInstallments == null ||
        totalInstallments <= 0) {
      return;
    }

    setState(() => loading = true);

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('mf_sip')
        .add({
      'fundId': widget.fundId,
      'amount': amount,
      'frequencySeconds': frequencySeconds,
      'totalInstallments': totalInstallments,
      'installmentsCompleted': 0,
      'isActive': true,
      'lastExecutedAt': null,
      'createdAt':
      FieldValue.serverTimestamp(),
      'updatedAt':
      FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom:
        MediaQuery.of(context).viewInsets.bottom +
            16,
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

            Text(
              "Start SIP",
              style: theme
                  .textTheme.titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Fund: ${widget.fundId}",
              style: theme
                  .textTheme.bodyLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Amount
            TextField(
              controller: _amount,
              keyboardType:
              TextInputType.number,
              decoration:
              const InputDecoration(
                labelText:
                "Investment Amount (₹)",
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Frequency Selector
            DropdownButtonFormField<int>(
              value: frequencySeconds,
              decoration:
              const InputDecoration(
                labelText:
                "Frequency (Demo Mode)",
              ),
              items: const [
                DropdownMenuItem(
                    value: 30,
                    child: Text(
                        "Every 30 seconds")),
                DropdownMenuItem(
                    value: 60,
                    child: Text(
                        "Every 60 seconds")),
                DropdownMenuItem(
                    value: 120,
                    child: Text(
                        "Every 2 minutes")),
              ],
              onChanged: (val) {
                setState(() {
                  frequencySeconds =
                      val ?? 30;
                });
              },
            ),

            const SizedBox(height: 16),

            // 🔹 Duration
            TextField(
              controller:
              _installments,
              keyboardType:
              TextInputType.number,
              decoration:
              const InputDecoration(
                labelText:
                "Number of Installments",
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                loading ? null : _createSIP,
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
                    "CREATE SIP"),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
