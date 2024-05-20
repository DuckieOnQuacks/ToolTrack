import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'backend/auth.dart';

Future<void> main() async {
  // Ensuring that the widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initializing Firebase
  await Firebase.initializeApp();
  // Running the MyApp widget
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dark Mode Demo',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        hintColor: Colors.grey,
        scaffoldBackgroundColor: Colors.black54,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        appBarTheme: AppBarTheme(
          color: Colors.blueGrey[900],
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.grey,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: const AuthPage(),  // Updated to navigate to AuthPage
    );
  }
}