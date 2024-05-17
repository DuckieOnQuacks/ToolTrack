import 'package:another_flushbar/flushbar.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vineburgapp/user/returnConfirmation.dart';
import '../backend/cameraManager.dart';
import '../classes/toolClass.dart';
import 'checkoutConfirmation.dart';

class ScanToolPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String workorderData;
  final String workOrderImagePath;
  final String inOrOut;

  const ScanToolPage(this.cameras, this.workorderData, this.workOrderImagePath, this.inOrOut, {super.key});

  @override
  _ScanToolPageState createState() => _ScanToolPageState();
}

class _ScanToolPageState extends State<ScanToolPage> {
  late CameraManager _cameraManager;
  FlashMode _flashMode = FlashMode.off;
  bool _isCameraInitialized = false;
  String _associatedImageUrl = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameraManager = CameraManager(widget.cameras);
    await _cameraManager.initializeCamera();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  @override
  void dispose() {
    _cameraManager.disposeCamera();
    super.dispose();
  }

  Future<DocumentSnapshot?> getToolDocument(String toolId) async {
    try {
      final toolDoc = await FirebaseFirestore.instance.collection('Tools').doc(toolId).get();
      return toolDoc.exists ? toolDoc : null;
    } catch (e) {
      print('Error getting tool document: $e');
      return null;
    }
  }

  void showConfirmationDialog(BuildContext context, String toolBarcodeData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirm Barcode",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[900]),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[800], fontSize: 16.0),
                  children: <TextSpan>[
                    const TextSpan(text: "Tool ID: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: toolBarcodeData, style: const TextStyle(fontWeight: FontWeight.normal)),
                    const TextSpan(text: "\n\nIs this the correct ID?", style: TextStyle(fontWeight: FontWeight.normal, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red,
                  ),
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 10), // Add space between the buttons
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green,
                  ),
                  child: const Text("Confirm"),
                  onPressed: () {
                    if (widget.inOrOut == 'return') {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReturnConfirmationPage(
                            workorderId: widget.workorderData,
                            toolId: toolBarcodeData,
                            toolImagePath: _associatedImageUrl,
                            workOrderImagePath: widget.workOrderImagePath,
                          ),
                        ),
                      );
                    } else if (widget.inOrOut == 'checkout') {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutConfirmationPage(
                            workorderId: widget.workorderData,
                            toolId: toolBarcodeData,
                            toolImagePath: _associatedImageUrl,
                            workOrderImagePath: widget.workOrderImagePath,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void handleToolBarcodeScanning() async {
    final imagePath = await _cameraManager.takePicture();
    if (imagePath != null) {
      final barcodeData = await _cameraManager.scanBarcode(imagePath);
      if (barcodeData != null) {
        // Check if the tool ID exists in the Firestore database
        final toolDoc = await getToolDocument(barcodeData);
        if (toolDoc != null) {
          // Tool ID exists, get the associated image URL
          final storageUrl = toolDoc['Tool Image Path'] ?? '';
          setState(() {
            _associatedImageUrl = storageUrl;
          });
          // Show the confirmation dialog with the associated image URL
          showConfirmationDialog(context, barcodeData);
        } else {
          // Tool ID does not exist, show error snackbar
          showTopSnackBar(context, "Tool ID not found in the database.");
        }
      } else {
        showTopSnackBar(context, "No tool QR code found, try again.");
      }
    }
  }

  void showTopSnackBar(BuildContext context, String message) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: Colors.red,
    ).show(context);
  }

  void _toggleFlashMode() {
    setState(() {
      _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      _cameraManager.controller?.setFlashMode(_flashMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Tool QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: !_isCameraInitialized
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: SizedBox(
                  width: 350,
                  height: 500,
                  child: CameraPreview(_cameraManager.controller!),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off),
                  onPressed: _toggleFlashMode,
                  color: Colors.yellow,
                  iconSize: 36,
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  iconSize: 50.0,
                  onPressed: handleToolBarcodeScanning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
