import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vineburgapp/user/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await signInDefaultUser();
  runApp(const MyApp());
}

Future<void> signInDefaultUser() async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: 'user@vineburg.com',
      password: '1234567', // Replace with the actual password
    );
  } catch (e) {
    print('Failed to sign in with default user: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey,
        hintColor: Colors.grey,
        scaffoldBackgroundColor: Colors.black54,
        appBarTheme: AppBarTheme(
          color: Colors.blueGrey[900],
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.grey,
          textTheme: ButtonTextTheme.primary,
        ),
      ),
      home: const HomePage(),
    );
  }
}
