import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../components/myButton.dart';
import '../../components/utils.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_reset, size: 80, color: colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                "Forgot your password?",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your registered email address.\nWe’ll send you a reset link.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (email) =>
                email != null && !EmailValidator.validate(email)
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 24),
              MyButton(onTap: resetPassword, text: "Send Reset Email"),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      Navigator.pop(context);
      Utils.showSnackBar("Password reset email sent");
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      Utils.showSnackBar(e.message ?? "Error at the backend");

    } catch (e) {
      Navigator.pop(context);
      Utils.showSnackBar(e.toString());
    }
  }
}