import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../components/app_navigator.dart';
import '../../components/myButton.dart';
import '../../components/utils.dart';
import '../../components/wrapper.dart';
import '../../main.dart';
import 'verify_email.dart';
import 'Forgot_Password_Page.dart';

class LoginWidget extends StatefulWidget {
  final VoidCallback onClickedSignUp;

  const LoginWidget({Key? key, required this.onClickedSignUp})
      : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Transform.scale(
                  scale: 1.4, // increase for more zoom
                  child: Image.asset(
                    "assets/logo.png",
                    height: 240,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  "Welcome Back",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (email) =>
                  email != null && !EmailValidator.validate(email)
                      ? "Enter valid email"
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (val) => val != null && val.length < 8
                      ? "Password must be 8+ characters"
                      : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage()),
                    ),
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 24),
                MyButton(onTap: signIn, text: "Login"),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    text: "New here? ",
                    children: [
                      TextSpan(
                        text: "Create account",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = widget.onClickedSignUp,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final cred =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 🔥 REQUIRED
      await cred.user?.reload();

      await cred.user?.reload();

      navigatorKey.currentState?.pop(); // close loader

// 🔥 FORCE ROOT REBUILD
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Wrapper()),
            (_) => false,
      );

    } on FirebaseAuthException catch (e) {
      navigatorKey.currentState?.pop();
      Utils.showSnackBar(e.message ?? "Login failed");
    }
  }
}