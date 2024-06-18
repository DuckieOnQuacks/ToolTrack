import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vineburgapp/classes/bin_class.dart';
import '../backend/camera_manager.dart';
import '../backend/message_helper.dart';
import '../classes/tool_class.dart';
import 'checkout_confirmation.dart';

class ScanToolPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String workorderData;
  final String workOrderImagePath;
  final String inOrOut;
  final String? snackbarMessage; // Add this line

  const ScanToolPage(this.cameras, this.workorderData, this.workOrderImagePath, this.inOrOut, {super.key, this.snackbarMessage}); // Modify this line

  @override
  State<ScanToolPage> createState() => _ScanToolPageState();
}

class _ScanToolPageState extends State<ScanToolPage> {
  late CameraManager _cameraManager;
  bool isCameraInitialized = false;
  bool isLoading = false;
  bool flashEnabled = false;
  String associatedImageUrl = '';
  Tool? selectedTool;

  @override
  void initState() {
    super.initState();
    initializeCamera();

    // Show snackbar if there's a message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.snackbarMessage != null) {
        showTopSnackBar(context, widget.snackbarMessage!, Colors.green, title: "Success", icon: Icons.check);
      }
    });
  }

  Future<void> initializeCamera() async {
    setState(() {
      isLoading = true;
    });
    _cameraManager = CameraManager(widget.cameras);
    await _cameraManager.initializeCamera();
    setState(() {
      isCameraInitialized = true;
      isLoading = false;
    });
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
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                "Select The Tool You Want To Checkout:",
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
                              color: selectedTool == tool ? Colors.black26 : Colors.grey[800],
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
                                    selectedTool = tool;
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
                    if (selectedTool != null && selectedTool?.status == "Available") {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CheckoutConfirmationPage(
                            workorderId: widget.workorderData,
                            tool: selectedTool!,
                            toolImagePath: associatedImageUrl,
                            workOrderImagePath: widget.workOrderImagePath,
                          ),
                        ),
                      );
                    } else if(selectedTool?.status == "Checked Out"){
                      showTopSnackBar(context, "Tool already checked out to ${selectedTool?.checkedOutTo}", Colors.red, title: "Error:", icon: Icons.warning);
                    }
                    else{
                      showTopSnackBar(context, "Please select a tool", Colors.orange, title: "Warning", icon: Icons.warning);
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

  Future<void> handleToolBarcodeScanning() async {
    setState(() {
      isLoading = true;
    });
    if (flashEnabled) {
      await _cameraManager.controller?.setFlashMode(FlashMode.torch);
    }
    final imagePath = await _cameraManager.takePicture();
    await _cameraManager.controller?.setFlashMode(FlashMode.off);
    if (imagePath != null) {
      final barcodeData = await _cameraManager.scanBarcode(imagePath);
      if (barcodeData != null) {
        final binID = barcodeData;
        final binDoc = await FirebaseFirestore.instance.collection('Bins').doc(formatBinID(binID)).get();

        if (binDoc.exists) {
          final data = binDoc.data();
          if (data != null && data.containsKey('Tools')) {
            final toolIDs = List<String>.from(data['Tools']);
            final tools = <Tool>[];

            for (final toolID in toolIDs) {
              final toolDoc = await FirebaseFirestore.instance.collection('Tools').doc(toolID).get();
              if (toolDoc.exists) {
                final toolData = toolDoc.data();
                if (toolData != null) {
                  tools.add(Tool.fromJson(toolData));
                }
              }
            }

            if (tools.isNotEmpty) {
              setState(() {
                associatedImageUrl = tools.first.imagePath;
                isLoading = false;
              });

              showToolSelectionDialog(context, barcodeData, tools);
            } else {
              setState(() {
                isLoading = false;
              });
              showTopSnackBar(context, "No tools found in the bin.", Colors.red, title: "Error", icon: Icons.error);
            }
          } else {
            setState(() {
              isLoading = false;
            });
            showTopSnackBar(context, "Bin exists but no tools found.", Colors.red, title: "Error", icon: Icons.error);
          }
        } else {
          setState(() {
            isLoading = false;
          });
          showTopSnackBar(context, "Bin ID not found in the database.", Colors.red, title: "Error", icon: Icons.error);
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showTopSnackBar(context, "No tool QR code found, please scan again.", Colors.red, title: "Error", icon: Icons.error);
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showManualEntryDialog(BuildContext context) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Row(
            children: [
              const Text("Enter Bin Name"),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: Image.asset('assets/images/binTipImage.jpg'), // Replace with your image path
                    ),
                  );
                },
              ),
            ],
          ),
          content: SingleChildScrollView( // Add SingleChildScrollView
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: "Bin Name"),
                ),
              ],
            ),
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
                    isLoading = true;
                  });

                  final toolDoc = await getToolDocument(toolId);
                  if (toolDoc != null) {
                    final data = toolDoc.data();
                    if (data != null && data is Map<String, dynamic>) {
                      final storageUrl = data['Tool Image Path'] ?? '';
                      final tool = Tool.fromJson(data);

                      setState(() {
                        associatedImageUrl = storageUrl;
                        isLoading = false;
                      });

                      bool toolIsInWorkOrder = await isToolInWorkOrder(widget.workorderData, tool.gageID);

                      if (!toolIsInWorkOrder && widget.inOrOut != 'checkout') {
                        showTopSnackBar(context, "Tool Not Checked Out To WorkOrder ${widget.workorderData}", Colors.red, title: "Error", icon: Icons.error);

                      } else {
                        if (widget.inOrOut == 'checkout' && tool.status != 'Available') {
                          showTopSnackBar(context, "Tool ${tool.gageID} is currently checked out to ${tool.checkedOutTo}. Try A Different Tool!", Colors.red, title: "Error", icon: Icons.error);
                        } else {
                          showToolSelectionDialog(context, toolId, [tool]);
                        }
                      }
                    } else {
                      setState(() {
                        isLoading = false;
                      });
                      showTopSnackBar(context, "Bin data is invalid.", Colors.red, title: "Error", icon: Icons.error);
                    }
                  } else {
                    setState(() {
                      isLoading = false;
                    });
                    showTopSnackBar(context, "Bin name not found in the database.", Colors.red, title: "Error", icon: Icons.error);
                  }
                } else {
                  showTopSnackBar(context, "Please enter a valid bin name.", Colors.orange, title: "Warning", icon: Icons.warning);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraManager.disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Bin QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              showManualEntryDialog(context);
            },
            tooltip: 'Enter Bin ID Manually',
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? Lottie.asset(
          'assets/lottie/loading.json',
          width: 150,
          height: 150,
        )
            : !isCameraInitialized
            ? Lottie.asset(
          'assets/lottie/loading.json',
          width: 150,
          height: 150,
        ): Column(
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
                  icon: const Icon(Icons.camera_alt),
                  iconSize: 60.0,
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
