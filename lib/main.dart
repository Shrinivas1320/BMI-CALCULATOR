import 'package:flutter/material.dart';
import 'pages/login_screen.dart';
import 'pages/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? username;

  void handleLogin(String user) {
    setState(() {
      username = user;
    });
  }

  void handleLogout() {
    setState(() {
      username = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: username == null
          ? LoginScreen(onLogin: handleLogin)
          : HomeScreen(username: username!, onLogout: handleLogout),
    );
  }
}