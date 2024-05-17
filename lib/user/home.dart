import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vineburgapp/classes/toolClass.dart';
import 'scanWorkorder.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CameraDescription> cameras;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, size: 125, color: Colors.orange[800]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: cameras.isEmpty ? null : () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ScanWorkorderPage(cameras, 'checkout')
                ));
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.orange[800], // Text and Icon color
                shadowColor: Colors.black, // Shadow color
                elevation: 12, // Shadow elevation
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Checkout Tool'),
            ),
            const SizedBox(height: 20), // Add space between buttons
            ElevatedButton(
              onPressed: cameras.isEmpty ? null : () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ScanWorkorderPage(cameras, 'return')
                ));
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.red[800], // Text and Icon color
                shadowColor: Colors.black, // Shadow color
                elevation: 12, // Shadow elevation
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Return Tool'),
            ),
          ],
        ),
      ),
    );
  }
}
