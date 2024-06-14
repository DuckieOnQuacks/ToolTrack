import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:vineburgapp/backend/message_helper.dart';
import 'package:vineburgapp/user/return_tool.dart';
import '../classes/tool_class.dart';
import '../login.dart';
import 'scan_workorder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CameraDescription>? cameras;
  bool isLoadingCameras = true;

  void showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          buttonPadding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: const Text('Log out of user account?'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black54,
                backgroundColor: Colors.grey[300],
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => const LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }

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
                    showTopSnackBar(context, "Note succesfully submitted!", Colors.green, title: "Success", icon: Icons.check_circle);
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

  void showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "Help",
            style: TextStyle(color: Colors.white),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Checkout Tool:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "1. Select 'Checkout Tool'.",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "2. Scan or manually enter workorder ID",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "3. Scan or manually enter the Bin name",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "4. Enter your employee ID, machine ID and confirm checkout.",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "5. Confirm that the tool was checked out successfully",
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 10),
                Text(
                  "Return Tool:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "1. Select 'Return Tool'.",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "2. Scan or manually enter bin QR code.",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "3. Select the tool you're returning from the list. If its not there you most likely scanned the wrong bin.",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "4. Confirm that the tool was returned successfully.",
                  style: TextStyle(color: Colors.white70),
                ),
                SizedBox(height: 10),
                Text(
                  "Barcode or QR code not scanning?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "1. Tap the 'pencil' icon to manually enter Workorder ID or Bin name",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "2. Workorders are manually entered by ID",
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  "3. Bins are manually entered by bin name",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Close'),
            ),
          ],
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
          // Instructions button in the top left
          Positioned(
            top: 25,
            left: 5,
            child: IconButton(
              icon: const Icon(Icons.info_outline, size: 24),
              tooltip: 'Instructions',
              onPressed: () {
                showInstructionsDialog(context);
              },
            ),
          ),
          Positioned(
            top: 25,
            right: 5,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.report, size: 24),
                  tooltip: 'Leave an issue report',
                  onPressed: () {
                    showIssueDialog(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 24),
                  tooltip: 'Logout',
                  onPressed: () {
                    showLogoutConfirmationDialog(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
