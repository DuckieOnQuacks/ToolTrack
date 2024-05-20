import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vineburgapp/classes/toolClass.dart';
import '../login.dart';
import 'scanWorkorder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CameraDescription>? cameras;
  bool isLoadingCameras = true;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      setState(() {
        cameras = availableCameras;
        isLoadingCameras = false;
      });
    }).catchError((e) {
      print('Error initializing cameras: $e');
      setState(() {
        isLoadingCameras = false;
      });
    });
  }

  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to LoginPage
      );
    } catch (e) {
      print('Error logging out: $e');
      // Optionally, show an error message to the user
    }
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
              width: 200,
              height: 200,
            ) // Show Lottie animation while cameras are being initialized
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build, size: 187.5, color: Colors.orange[800]), // Increased by 50%
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: cameras == null || cameras!.isEmpty ? null : () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ScanWorkorderPage(cameras!, 'checkout')
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.orange[800], // Text and Icon color
                    shadowColor: Colors.black, // Shadow color
                    elevation: 12, // Shadow elevation
                    textStyle: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold), // Increased font size by 50%
                    padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 30), // Increased padding by 50%
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Checkout Tool'),
                ),
                const SizedBox(height: 20), // Add space between buttons
                ElevatedButton(
                  onPressed: cameras == null || cameras!.isEmpty ? null : () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ScanWorkorderPage(cameras!, 'return')
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red[800], // Text and Icon color
                    shadowColor: Colors.black, // Shadow color
                    elevation: 12, // Shadow elevation
                    textStyle: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold), // Increased font size by 50%
                    padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 30), // Increased padding by 50%
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Return Tool'),
                ),
              ],
            ),
          ),
          // Logout button in the top-right corner
          Positioned(
            top: 25,
            right: 5,
            child: IconButton(
              icon: const Icon(Icons.logout, size: 24), // Increased by 50%
              tooltip: 'Logout',
              onPressed: logout,
            ),
          ),
        ],
      ),
    );
  }
}
