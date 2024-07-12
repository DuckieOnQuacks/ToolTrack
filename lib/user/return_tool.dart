import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vineburgapp/classes/workorder_class.dart';
import '../backend/camera_manager.dart';
import '../backend/message_helper.dart';
import '../classes/tool_class.dart';

class ReturnToolPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String inOrOut;

  const ReturnToolPage(this.cameras, this.inOrOut, {super.key});

  @override
  _ReturnToolState createState() => _ReturnToolState();
}

class _ReturnToolState extends State<ReturnToolPage> {
  late CameraManager _cameraManager;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  bool _flashEnabled = false;
  bool _isScanning = false;
  Tool? _selectedTool;

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
          bool workOrderExists = await checkWorkOrderExists(barcodeData);
          if (workOrderExists) {
            final tools = await fetchToolsFromWorkOrder(barcodeData);
            showToolSelectionDialog(context, barcodeData, tools);
          } else {
            showTopSnackBar(context, "Workorder not found in the database.", Colors.red, title: "Error", icon: Icons.error);
          }
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 500)); // Adjust delay as needed
    }
  }

  void showToolSelectionDialog(BuildContext context, String barcodeData, List<Tool> tools) {
    setState(() {
      _isScanning = false;
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Select The Tool You Want To Return:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 300.0, // Adjust the max height as needed
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: tools.length,
                          itemBuilder: (context, index) {
                            final tool = tools[index];
                            bool isAvailable = tool.status == 'Available';
                            return Card(
                              color: _selectedTool == tool ? Colors.black26 : Colors.grey[800],
                              child: ListTile(
                                leading: Icon(Icons.build, color: Colors.orange[300]),
                                title: Text(
                                  tool.gageDesc,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: Row(
                                  children: [
                                    Text(
                                      "Tool ID: ${tool.gageID}",
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(width: 10),
                                    isAvailable
                                        ? const Icon(Icons.check_circle, color: Colors.green)
                                        : const Icon(Icons.lock, color: Colors.red),
                                    const SizedBox(width: 5),
                                    Text(
                                      isAvailable ? 'Available' : 'Checked Out',
                                      style: TextStyle(
                                        color: isAvailable ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedTool = tool;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red,
                  ),
                  child: const Text("Cancel"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isScanning = true;
                    });
                    startBarcodeScanning();
                  },
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.green,
                  ),
                  child: const Text("Confirm"),
                  onPressed: () {
                    if (_selectedTool != null) {
                      Navigator.of(context).pop();
                      confirmReturn(_selectedTool!);
                    } else {
                      showTopSnackBar(context, "Please select a tool.", Colors.orange, title: "Warning", icon: Icons.warning);
                    }
                  },
                ),
              ],
              backgroundColor: Colors.grey[900],
            );
          },
        );
      },
    ).then((_) {
      setState(() {
        _isScanning = true;
      });
      startBarcodeScanning();
    });
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
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Enter Work Order ID"),
            ],
          ),
          content: SingleChildScrollView(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: "Work Order ID"),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.red,
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
                foregroundColor: Colors.white, backgroundColor: Colors.green,
              ),
              child: const Text("Confirm"),
              onPressed: () async {
                String workOrderId = controller.text.trim();
                if (workOrderId.isNotEmpty) {
                  bool workOrderExists = await checkWorkOrderExists(workOrderId);
                  if (workOrderExists) {
                    final tools = await fetchToolsFromWorkOrder(workOrderId); // Fetch the tools for the workorder
                    Navigator.of(context).pop(); // Dismiss the dialog
                    showToolSelectionDialog(context, workOrderId, tools);
                  } else {
                    showTopSnackBar(context, "Workorder not found in the database.", Colors.red, title: "Error", icon: Icons.error);
                  }
                } else {
                  showTopSnackBar(context, "Please enter a valid work order ID.", Colors.red, title: "Error", icon: Icons.error);
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

  void toggleFlashMode() {
    setState(() {
      _flashEnabled = !_flashEnabled;
    });
  }

  void confirmReturn(Tool tool) async {
    if (context.mounted) {
      try {
        if (tool.status == "Available") {
          showTopSnackBar(context, "Tool is marked as already returned.", Colors.red, title: "Error", icon: Icons.error);
          return;
        }
        await returnTool(tool.gageID, "Available", tool.checkedOutTo);
        // Navigate back to the first route and show the snackbar
        Navigator.popUntil(context, (route) => route.isFirst);
        Future.delayed(const Duration(milliseconds: 100), () {
          showTopSnackBar(context, "Return successful!", Colors.green, title: "Success", icon: Icons.check_circle);
        });
      } catch (e) {
        showTopSnackBar(context, "Failed to return. Please try again.", Colors.red, title: "Error", icon: Icons.error);
      }
    }
  }

  @override
  void dispose() {
    _isScanning = false; // Stop scanning when disposing
    _cameraManager.disposeCamera();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Work Order Barcode', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900], // Consistent with the other page
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showManualEntryDialog(context);
            },
            tooltip: 'Enter Work Order ID Manually',
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
            : Stack(
          alignment: Alignment.center,
          children: [
            SingleChildScrollView(
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
            if (_isScanning)
              Positioned(
                bottom: 30,
                child: Column(
                  children: [
                    Lottie.asset(
                      'assets/lottie/barcodescan.json',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scanning for QR code...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
