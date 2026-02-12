import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/Login/auth_page.dart';
import '../screens/Login/verify_email.dart';
import '../screens/dashboard.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, authSnapshot) {
        // ⏳ WAIT FOR AUTH
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;

        // 🔒 NOT LOGGED IN
        if (user == null) {
          return const AuthPage();
        }

        // 📧 EMAIL NOT VERIFIED
        if (!user.emailVerified) {
          return const VerifyEmailPage();
        }

        // 🔥 WAIT FOR USER DOCUMENT
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ⛔ USER DOC NOT READY YET (very common just after signup)
            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const Scaffold(
                body: Center(
                  child: Text("Setting up your account..."),
                ),
              );
            }

            final data =
            userSnap.data!.data() as Map<String, dynamic>;

            final role = data['role'] ?? 'user';

            /* 👑 ADMIN
            if (role == 'super_admin') {
              return const AdminDashboardPage();
            }
            */
            // 👤 NORMAL USER
            return const DashboardPage();
          },
        );
      },
    );
  }
}
