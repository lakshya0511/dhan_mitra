import 'package:flutter/material.dart';
import '../main.dart';
import 'app_navigator.dart';

class Utils {
  static void showSnackBar(String message) {
    final context = navigatorKey.currentContext;

    if (context == null) {
      // 🔒 App is rebuilding / no scaffold yet
      debugPrint("SnackBar skipped: $message");
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }
}
