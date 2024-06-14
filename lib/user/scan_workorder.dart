import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vineburgapp/user/scan_bin.dart';
import '../backend/camera_manager.dart';
import '../backend/message_helper.dart';

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
  bool _isLoading = false;
  bool _isScanning = false;

  Future<void> initializeCamera() async {
    setState(() {
      _isLoading = true;
    });
    _cameraManager = CameraManager(widget.cameras);
    await _cameraManager.initializeCamera();
    setState(() {
      _isCameraInitialized = true;
      _isLoading = false;
    });
    startBarcodeScanning();
  }

  Future<void> startBarcodeScanning() async {
    setState(() {
      _isScanning = true;
    });
    while (_isScanning && _isCameraInitialized) {
      final imagePath = await _cameraManager.takePicture();
      if (imagePath != null) {
        final barcodeData = await _cameraManager.scanBarcode(imagePath);
        if (barcodeData != null) {
          setState(() {
            _isScanning = false;
            _isLoading = false;
          });
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanToolPage(
                widget.cameras,
                barcodeData,
                imagePath,
                widget.inOrOut,
                snackbarMessage: "Barcode data $barcodeData retrieved successfully!",
              ),
            ),
          );
          break;
        }
      }
      await Future.delayed(Duration(milliseconds: 500)); // Adjust delay as needed
    }
  }

  @override
  void dispose() {
    _cameraManager.disposeCamera();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  void showManualEntryDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();

    setState(() {
      _isScanning = false;
    });

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
                setState(() {
                  _isScanning = true;
                });
                Navigator.of(context).pop(); // Dismiss the dialog
                startBarcodeScanning(); // Restart scanning
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
                    MaterialPageRoute(
                      builder: (context) => ScanToolPage(
                        widget.cameras,
                        workOrderId,
                        '',
                        widget.inOrOut,
                        snackbarMessage: "Workorder ID $workOrderId entered successfully!",
                      ),
                    ),
                  );
                } else {
                  showTopSnackBar(context, "Please enter a valid Workorder ID.", Colors.red, title: "Error", icon: Icons.error);
                }
              },
            ),
          ],
        );
      },
    ).then((_) {
      setState(() {
        _isScanning = true;
      });
      startBarcodeScanning();
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
        child: _isLoading
            ? Lottie.asset(
          'assets/lottie/loading.json',
          width: 200,
          height: 200,
        )
            : !_isCameraInitialized
            ? Lottie.asset(
          'assets/lottie/loading.json',
          width: 200,
          height: 200,
        )
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
            ],
          ),
        ),
      ),
    );
  }
}
