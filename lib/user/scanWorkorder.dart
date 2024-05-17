import 'package:another_flushbar/flushbar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:vineburgapp/user/scanTool.dart';
import '../backend/cameraManager.dart';

class ScanWorkorderPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String inOrOut;

  const ScanWorkorderPage(this.cameras, this.inOrOut, {super.key});

  @override
  _ScanWorkorderPageState createState() => _ScanWorkorderPageState();
}

class _ScanWorkorderPageState extends State<ScanWorkorderPage> {
  late CameraManager _cameraManager;
  bool _isCameraInitialized = false;
  FlashMode _flashMode = FlashMode.off;

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

  void handleBarcodeScanning() async {
    final imagePath = await _cameraManager.takePicture();
    if (imagePath != null) {
      final barcodeData = await _cameraManager.scanBarcode(imagePath);
      if (barcodeData != null) {
        showConfirmationDialog(context, barcodeData, imagePath);
      } else {
        showTopSnackBar(context, "No barcode found, try again.");
      }
    }
  }

  void showConfirmationDialog(BuildContext context, String barcodeData, String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Barcode", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[900])),
          content: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[800], fontSize: 16.0), // Default style for TextSpans
              children: <TextSpan>[
                const TextSpan(text: "Barcode data: ", style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: barcodeData, style: const TextStyle(fontWeight: FontWeight.normal)),
                const TextSpan(text: "\n\nIs this the correct ID?", style: TextStyle(fontWeight: FontWeight.normal, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.red,  // Text color
              ),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog and do not navigate
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,  // Text color
              ),
              child: const Text("Confirm"),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanToolPage(widget.cameras, barcodeData, imagePath, widget.inOrOut)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void showManualEntryDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Workorder ID"),
          content: SingleChildScrollView(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Workorder ID"),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.red,  // Text color
              ),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,  // Text color
              ),
              child: const Text("Confirm"),
              onPressed: () {
                String workOrderId = controller.text.trim();
                if (workOrderId.isNotEmpty) {
                  Navigator.of(context).pop(); // Dismiss the dialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScanToolPage(widget.cameras, workOrderId, '', widget.inOrOut)),
                  );
                } else {
                  showTopSnackBar(context, "Please enter a valid Workorder ID.");
                }
              },
            ),
          ],
        );
      },
    );
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
        title: const Text('Scan Workorder Barcode', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900], // Consistent with the other page
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showManualEntryDialog(context);
            },
            tooltip: 'Enter Workorder ID Manually',
          ),
        ],
      ),
      body: Center(
        child: !_isCameraInitialized
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
          child: Column(
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
                    onPressed: handleBarcodeScanning,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
