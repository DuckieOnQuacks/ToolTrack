import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:core';
import 'backend/message_helper.dart';
import 'backend/user_helper.dart';
import 'login.dart';

// Object Cleanup, removes from tree permanently
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

// Register
class _RegisterPageState extends State<RegisterPage> {
  // All code on this page was developed by the team using the flutter framework
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController firstName = TextEditingController();
  List<String> tempTools = [""];
  List<String> tempFavOrders = [""];

  // Capitalize the first letter of the firstname and lastname
  String capitalize(String s) =>
      s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1).toLowerCase();

  void createAccount() async {
    if (passwordController.text.isEmpty ||
        confirmPassword.text.isEmpty ||
        firstName.text.isEmpty) {
      showMessage(context, 'Notice', 'Please complete all fields.');
      return;
    }

    try {
      // Check if password is confirmed
      if (passwordController.text == confirmPassword.text) {
        // Check if length of passwords entered are greater than 6
        if (passwordController.text.length > 6 &&
            confirmPassword.text.length > 6) {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: createUsername(firstName.text),
            password: passwordController.text,
          );

          // Capitalize first and last name before storing
          String capitalizedFirstName = capitalize(firstName.text);
          addUserDetails(capitalizedFirstName);
          Navigator.pop(context);
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (BuildContext context) {
            return const LoginPage();
          }));
        } else {
          // Show error message if password length is not greater than 6
          showMessage(
              context, 'Notice', 'Password must be at least 7 characters.');
        }
      } else {
        // Show error message if passwords don't match
        showMessage(context, 'Notice', 'Passwords do not match!');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        showMessage(context, 'Notice', 'Username already in use.');
      } else {
        await showErrorMessage(e.code);
      }
    }
  }

  // error message box
  // Show error message if password or email is invalid
  Future<void> showErrorMessage(String message) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the AlertDialog
              },
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    passwordController.dispose();
    confirmPassword.dispose();
    firstName.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The register page scaffold
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10), // Creates space between text
                Text('Create New Account',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 50,
                      color: Colors.white,
                    )),
                const SizedBox(height: 20),
                // firstname text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: firstName,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'First Name',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Password text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: passwordController,
                        obscureText: true, // Hides password text
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // Create Space between both boxes

                // Confirm password text field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.grey[700]!),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: TextField(
                        controller: confirmPassword,
                        obscureText: true, // Hides password text
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Confirm Password',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25), // Create Space between both boxes
                // Create account button

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: ElevatedButton(
                    onPressed: () {
                      createAccount();
                    },
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(25)),
                      backgroundColor: MaterialStateProperty.all<Color>(
                          Colors.orange.shade800),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side:
                                BorderSide(color: Colors.grey[900]!, width: 3)),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (BuildContext context) {
                            return const LoginPage();
                          }),
                        );
                      },
                      child: const Text(
                        'Sign In',
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
