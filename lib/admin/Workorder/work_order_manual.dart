import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../../backend/camera_preview_helper.dart';
import '../../backend/message_helper.dart';
import '../../backend/user_helper.dart';
import '../../classes/work_order_class.dart';

class AdminWorkOrderManualEntry extends StatefulWidget {

  const AdminWorkOrderManualEntry({super.key});

  @override
  State<StatefulWidget> createState() => _AdminWorkOrderManualEntry();
}

class _AdminWorkOrderManualEntry extends State<AdminWorkOrderManualEntry> {
  late final User user = FirebaseAuth.instance.currentUser!; // Get current user
  final TextEditingController _PartNameController = TextEditingController();
  final TextEditingController _PONumberController = TextEditingController();
  final TextEditingController _PartNumberController = TextEditingController();
  final TextEditingController _EnteredByController = TextEditingController();
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
      fullName = getUserFullName();
      fullName.then((name) {
        _EnteredByController.text = name; // Assuming this fetches and sets the user's name
      });
    });
  }

  bool _isFormFilled() {
    return _PartNameController.text.isNotEmpty &&
        _PONumberController.text.isNotEmpty &&
        _PartNumberController.text.isNotEmpty &&
        imagePath.isNotEmpty; // Assuming imagePath must also be non-empty
  }


  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 150 || MediaQuery.of(context).size.height < 300) ? 150.0 : 300.0; // Adjust the size of scan area here
    var cutOutSize = scanArea * 0.6; // Make cutout size smaller than the scan area

      return Scaffold(
        appBar: AppBar(
          title: const Text('Enter Work Order Details'),
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
                          'Take A Picture Of The Workorder:* ',
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
                          'Enter Part Name: *',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextField(
                          controller: _PartNameController,
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
                          'Enter Po Number: *',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextField(
                          controller: _PONumberController,
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
                          'Enter Part Number: *',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextField(
                          controller: _PartNumberController,
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
                          'Current User:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8), // Add some spacing between the label and the TextField
                        TextField(
                          controller: _EnteredByController,
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                          ),
                          readOnly: true, // Make it read-only if just displaying
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isFormFilled() ? () async {
                          if (!mounted) return;
                            String imageUrl = await uploadImage(imagePath);
                            // Use the parts as parameters for addWorkOrderWithParams
                            await addWorkOrderWithParams(
                                _PartNameController.text, // partName
                                _PONumberController.text, // po
                                _PartNumberController.text, // partNum
                                imageUrl,
                                false,
                                [""],
                                "Active"
                            );
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            //await widget.onWorkOrderAdded();
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      }
                      : null,
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                        onPrimary: Colors.white,
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
