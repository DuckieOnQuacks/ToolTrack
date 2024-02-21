import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:vineburgapp/admin/Workorder/work_order_manual.dart';
import '../../classes/work_order_class.dart';

class ScanWorkorder extends StatefulWidget {
  final Function onWorkOrderAdded;
  final CameraController controller;

  const ScanWorkorder(this.controller, {super.key, required this.onWorkOrderAdded});

  @override
  _ScanWorkorderState createState() => _ScanWorkorderState();
}

class _ScanWorkorderState extends State<ScanWorkorder> {
  double cameraWidth = 350; // Default width
  double cameraHeight = 600; // Default height
  bool _isFlashOn = false; // Track if flash is on or off\
  String imagePath = '';


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: cameraWidth,
              height: cameraHeight,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white24,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CameraPreview(widget.controller),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flash button
          IconButton(
            iconSize: 30,
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.black,
            ),
            onPressed: _toggleFlash,
          ),
          // Space between the flash button and the camera button
          const SizedBox(width: 20),
          // Camera button
          FloatingActionButton(
            onPressed: () => captureAndProcessImage(),
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  Future<void> captureAndProcessImage() async {
    try {
      // Ensure the flash is turned off after capturing the image
      if (_isFlashOn) {
        await widget.controller.setFlashMode(FlashMode.off);
        _isFlashOn = false; // Update the state to reflect the flash is off
      }

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


  void _toggleFlash() async {
    if (!_isFlashOn) {
      await widget.controller.setFlashMode(FlashMode.torch);
    } else {
      await widget.controller.setFlashMode(FlashMode.off);
    }
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  Future<String> processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final List<BarcodeFormat> formats = [BarcodeFormat.all];
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
}

class ImageAndQRDataScreen extends StatefulWidget {
  String imagePath;
  final String qrData;
  final Function onWorkOrderAdded;

  ImageAndQRDataScreen({
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
                    child: Text('${labels[index]} ${qrParts[index]}',
                        style: const TextStyle(fontSize: 20)),
                  ),
                ),
              )
                  : const Text('Invalid or insufficient QR data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      if (widget.qrData.isNotEmpty) {
                        List<String> parts = widget.qrData.split(',');
                        await uploadImage(widget.imagePath);
                        if (!mounted) return;

                        if (parts.length >= 3) {
                          // Use the parts as parameters for addWorkOrderWithParams
                          await addWorkOrderWithParams(
                            parts[0].trim(), // partName
                            parts[1].trim(), // po
                            parts[2].trim(), // partNum
                            imageUrl,
                            false,
                            [],
                            "Active"
                          );
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          await widget.onWorkOrderAdded();
                        } else {
                          if (kDebugMode) {
                            print('QR data format is incorrect');
                          }
                        }
                      }
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
              ),
            const SizedBox(height: 50),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AdminWorkOrderManualEntry(),
                        ),
                      );
                  }, // Go back to retake picture
                    child: const Text('Enter Manually'),
                  ),
                ]
            )
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







