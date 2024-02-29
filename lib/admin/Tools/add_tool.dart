import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:vineburgapp/backend/camera_preview_helper.dart';
import '../../backend/message_helper.dart';
import '../../classes/tool_class.dart';
import '../../classes/user_class.dart';

class AdminScanToolPage extends StatefulWidget {
  //Callback to notify tool list to refresh after tool is added.
  final Function onToolAdded;

  const AdminScanToolPage({super.key, required this.onToolAdded});

  @override
  State<StatefulWidget> createState() => _AdminScanPageState();
}

class _AdminScanPageState extends State<AdminScanToolPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late final User user = FirebaseAuth.instance.currentUser!; // Get current user
  final TextEditingController _calibrationDate = TextEditingController(); // Controller for machine number input
  late Future<String> fullName; // Future to hold the full name
  Barcode? result;
  late List<CameraDescription> cameras;
  String imagePath = '';
  String imageUrl = '';
  int pictureTaken = 0;
  String toolName = '';
  QRViewController? controller;
  String machineNumber = ''; // Variable to store machine number
  bool _isScanned = false; // Add a new flag for scanning status
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
    });
    fullName =
        getUserFullName(); // Fetch the full name when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 150 || MediaQuery.of(context).size.height < 300) ? 150.0 : 300.0; // Adjust the size of scan area here
    var cutOutSize = scanArea * 0.6; // Make cutout size smaller than the scan area

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tool To Database'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
          Visibility(
            visible: !_isScanned,
            child: Center(
              child: SizedBox(
                width: scanArea,
                height: scanArea,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.red,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: cutOutSize,
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: _isScanned,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Display the image if it exists, otherwise show the option to take a picture
                      if (imagePath.isNotEmpty &&
                          File(imagePath).existsSync())
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'Image Of Tool:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Image.file(
                                File(imagePath),
                                width: 300, // Set a fixed width for the image
                                height: 450, // Set a fixed height for the image
                                fit: BoxFit.cover,
                              ),
                            ],
                          ),
                        )
                      else
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
                              icon: const Icon(Icons.camera_alt,
                                  size: 40, color: Colors.blue),
                              onPressed: () async {
                                imagePath = (await openCamera(context))!;
                                if (imagePath.isNotEmpty) {
                                  setState(() {
                                    pictureTaken = 1;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0), // Reduced top padding
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Tool Name: ',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                toolName.isEmpty ? 'Not Scanned' : toolName,
                            style: const TextStyle(
                                fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<String>(
                      future: fullName,
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.done) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else if (snapshot.hasData) {
                            return RichText(
                              text: TextSpan(
                                text: 'Current User: ',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: snapshot.data,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                        return const CircularProgressIndicator(); // Show a loading spinner while waiting for the data
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_isScanned) // Show the following widgets only after QR code is scanned
            Padding(
              padding: const EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'Calibration Date:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate, // Refer to the current selected date
                    firstDate: DateTime(2020), // Limits the earliest date
                    lastDate: DateTime(2025), // Limits the latest date
                  );
                  if (picked != null && picked != selectedDate) {
                    setState(() {
                      selectedDate = picked;
                      // Update the text field with the formatted date
                      _calibrationDate.text = DateFormat('MM/dd/yy').format(picked);
                    });
                  }
                },
                child: AbsorbPointer( // Prevents the keyboard from showing
                  child: TextField(
                    controller: _calibrationDate,
                    decoration: const InputDecoration(
                      hintText: 'Enter calibration date',
                      hintStyle: TextStyle(fontSize: 16),
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ),
              ],
              ),
            ),
          const SizedBox(height: 20),
            Visibility(
              visible: _isScanned, // Show the button only after QR code is scanned
              child: ElevatedButton(
                onPressed: imagePath.isNotEmpty && _calibrationDate.text.isNotEmpty ? () async {
                  String imageUrlSend = await uploadImage(imagePath);
                  Tool newTool = Tool(
                    toolName: toolName,
                    personCheckedTool: '',
                    whereBeingUsed: '',
                    calibrationDate: _calibrationDate.text,
                    imagePath: imageUrlSend,
                    personAddedTool: await getUserFullName(),
                  );
                  await newTool.addToolToCollection(newTool);
                  widget.onToolAdded();
                  Navigator.pop(context);
                }
                    : () {
                  if (imagePath.isEmpty) {
                    showMessage(context, 'Image Required', 'Please take a picture of the tool.');
                  } else if (_calibrationDate.text.isEmpty) {
                    showMessage(context, 'Date Required', 'Please enter the calibration date.');
                  }
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // Button color
                  onPrimary: Colors.white, // Text color
                  elevation: 5, // Button shadow
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                ),
                child: const Text('Submit'),
              ),
            ),
        ],
      ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        toolName =
            result!.code!; // Assuming the QR code contains just the tool name
        _isScanned = true; // Set the flag to true when QR code is scanned
      });
    });
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

    CameraController controller = CameraController(
      cameras[0], // Assuming `cameras` is already populated
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();

    // Navigate to the ScanTool widget instead of CameraScreen
    String? imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => CameraPreviewHelper(controller),
      ),
    );

    // Dispose the controller after coming back from the ScanTool
    await controller.dispose();

    if (imagePath == null || imagePath.isEmpty) {
      return 'null';
    }
    return imagePath;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<String> uploadImage(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      String fileExtension = imageFile.uri.pathSegments.last.split('.').last;
      String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
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
