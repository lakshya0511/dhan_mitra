import 'package:flutter/material.dart';
import 'LoginWidget.dart';
import 'sign_up.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLogin = true;

  void toggle() {
    setState(() => showLogin = !showLogin);
  }

  @override
  Widget build(BuildContext context) {
    return showLogin
        ? LoginWidget(onClickedSignUp: toggle)
        : SignUpWidget(onClickedSignIn: toggle);
  }
}
