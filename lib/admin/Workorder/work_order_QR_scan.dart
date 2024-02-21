import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:vineburgapp/admin/Workorder/work_order_manual.dart';
import 'package:vineburgapp/backend/message_helper.dart';
import '../../classes/work_order_class.dart';

class QRScan extends StatefulWidget {
  final Function onWorkOrderAdded;
  final CameraController controller;

  const QRScan(this.controller, {super.key, required this.onWorkOrderAdded});

  @override
  _QRScan createState() => _QRScan();
}

class _QRScan extends State<QRScan> {
  double cameraWidth = 350; // Default width
  double cameraHeight = 600; // Default height
  bool _isFlashOn = false; // Track if flash is on or off


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
            // Navigator.of(context).pushReplacementNamed('/desiredRoute');
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 350, // Default width
              height: 600, // Default height
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 3),
                borderRadius: BorderRadius.circular(20), // Added rounded corners
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20), // Clip it to have rounded corners
                child: CameraPreview(widget.controller),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildCameraControls(),
    );
  }


  Future<void> captureAndProcessImage() async {
    try {
      var image = await widget.controller.takePicture();
      String qrData = await processImage(image.path);

      if (qrData != '') {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => ImageAndQRDataScreen(
            imagePath: image.path,
            qrData: qrData,
            onWorkOrderAdded: widget.onWorkOrderAdded,
          ),
        ));
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final List<BarcodeFormat> formats = [BarcodeFormat.qrCode];
    final barcodeScanner = BarcodeScanner(formats: formats);
    final List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);

    String qrData = 'No QR code found';
    for (Barcode barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        qrData = rawValue;
        break;
      }
    }

    await barcodeScanner.close();
    return qrData;
  }

  Widget _buildCameraControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flash button with unique heroTag
          FloatingActionButton(
            heroTag: 'flashButton', // Unique tag for the flash button
            mini: true, // Make it smaller than the capture button
            onPressed: _toggleFlash,
            backgroundColor: Colors.white,
            child: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 40), // Space between the flash and capture button
          // Camera capture button with unique heroTag
          FloatingActionButton(
            heroTag: 'captureButton', // Unique tag for the capture button
            onPressed: () {
              // Implement your capture and confirmation logic here
              captureAndProcessImage();
            },
            backgroundColor: Colors.deepOrange, // Custom color for the button
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),
    );
  }


  void _toggleFlash() async {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    await widget.controller.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
  }
}

class ImageAndQRDataScreen extends StatefulWidget {
  final String imagePath;
  final String qrData;
  final Function onWorkOrderAdded;

  const ImageAndQRDataScreen({
    super.key,
    required this.imagePath,
    required this.qrData,
    required this.onWorkOrderAdded,
  });

  @override
  _ImageAndQRDataScreenState createState() => _ImageAndQRDataScreenState();
}

class _ImageAndQRDataScreenState extends State<ImageAndQRDataScreen> {
  String imageUrl = '';

  @override
  Widget build(BuildContext context) {
    List<String> qrParts = widget.qrData.isNotEmpty ? widget.qrData.split(',') : [];
    List<String> labels = ['Part Name:', 'PO Number:', 'Part Number:'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image and QR Data'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 500,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: qrParts.isNotEmpty && qrParts.length >= labels.length
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  labels.length,
                      (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${labels[index]} ',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold, // Make labels bold
                              color: Colors.black, // Specify the text color for labels
                            ),
                          ),
                          TextSpan(
                            text: qrParts[index],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.normal, // Keep qrParts not bold
                              color: Colors.black, // Specify the text color for qrParts
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
                  : const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Invalid or insufficient QR data',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(), // Go back to retake picture
                    child: const Text('Retake'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Assuming widget.qrData contains the QR code data you need to validate
                      if (widget.qrData.isNotEmpty) {
                        List<String> parts = widget.qrData.split(',');
                        if (parts.length >= 3) { // Assuming valid QR data should have at least 3 parts
                          imageUrl = await uploadImage(widget.imagePath); // Ensure you're using the correct variable for imagePath
                          // Use the parts as parameters for addWorkOrderWithParams
                          await addWorkOrderWithParams(
                              parts[0].trim(), // partName
                              parts[1].trim(), // po
                              parts[2].trim(), // partNum
                              imageUrl,
                              false,
                              [""],
                              "Active"
                          );
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          widget.onWorkOrderAdded();
                        } else {
                          // Show warning if QR data is invalid
                          showWarning(context, "QR Data Is Invalid, Enter Manually Or Scan Again");
                        }
                      } else {
                        // This else block handles the case where QR data is empty. Adjust as necessary.
                        showWarning(context, "QR Data Is Empty, Please Scan Again");
                      }
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Spacing between buttons
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (kDebugMode) {
                    print('Enter data manually');
                  }
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminWorkOrderManualEntry()));
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
                ),
                child: const Text('Enter Manually'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> uploadImage(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      String fileExtension = imageFile.uri.pathSegments.last.split('.').last;
      String uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      Reference storageRef = FirebaseStorage.instance.ref();
      Reference imageRef = storageRef.child('WorkOrderImages/$uniqueFileName');
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






