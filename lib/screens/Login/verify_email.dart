import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../components/myButton.dart';
import '../../components/utils.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({Key? key}) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool canResend = false;
  int secondsRemaining = 60;
  Timer? _verifyTimer;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    // Send verification email once
    if (user != null && !user.emailVerified) {
      _sendVerificationEmail();
      _startVerificationPolling();
    }
  }

  // ---------------- SEND EMAIL ----------------

  Future<void> _sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }

      setState(() {
        canResend = false;
        secondsRemaining = 60;
      });

      _startResendCountdown();
      Utils.showSnackBar("Verification email sent.");

    } catch (e) {
      setState(() => canResend = true);
    }
  }

  // ---------------- POLLING ----------------

  void _startVerificationPolling() {
    _verifyTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) => _checkVerificationStatus(),
    );
  }

  Future<void> _checkVerificationStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    await user?.reload();

    if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
      _verifyTimer?.cancel();
      // ✅ DO NOTHING ELSE
      // Wrapper will automatically redirect
    }
  }

  // ---------------- RESEND TIMER ----------------

  void _startResendCountdown() {
    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (secondsRemaining > 0) {
          secondsRemaining--;
        } else {
          canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> resendEmail() async {
    if (!canResend) return;
    await _sendVerificationEmail();
  }

  // ---------------- CANCEL ----------------

  Future<void> cancelAndSignOut() async {
    await FirebaseAuth.instance.signOut();
    // Wrapper will take user back to AuthPage
  }

  @override
  void dispose() {
    _verifyTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread, size: 80),
            const SizedBox(height: 24),

            const Text(
              "A verification email has been sent.\n"
                  "Please check your inbox (and spam).",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            canResend
                ? MyButton(
              onTap: resendEmail,
              text: "Resend Email",
            )
                : Text(
              "Try again in $secondsRemaining seconds",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            MyButton(
              onTap: cancelAndSignOut,
              text: "Cancel",
            ),

            const SizedBox(height: 16),

            const Text(
              "This page will update automatically after verification.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
