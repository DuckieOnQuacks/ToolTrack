import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../admin/bottom_bar.dart';
import '../login_page.dart';
import '../user/bottom_bar.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // Check if the signed-in user is an admin
            if (snapshot.data!.email == 'admin123@vineburg.com') {
              return const AdminBottomBar();
            } else {
              return const BottomBar();
            }
          } else {
            // If the user is not signed in, show the login screen
            return const LoginPage();
          }
        },
      ),
    );
  }
}
