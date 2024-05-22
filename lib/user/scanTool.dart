import 'package:another_flushbar/flushbar.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _flashEnabled = false;
  String _associatedImageUrl = '';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
    });
    _cameraManager = CameraManager(widget.cameras);
    await _cameraManager.initializeCamera();
    setState(() {
      _isCameraInitialized = true;
      _isLoading = false;
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

  void showConfirmationDialog(BuildContext context, String toolBarcodeData, Tool tool) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Barcode",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.white, fontSize: 16.0),
                  children: <TextSpan>[
                    const TextSpan(text: "Tool ID: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: toolBarcodeData, style: const TextStyle(fontWeight: FontWeight.normal)),
                    const TextSpan(text: "\n\nIs this the correct ID?", style: TextStyle(fontWeight: FontWeight.normal, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
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
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (widget.inOrOut == 'return') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReturnConfirmationPage(
                            workorderId: widget.workorderData,
                            tool: tool,
                            toolImagePath: _associatedImageUrl,
                            workOrderImagePath: widget.workOrderImagePath,
                          ),
                        ),
                      );
                    } else if (widget.inOrOut == 'checkout') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutConfirmationPage(
                            workorderId: widget.workorderData,
                            tool: tool,
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

  Future<void> handleToolBarcodeScanning() async {
    setState(() {
      _isLoading = true;
    });
    if (_flashEnabled) {
      await _cameraManager.controller?.setFlashMode(FlashMode.torch);
    }
    final imagePath = await _cameraManager.takePicture();
    await _cameraManager.controller?.setFlashMode(FlashMode.off);
    if (imagePath != null) {
      final barcodeData = await _cameraManager.scanBarcode(imagePath);
      if (barcodeData != null) {
        // Check if the tool ID exists in the Firestore database
        final toolDoc = await getToolDocument(barcodeData);
        if (toolDoc != null) {
          // Tool ID exists, get the associated image URL
          final data = toolDoc.data();
          if (data != null && data is Map<String, dynamic>) {
            final storageUrl = data['Tool Image Path'] ?? '';
            final tool = Tool.fromJson(data);

            setState(() {
              _associatedImageUrl = storageUrl;
              _isLoading = false;
            });

            // If checking out, ensure the tool is not already checked out
            if (widget.inOrOut == 'checkout' && tool.status != 'Available') {
              showTopSnackBar(context, "Tool ${tool.gageID} is currently checked out to ${tool.lastCheckedOutBy}. Try A Different Tool!");
            } else {
              // Show the confirmation dialog with the associated image URL
              showConfirmationDialog(context, barcodeData, tool);
            }
          } else {
            setState(() {
              _isLoading = false;
            });
            showTopSnackBar(context, "Tool data is invalid.");
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          // Tool ID does not exist, show error snackbar
          showTopSnackBar(context, "Tool ID not found in the database.");
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        showTopSnackBar(context, "No tool QR code found, try again.");
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showManualEntryDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Tool ID"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Tool ID"),
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
              onPressed: () async {
                String toolId = controller.text.trim();
                if (toolId.isNotEmpty) {
                  setState(() {
                    _isLoading = true;
                  });
                  final toolDoc = await getToolDocument(toolId);
                  if (toolDoc != null) {
                    final data = toolDoc.data();
                    if (data != null && data is Map<String, dynamic>) {
                      final storageUrl = data['Tool Image Path'] ?? '';
                      final tool = Tool.fromJson(data);

                      setState(() {
                        _associatedImageUrl = storageUrl;
                        _isLoading = false;
                      });
                      Navigator.of(context).pop(); // Dismiss the dialog

                      // If checking out, ensure the tool is not already checked out
                      if (widget.inOrOut == 'checkout' && tool.status != 'Available') {
                        showTopSnackBar(context, "Tool is currently checked out.");
                      } else {
                        showConfirmationDialog(context, toolId, tool);
                      }
                    } else {
                      setState(() {
                        _isLoading = false;
                      });
                      showTopSnackBar(context, "Tool data is invalid.");
                    }
                  } else {
                    setState(() {
                      _isLoading = false;
                    });
                    showTopSnackBar(context, "Tool ID not found in the database.");
                  }
                } else {
                  showTopSnackBar(context, "Please enter a valid Tool ID.");
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
      _flashEnabled = !_flashEnabled;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showManualEntryDialog(context);
            },
            tooltip: 'Enter Tool ID Manually',
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? Lottie.asset(
          'assets/lottie/loading.json',
          width: 150,
          height: 150,
        )
            : !_isCameraInitialized
            ? Lottie.asset(
          'assets/lottie/loading.json',
          width: 150,
          height: 150,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
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
      ),
    );
  }
}
