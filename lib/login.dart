import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:vineburgapp/admin/tools/tools.dart';
import 'package:vineburgapp/register.dart';
import 'package:vineburgapp/user/home.dart';
import 'admin/bottom_bar.dart';
import 'backend/message_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController usernameController = TextEditingController();
  late final TextEditingController passwordController = TextEditingController();
  String? usernameErrorMessage;
  String? passwordErrorMessage;

  String createUsername(String username) {
    String formattedUsername =
    username.trim().replaceAll(' ', '_').toLowerCase();
    return '$formattedUsername@vineburg.com';
  }

  void signUserIn() async {
    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: Lottie.asset(
            'assets/lottie/loading.json',
            width: 150,
            height: 150,
            fit: BoxFit.fill,
          ),
        );
      },
    );

    try {
      if (validateFields()) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: createUsername(usernameController.text.trim()),
          password: passwordController.text,
        );

        String userEmail = FirebaseAuth.instance.currentUser!.email!;
        MaterialPageRoute newPage;

        if (userEmail == 'admin@vineburg.com') {
          newPage = MaterialPageRoute(builder: (context) => const AdminBottomBar());
        } else {
          newPage = MaterialPageRoute(builder: (context) => const HomePage());
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(newPage);
        }
      } else {
        Navigator.pop(context);
        showTopSnackBar(context, 'Error: Please insert log in credentials', Colors.red);
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      String errorMessage;
      if (e.code == 'invalid-email') {
        errorMessage = 'Error: Please enter a valid email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Error: Wrong password';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'Error: Email address entered is not registered';
      } else {
        errorMessage = 'Error: ${e.message}';
      }
      showTopSnackBar(context, errorMessage, Colors.red);
    } catch (e) {
      Navigator.pop(context);
      showTopSnackBar(context, 'Error: An unexpected error has occurred', Colors.red);
    }
  }

  bool validateFields() {
    bool valid = true;
    setState(() {
      usernameErrorMessage = null;
      passwordErrorMessage = null;

      if (usernameController.text.isEmpty) {
        usernameErrorMessage = 'Please enter your username';
        valid = false;
      }
      if (passwordController.text.isEmpty || passwordController.text.length < 6) {
        passwordErrorMessage = 'Please enter a password with at least 6 characters';
        valid = false;
      }
    });
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/drilling.png',
                  scale: 2.5,
                ),
                const SizedBox(height: 50),
                Text(
                  'Welcome To Tool Tracker',
                  style: GoogleFonts.signika(
                    fontSize: 50.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        labelText: 'Username',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                        errorText: usernameErrorMessage,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        labelText: 'Password',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[800],
                        errorText: passwordErrorMessage,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: signUserIn,
                  style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(20)),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.orange.shade800),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (BuildContext context) {
                            return const RegisterPage();
                          },
                        ));
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
