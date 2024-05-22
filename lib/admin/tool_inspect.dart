import 'dart:io';
import 'package:another_flushbar/flushbar.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../classes/toolClass.dart';

class AdminInspectToolScreen extends StatefulWidget {
  final Tool tool;

  const AdminInspectToolScreen({super.key, required this.tool});

  @override
  _AdminInspectToolScreenState createState() => _AdminInspectToolScreenState();
}

class CameraManager {
  CameraController? controller;
  final List<CameraDescription> cameras;

  CameraManager(this.cameras);

  Future<void> initializeCamera() async {
    if (cameras.isNotEmpty) {
      controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      try {
        await controller!.initialize();
      } catch (e) {
        debugPrint('Error initializing camera: $e');
      }
    }
  }

  Future<void> disposeCamera() async {
    await controller?.dispose();
  }

  Future<String?> takePicture() async {
    if (controller == null || !controller!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return null;
    }

    if (!controller!.value.isTakingPicture) {
      try {
        final XFile file = await controller!.takePicture();
        return file.path;
      } catch (e) {
        debugPrint('Error taking picture: $e');
        return null;
      }
    }
    return null;
  }
}

class _AdminInspectToolScreenState extends State<AdminInspectToolScreen> {
  late List<CameraDescription> cameras;
  late CameraManager _cameraManager;
  late TextEditingController toolNameController;
  String imagePath = '';
  bool pictureTaken = false;
  late TextEditingController whereBeingUsedController;
  late TextEditingController personCheckedOutController;
  late TextEditingController dateCheckedOutController;
  FlashMode _flashMode = FlashMode.off;
  bool _isCameraInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
      setState(() {
        _cameraManager = CameraManager(cameras);
      });
      _initializeCamera();
    });
    toolNameController = TextEditingController(text: widget.tool.gageType);
    whereBeingUsedController = TextEditingController(text: widget.tool.atMachine);
    personCheckedOutController = TextEditingController(text: widget.tool.status);
    dateCheckedOutController = TextEditingController(text: widget.tool.atMachine);
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
    });
    await _cameraManager.initializeCamera();
    setState(() {
      _isCameraInitialized = true;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _cameraManager.disposeCamera();
    toolNameController.dispose();
    whereBeingUsedController.dispose();
    personCheckedOutController.dispose();
    dateCheckedOutController.dispose();
    super.dispose();
  }

  Future<void> _showCameraDialog() async {
    if (_cameraManager.controller != null && _cameraManager.controller!.value.isInitialized) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: SingleChildScrollView(
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
                        onPressed: () async {
                          String? path = await _cameraManager.takePicture();
                          if (path != null) {
                            setState(() {
                              imagePath = path;
                              pictureTaken = true;
                            });
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _toggleFlashMode() {
    setState(() {
      _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      _cameraManager.controller?.setFlashMode(_flashMode);
    });
  }

  void _showPictureDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(File(imagePath)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  void showTopSnackBar(BuildContext context, String message, Color color) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: color,
    ).show(context);
  }

  void _confirmChanges(BuildContext context) {
    // Compare current values with original values and create a list of changes
    List<Widget> changesWidgets = [];
    if (toolNameController.text != widget.tool.gageType) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'Tool Name: ',
          style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
          children: <TextSpan>[
            TextSpan(
              text: '${widget.tool.gageType} -> ${toolNameController.text}',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ));
    }
    const SizedBox(height: 10);
    if (whereBeingUsedController.text != widget.tool.atMachine) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Located At Machine: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool.atMachine} -> ${whereBeingUsedController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal))
            ]),
      ));
    }
    const SizedBox(height: 10);
    if (personCheckedOutController.text != widget.tool.status) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Checked Out To:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool.status} -> ${personCheckedOutController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    const SizedBox(height: 10);
    if (dateCheckedOutController.text != widget.tool.dateCheckedOut) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Check Out Date:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool.dateCheckedOut} -> ${dateCheckedOutController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Changes'),
          content: SingleChildScrollView(
            child: ListBody(
              children: changesWidgets,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                // Implement save functionality here
                Navigator.of(context).pop();
                showTopSnackBar(context, "Changes saved successfully", Colors.green);
              },
            ),
          ],
        );
      },
    );
  }

  void _showImageFullscreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Tool Image'),
          leading: const BackButton(), // Uses default back button
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.file(File(imageUrl), fit: BoxFit.contain),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tool Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: (!widget.tool.imagePath.startsWith("Invalid") || pictureTaken)
                    ? const Icon(Icons.image)
                    : const Icon(Icons.camera_alt),
                color: Colors.orange[800],
                iconSize: 100.0,
                onPressed: () {
                  if (!widget.tool.imagePath.startsWith("Invalid") || pictureTaken) {
                    _showImageFullscreen(context, pictureTaken ? imagePath : widget.tool.imagePath);
                  } else {
                    _showCameraDialog();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Tool Name:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: toolNameController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Located At Machine: ',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: whereBeingUsedController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Checked Out To: ',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: personCheckedOutController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Check Out Date: ',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: dateCheckedOutController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 50),
            child: ElevatedButton(
              onPressed: () => _confirmChanges(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange[800],
                // Text color
                elevation: 5,
                // Button shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ), // Button padding
              ),
              child: const Text(
                'Submit Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
