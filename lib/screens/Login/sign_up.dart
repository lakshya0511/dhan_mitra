import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/app_navigator.dart';
import '../../components/models/user_database.dart';
import '../../components/myButton.dart';
import '../../components/utils.dart';
import '../../components/wrapper.dart';
import '../../main.dart';

class SignUpWidget extends StatefulWidget {
  final VoidCallback onClickedSignIn;

  const SignUpWidget({Key? key, required this.onClickedSignIn})
      : super(key: key);

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();

  String? selectedCity;

  final formKey = GlobalKey<FormState>();

  String? selectedGender;

  final List<String> genders = [
    "Male",
    "Female",
    "Other",
    "Prefer not to say",
  ];


  final List<String> cities = [
    "Mumbai",
    "Delhi",
    "Bengaluru",
    "Hyderabad",
    "Chennai",
    "Kolkata",
    "Pune",
    "Ahmedabad",
    "Jaipur",
    "Chandigarh",
    "Indore",
    "Bhopal",
    "Lucknow",
    "Kanpur",
    "Noida",
    "Gurugram",
    "Faridabad",
    "Ghaziabad",
    "Meerut",
    "Agra",
    "Varanasi",
    "Patna",
    "Ranchi",
    "Bhubaneswar",
    "Cuttack",
    "Visakhapatnam",
    "Vijayawada",
    "Coimbatore",
    "Madurai",
  ]..sort();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
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
            padding: const EdgeInsets.fromLTRB(0, 95, 0, 0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  "Register Yourself",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Enter full name" : null,
                ),
                const SizedBox(height: 16),

                // Phone Number (+91)
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixText: "+91 ",
                    prefixIcon: Icon(Icons.phone),
                    counterText: "",
                  ),
                  validator: (v) =>
                  v != null && v.length == 10
                      ? null
                      : "Enter 10-digit phone number",
                ),
                const SizedBox(height: 16),

                // City Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCity,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "City",
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  hint: const Text("Select your city"),
                  items: cities
                      .map(
                        (city) => DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCity = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? "Please select your city" : null,
                ),
                const SizedBox(height: 16),

// Gender Dropdown
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Gender",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  hint: const Text("Select your gender"),
                  items: genders
                      .map(
                        (gender) => DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedGender = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? "Please select your gender" : null,
                ),

                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (email) =>
                  email != null && !EmailValidator.validate(email)
                      ? "Invalid email"
                      : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (v) =>
                  v != null && v.length < 8
                      ? "Minimum 8 characters"
                      : null,
                ),
                const SizedBox(height: 32),

                // Submit
                MyButton(onTap: signUp, text: "Create Account"),
                const SizedBox(height: 24),

                // Login Redirect
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    text: "Already registered? ",
                    children: [
                      TextSpan(
                        text: "Login",
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = widget.onClickedSignIn,
                      ),
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

  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user!;

      await UserService().createOrUpdateUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        phone: "+91${phoneController.text.trim()}",
        city: selectedCity!, gender: selectedGender!,
      );

      await user.sendEmailVerification();

      navigatorKey.currentState?.pop();

      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Wrapper()),
            (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      navigatorKey.currentState?.pop();
      Utils.showSnackBar(e.message ?? "Signup failed");
    }
  }
}
