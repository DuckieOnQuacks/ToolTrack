import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vineburgapp/user/home.dart';
import '../admin/tools.dart';
import '../login.dart';

/*
* Authorization page responsible for checking to see
* if the current user is signed in or not. The auto login is
* reset if the app is removed and then installed again
*
* Also checks if the current user is an admin or not.
*/
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
            if (snapshot.data!.email == 'admin@vineburg.com') {
              return const AdminToolsPage();
            } else {
              return const HomePage();
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
