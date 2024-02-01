import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:core';
import 'backend/message_helper.dart';
import 'backend/user_helper.dart';
import 'login_page.dart';

//Object Cleanup, removes from tree permanently
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

//Register
class _RegisterPageState extends State<RegisterPage> {
  // All code on this page was developed by the team using the flutter framework
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();
  List<String> tempTools = [""];
  List<String> tempFavOrders = [""];

  //Capitalize the first letter of the firstname and lastname
  String capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1).toLowerCase();

  void createAccount() async {
    if (passwordController.text.isEmpty || confirmPassword.text.isEmpty || firstName.text.isEmpty || lastName.text.isEmpty) {
      showMessage(context, 'Notice', 'Please complete all fields.');
      return;
    }

    try {
      // Check if password is confirmed
      if (passwordController.text == confirmPassword.text) {
        // Check if length of passwords entered are greater than 6
        if (passwordController.text.length > 6 && confirmPassword.text.length > 6) {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: createUsername(firstName.text, lastName.text),
            password: passwordController.text,
          );

          // Capitalize first and last name before storing
          String capitalizedFirstName = capitalize(firstName.text);
          String capitalizedLastName = capitalize(lastName.text);

          addUserDetails(capitalizedFirstName, capitalizedLastName, tempTools, tempFavOrders);
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
            return const LoginPage();
          }));
        } else {
          // Show error message if password length is not greater than 6
          showMessage(context, 'Notice', 'Password must be at least 7 characters.');
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

  //error message box
  //Show error message if password or email is invalid
  Future<void> showErrorMessage(String message) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.black),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the AlertDialog
              },
              child: const Text('Close'),
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
    lastName.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The login page scaffold
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.grey[200],
        body: SafeArea(
            child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //Image.asset(
                      //  'assets/images/robotics.png',
                      //  scale: 5,
                      //),
                      const SizedBox(height: 10), //Creates space between text
                      Text('Sign up new account',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 40,
                          )),
                      const SizedBox(height: 20),
                      //firstname text field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: TextField(
                              controller: firstName,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'First Name',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), //Create Space between both boxes

                      //Last name text field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: TextField(
                              controller: lastName,
                              obscureText: false,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Last Name',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      //Password text field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: TextField(
                              controller: passwordController,
                              obscureText: true, //Hides password text
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Password',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), //Create Space between both boxes

                      //email text field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: TextField(
                              controller: confirmPassword,
                              obscureText: true, //Hides password text
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Confirm Password',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25), //Create Space between both boxes
                      //Create account button

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: ElevatedButton(
                          onPressed: () {
                            createAccount();
                          },
                          style: ButtonStyle(
                              padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                                  const EdgeInsets.all(25)),
                              backgroundColor:
                              MaterialStateProperty.all<Color>(

                                Colors.grey,
                              ),
                              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.grey[900]!,
                                          width: 3)
                                  )
                              )
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
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (BuildContext context) {
                                    return const LoginPage();
                                  }));
                            },
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ))));
  }
}