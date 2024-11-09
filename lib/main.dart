import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'sign_in_screen.dart';
import 'create_account_screen.dart';
import 'dashboard_screen.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb
        ? FirebaseOptions(
            apiKey: "AIzaSyC1y1QZc5niptc8kOif1LsPGedhTzL8MiM",
            authDomain: "flutterproj-56250.firebaseapp.com",
            projectId: "flutterproj-56250",
            storageBucket: "flutterproj-56250.appspot.com",
            messagingSenderId: "162930788272",
            appId: "1:162930788272:web:002dd8a3df9ea6790f7875",
            measurementId: "G-MZ8XVKQGS7",
          )
        : null,
  );
  Intl.defaultLocale = 'en_US';
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Login UI',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          labelLarge: TextStyle(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.yellow,
        scaffoldBackgroundColor: Colors.grey[850],
        textTheme: const TextTheme(
          labelLarge: TextStyle(color: Colors.white), // Corrected text style
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute:
          FirebaseAuth.instance.currentUser == null ? '/' : '/dashboard',
      routes: {
        '/': (context) => const LoginScreen(),
        '/signIn': (context) => const SignInScreen(),
        '/createAccount': (context) => const CreateAccountScreen(),
        '/dashboard': (context) => DashboardScreen(
              toggleTheme: _toggleTheme,
              isDarkMode: _isDarkMode,
            ),
      },
    );
  }
}