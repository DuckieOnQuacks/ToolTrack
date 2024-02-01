import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import '../classes/work_order_class.dart';

class CameraScreen extends StatefulWidget {
  final Function onWorkOrderAdded;
  final CameraController controller;

  const CameraScreen(this.controller, {super.key, required this.onWorkOrderAdded});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  double cameraWidth = 350; // Default width
  double cameraHeight = 600; // Default height

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.grey),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: cameraWidth,
              height: cameraHeight,
              child: CameraPreview(widget.controller),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => captureAndProcessImage(),
        child: const Icon(Icons.camera),
      ),
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
                    child: Text('${labels[index]} ${qrParts[index]}',
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
              )
                  : const Text('Invalid or insufficient QR data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                            [""]
                          );
                          if (!mounted) return;
                          Navigator.of(context).pop();
                          await widget.onWorkOrderAdded();
                        } else {
                          print('QR data format is incorrect');
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
      print('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }
}







