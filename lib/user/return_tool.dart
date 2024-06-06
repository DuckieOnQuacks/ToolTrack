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
  Tool? _selectedTool;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

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
  }

  @override
  void dispose() {
    _cameraManager.disposeCamera();
    super.dispose();
  }

  void handleBarcodeScanning() async {
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
        bool workOrderExists = await checkWorkOrderExists(barcodeData);
        if (workOrderExists) {
          final tools = await fetchToolsFromWorkOrder(barcodeData); // Fetch the tools for the workorder
          setState(() {
            _isLoading = false;
          });
          showToolSelectionDialog(context, barcodeData, tools);
        } else {
          setState(() {
            _isLoading = false;
          });
          showTopSnackBar(context, "Workorder not found in the database.", Colors.red, title: "Error", icon: Icons.error);

        }
      } else {
        setState(() {
          _isLoading = false;
        });
        showTopSnackBar(context, "No barcode found, try again.", Colors.red, title: "Error", icon: Icons.error);
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void showToolSelectionDialog(BuildContext context, String barcodeData, List<Tool> tools) {
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
                      showConfirmationDialog(context, _selectedTool!);
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
                  showTopSnackBar(context, "Please enter a valid Workorder ID.", Colors.red, title: "Error", icon: Icons.error);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void toggleFlashMode() {
    setState(() {
      _flashEnabled = !_flashEnabled;
    });
  }

  void showConfirmationDialog(BuildContext context, Tool tool) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Return", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Text(
            "Are you sure you want to return ${tool.gageDesc}?",
            style: const TextStyle(color: Colors.white),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.red,
              ),
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.green,
              ),
              child: const Text("Confirm"),
              onPressed: () async {
                Navigator.of(context).pop();
                confirmReturn(tool);
              },
            ),
          ],
        );
      },
    );
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
          showTopSnackBar(context, "Return successful!", Colors.green);
        });
      } catch (e) {
        showTopSnackBar(context, "Failed to return. Please try again.", Colors.red, title: "Error", icon: Icons.error);
      }
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
                    onPressed: toggleFlashMode,
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
