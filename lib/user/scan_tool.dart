import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vineburgapp/user/return_confirmation.dart';
import '../backend/camera_manager.dart';
import '../backend/message_helper.dart';
import '../classes/tool_class.dart';
import 'checkout_confirmation.dart';

class ScanToolPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String workorderData;
  final String workOrderImagePath;
  final String inOrOut;

  const ScanToolPage(this.cameras, this.workorderData, this.workOrderImagePath, this.inOrOut, {super.key});

  @override
  State<ScanToolPage> createState() => _ScanToolPageState();
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
      if (kDebugMode) {
        print('Error getting tool document: $e');
      }
      return null;
    }
  }

  void showToolSelectionDialog(BuildContext context, String barcodeData, List<Tool> tools) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Tool",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select the correct tool from the list:",
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
              const SizedBox(height: 10),
              ...tools.map((tool) {
                return Card(
                  color: Colors.grey[800],
                  child: ListTile(
                    leading: Icon(Icons.build, color: Colors.orange[300]),
                    title: Text(
                      "Tool ID: ${tool.gageID}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "Status: ${tool.status}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () async {
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
                );
              }).toList(),
            ],
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
          ],
          backgroundColor: Colors.grey[900],
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
        final toolIds = barcodeData.split(',').map((id) => id.trim()).toList();
        List<Tool> tools = [];
        for (var toolId in toolIds) {
          final toolDoc = await getToolDocument(toolId);
          if (toolDoc != null) {
            final data = toolDoc.data();
            if (data != null && data is Map<String, dynamic>) {
              final tool = Tool.fromJson(data);
              tools.add(tool);
            }
          }
        }

        if (tools.isNotEmpty) {
          setState(() {
            _associatedImageUrl = tools.first.imagePath ?? '';
            _isLoading = false;
          });

          showToolSelectionDialog(context, barcodeData, tools);
        } else {
          setState(() {
            _isLoading = false;
          });
          showTopSnackBar(context, "Error: Tool IDs not found in the database.", Colors.red);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        showTopSnackBar(context, "Error: No tool QR code found, please scan again.", Colors.red);
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

                      bool toolIsInWorkOrder = await isToolInWorkOrder(widget.workorderData, tool.gageID);

                      if (!toolIsInWorkOrder && widget.inOrOut != 'checkout') {
                        showTopSnackBar(context, "Tool Not Checked Out To WorkOrder ${widget.workorderData}", Colors.red);
                      } else {
                        if (widget.inOrOut == 'checkout' && tool.status != 'Available') {
                          showTopSnackBar(context, "Error: Tool ${tool.gageID} is currently checked out to ${tool.checkedOutTo}. Try A Different Tool!", Colors.red);
                        } else {
                          showToolSelectionDialog(context, toolId, [tool]);
                        }
                      }
                    } else {
                      setState(() {
                        _isLoading = false;
                      });
                      showTopSnackBar(context, "Error: Tool data is invalid.", Colors.red);
                    }
                  } else {
                    setState(() {
                      _isLoading = false;
                    });
                    showTopSnackBar(context, "Error: Tool ID not found in the database.", Colors.red);
                  }
                } else {
                  showTopSnackBar(context, "Error: Please enter a valid Tool ID.", Colors.red);
                }
              },
            ),
          ],
        );
      },
    );
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
