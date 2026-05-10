import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';

import 'components/wrapper.dart';
import 'components/app_theme.dart';
import 'components/app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      //
    ),
  );

  runApp(const MoneyMitraApp());
}

class MoneyMitraApp extends StatefulWidget {
  const MoneyMitraApp({super.key});

  @override
  State<MoneyMitraApp> createState() => _MoneyMitraAppState();

  static _MoneyMitraAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MoneyMitraAppState>();
}

class _MoneyMitraAppState extends State<MoneyMitraApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Money Mitra',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,

      home: Builder(
        builder: (context) {
          final bgColor = Theme.of(context).scaffoldBackgroundColor;

          return Scaffold(
            backgroundColor: bgColor,
            body: AnimatedSplashScreen(
              splash: "assets/logo.png",
              splashIconSize: 380,
              backgroundColor: Colors.transparent,
              nextScreen: const Wrapper(),
              duration: 500,
              splashTransition: SplashTransition.scaleTransition,
              pageTransitionType: PageTransitionType.fade,
            ),
          );
        },
      ),
    );
  }
}

