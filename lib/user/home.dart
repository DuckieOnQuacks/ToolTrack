import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:vineburgapp/admin/bottom_bar.dart';
import 'package:vineburgapp/backend/message_helper.dart';
import 'package:vineburgapp/user/return_tool.dart';
import 'scan_workorder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CameraDescription>? cameras;
  bool isLoadingCameras = true;

  void showIssueDialog(BuildContext context) {
    TextEditingController helpController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Leave a Note"),
          content: TextField(
            controller: helpController,
            decoration: const InputDecoration(
              hintText: "Describe the issue or leave a note...",
            ),
            maxLines: 4,
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String note = helpController.text.trim();
                if (note.isNotEmpty) {
                  try {
                    await FirebaseFirestore.instance.collection('Issues').add({
                      'note': note,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    Navigator.of(context).pop();
                    showTopSnackBar(context, "Note successfully submitted!", Colors.green, title: "Success", icon: Icons.check_circle);
                  } catch (e) {
                    if (kDebugMode) {
                      print('Error saving note: $e');
                    }
                    showTopSnackBar(context, "Failed to submit note please try again.", Colors.orange, title: "Warning:", icon: Icons.warning);
                  }
                } else {
                  showTopSnackBar(context, "Please enter a note before submitting", Colors.orange, title: "Warning:", icon: Icons.warning);
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void showAdminPasswordDialog(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text("Admin Login"),
              content: TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: "Enter admin password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  ),
                ),
                obscureText: obscureText,
              ),
              actions: <Widget>[
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.redAccent,
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String password = passwordController.text.trim();
                    try {
                      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: 'admin@vineburg.com',
                        password: password,
                      );
                      if (userCredential.user != null) {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) => const AdminBottomBar(),
                          ),
                        );
                      } else {
                        showTopSnackBar(context, "Invalid credentials", Colors.red, title: "Error", icon: Icons.error);
                      }
                    } catch (e) {
                      showTopSnackBar(context, "Invalid credentials", Colors.red, title: "Error", icon: Icons.error);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      setState(() {
        cameras = availableCameras;
        isLoadingCameras = false;
      });
    }).catchError((e) {
      if (kDebugMode) {
        print('Error initializing cameras: $e');
      }
      setState(() {
        isLoadingCameras = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: isLoadingCameras
                ? Lottie.asset(
              'assets/lottie/loading.json',
              width: 150,
              height: 150,
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build, size: 187.5, color: Colors.orange[800]),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: cameras == null || cameras!.isEmpty
                      ? null
                      : () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ScanWorkorderPage(cameras!, 'checkout')));
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange[800],
                    shadowColor: Colors.black,
                    elevation: 12,
                    textStyle: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Checkout Tool'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: cameras == null || cameras!.isEmpty
                      ? null
                      : () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ReturnToolPage(cameras!, 'return')));
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red[800],
                    shadowColor: Colors.black,
                    elevation: 12,
                    textStyle: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Return Tool'),
                ),
              ],
            ),
          ),
          // Help and Leave a Note combined button in the top left
          Positioned(
            top: 25,
            left: 5,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.menu, size: 28, color: Colors.white),
              tooltip: 'Help & Note',
              onSelected: (String result) {
                switch (result) {
                  case 'Instructions':
                    showInstructionsDialog(context);
                    break;
                  case 'Leave a Note':
                    showIssueDialog(context);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Instructions',
                  child: ListTile(
                    leading: Icon(Icons.info_outline, color: Colors.blue),
                    title: Text('Instructions'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'Leave a Note',
                  child: ListTile(
                    leading: Icon(Icons.note_add, color: Colors.orange),
                    title: Text('Leave a Note'),
                  ),
                ),
              ],
              color: Colors.grey[900],
            ),
          ),
          // Admin button in the top right
          Positioned(
            top: 25,
            right: 5,
            child: IconButton(
              icon: const Icon(Icons.admin_panel_settings, size: 24, color: Colors.white),
              tooltip: 'Admin Login',
              onPressed: () {
                showAdminPasswordDialog(context);
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
    );
  }
}
