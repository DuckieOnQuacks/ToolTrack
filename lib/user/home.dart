import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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

  void showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
          content: const Text('Are you sure you want to log out of your account?'),
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
              icon: const Icon(Icons.logout, size: 24),
              tooltip: 'Logout',
              onPressed: (){showLogoutConfirmationDialog(context);}
            ),
          ),
        ],
      ),
    );
  }
}
