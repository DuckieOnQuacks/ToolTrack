/*import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../backend/camera_preview_helper.dart';
import '../../backend/message_helper.dart';
import '../../classes/tool_class_new.dart';

class AdminScanToolPage extends StatefulWidget {
  final Function onToolAdded;
  const AdminScanToolPage({super.key, required this.onToolAdded});


  @override
  State<StatefulWidget> createState() => _AdminScanToolPage();
}

class _AdminScanToolPage extends State<AdminScanToolPage> {
  late final User user = FirebaseAuth.instance.currentUser!; // Get current user
  final TextEditingController _GageIDController = TextEditingController();
  final TextEditingController _CalFreqController = TextEditingController();
  final TextEditingController _CalNextDueController = TextEditingController();
  final TextEditingController _CalLastController = TextEditingController();
  final TextEditingController _DateCreatedController = TextEditingController();
  final TextEditingController _GageTypeController = TextEditingController();
  final TextEditingController _GageDescController = TextEditingController();
  final TextEditingController _DaysRemainController = TextEditingController();


  late Future<String> fullName; // Future to hold the full name

  late List<CameraDescription> cameras;
  String imagePath = '';
  String imageUrl = '';
  int pictureTaken = 0;
  String toolName = "";


  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
    });
  }

  bool _isFormFilled() {
    return _GageIDController.text.isNotEmpty &&
        imagePath.isNotEmpty; // Assuming imagePath must also be non-empty
  }


  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 150 || MediaQuery.of(context).size.height < 300) ? 150.0 : 300.0; // Adjust the size of scan area here
    var cutOutSize = scanArea * 0.6; // Make cutout size smaller than the scan area

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Tool Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Take A Picture Of The Tool:* ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, size: 40, color: Colors.blue),
                        onPressed: () async {
                          imagePath = await openCamera(context);
                          if (imagePath != 'null') {
                            setState(() {
                              pictureTaken = 1;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Gage ID: *',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: _GageIDController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {}); // This triggers a rebuild, which will refresh the button's state
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Creation Date: *',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: _DateCreatedController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {}); // This triggers a rebuild, which will refresh the button's state
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Gage Description: *',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: _GageDescController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {}); // This triggers a rebuild, which will refresh the button's state
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gage Type: ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8), // Add some spacing between the label and the TextField
                      TextField(
                        controller: _GageTypeController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),// Make it read-only if just displaying
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calibration Frequency: ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8), // Add some spacing between the label and the TextField
                      TextField(
                        controller: _CalFreqController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calibration Next Due: ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8), // Add some spacing between the label and the TextField
                      TextField(
                        controller: _CalNextDueController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Days Remaining Until Calibration: ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8), // Add some spacing between the label and the TextField
                      TextField(
                        controller: _DaysRemainController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calibration Last Completed: ',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8), // Add some spacing between the label and the TextField
                      TextField(
                        controller: _CalLastController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isFormFilled() ? () async {
                      if (!mounted) return;
                      String imageUrl = await uploadImage(imagePath);
                      // Use the parts as parameters for addWorkOrderWithParams
                      await addToolWithParams(
                          _CalFreqController.text,
                          _CalLastController.text,
                          _CalNextDueController.text,
                          _DateCreatedController.text,
                          _GageIDController.text,
                          _GageTypeController.text,
                          imageUrl,
                          _GageDescController.text,
                          _DaysRemainController.text,
                      );
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      //await widget.onWorkOrderAdded();
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.blue,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> openCamera(BuildContext context) async {
    // Ensure that there is a camera available on the device
    if (cameras.isEmpty) {
      showMessage(context, 'Uh Oh!', 'Camera not available');
      return 'null';
    }

    // Check if the user has granted camera permission
    PermissionStatus cameraPermission = await Permission.camera.status;
    if (cameraPermission != PermissionStatus.granted) {
      // Request camera permission
      PermissionStatus permissionStatus = await Permission.camera.request();
      if (permissionStatus == PermissionStatus.denied) {
        // Permission denied show warning
        showWarning2(context, "App require access to camera... Press allow camera to allow the camera.");
        // Request camera permission again
        PermissionStatus permissionStatus2 = await Permission.camera.request();
        if (permissionStatus2 != PermissionStatus.granted) {
          // Permission still not granted, return null
          showMessage(context, 'Uh Oh!', 'Camera permission denied');
          return 'null';
        }
      } else if (permissionStatus != PermissionStatus.granted) {
        // Permission not granted, return null
        showMessage(context, 'Uh Oh!', 'Camera permission denied');
        return 'null';
      }
    }

    // Take the first camera in the list
    CameraDescription camera = cameras[0];

    // Open the camera and store the resulting CameraController
    CameraController controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();

    // Navigate to the CameraScreen and pass the CameraController to it
    String? imagePath = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPreviewHelper(controller,
        ),
      ),
    );

    if (imagePath == null || imagePath.isEmpty) {
      return 'null';
    }
    return imagePath;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String> uploadImage(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      String fileExtension = imageFile.uri.pathSegments.last.split('.').last;
      String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      Reference storageRef = FirebaseStorage.instance.ref();
      Reference imageRef = storageRef.child('ToolImages/$uniqueFileName');
      await imageRef.putFile(imageFile);
      imageUrl = await imageRef.getDownloadURL();
      if (kDebugMode) {
        print('Image uploaded successfully: $imageUrl');
      }
      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading image: $e');
      }
      return '';
    }
  }
}
*/