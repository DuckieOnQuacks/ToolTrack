import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vineburgapp/admin/tools.dart';
import 'package:vineburgapp/user/home.dart';
import 'backend/messageHelper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // All code on this page was developed by the team using the flutter framework
  late final TextEditingController usernameController = TextEditingController();
  late final TextEditingController passwordController = TextEditingController();
  String? usernameErrorMessage;
  String? passwordErrorMessage;

  String createUsername(String username) {
    String formattedUsername =
        username.trim().replaceAll(' ', '_').toLowerCase();
    return '$username@vineburg.com';
  }

  void signUserIn() async {
    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
    try {
      if (validateFields()) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: createUsername(usernameController.text),
            password: passwordController.text);

        String userEmail = FirebaseAuth.instance.currentUser!.email!;
        MaterialPageRoute newPage;

        // Check if the user is an admin
        if (userEmail == 'admin@vineburg.com') {
          newPage = MaterialPageRoute(builder: (context) => const AdminToolsPage());
        } else {
          newPage = MaterialPageRoute(builder: (context) => const HomePage());
        }

        if (mounted) {
          setState(() {
            Navigator.of(context).push(newPage);
          });
        }
      } else {
        Navigator.pop(context);
        showMessage(context, 'Error', 'Please insert log in credentials');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        Navigator.pop(context);
        if (e.code == 'invalid-email') {
          showMessage(context, 'Error', 'Please enter a valid email');
        } else if (e.code == 'wrong-password') {
          showMessage(context, 'Error', 'Wrong password');
        } else if (e.code == 'user-not-found') {
          showMessage(context, 'Error',
              'This email address entered is not registered.');
        } else {
          showMessage(context, 'Error', 'An unexpected error occurred');
        }
      }
    }
  }

  bool validateFields() {
    bool valid = true;
    setState(() {
      usernameErrorMessage = null;
      passwordErrorMessage = null;

      if (passwordController.text.isEmpty ||
          passwordController.text.length < 6) {
        passwordErrorMessage =
            'Please enter a password with at least 6 characters';
        valid = false;
      }
    });
    return valid;
  }

  @override
  Widget build(BuildContext context) {
    // The login page scaffold
    return Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: SafeArea(
            top: true,
            child: Center(
                child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
              Image.asset(
                'assets/images/drilling.png',
                scale: 3,
              ),
              const SizedBox(height: 50),
              //Creates space between text
               Text(
                'Welcome to Tool Tracker',
                style: GoogleFonts.signika(fontSize: 35.0, fontWeight: FontWeight.bold)
                  //TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              //email text field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: const TextStyle(
                          fontSize: 18, // Change the font size as needed
                          color: Colors.black, // You can also change the color, weight, etc.
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Rest of your decoration like hintText if needed
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              //Create Space between both boxes
              //Password text field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: const TextStyle(
                          fontSize: 18, // Change the font size as needed
                          color: Colors.black, // You can also change the color, weight, etc.
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        // Rest of your decoration like hintText if needed
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navigator.push(context,
                        //MaterialPageRoute(builder: (context) {
                        //return ResetPasswordPage();
                        //}));
                      },
                      child: const Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              //sign in button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      signUserIn();
                    });
                  },
                  style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                          const EdgeInsets.all(20)),
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.black87),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                  color: Colors.black!, width: 1)))),
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
              ),
              const SizedBox(height: 5),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Dont have an account?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ])))));
  }
}
