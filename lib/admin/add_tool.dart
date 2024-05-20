import 'dart:io';
import 'package:another_flushbar/flushbar.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:intl/intl.dart';
import '../classes/toolClass.dart';

class AdminAddToolPage extends StatefulWidget {
  const AdminAddToolPage({super.key});

  @override
  State<StatefulWidget> createState() => _AdminAddToolPageState();
}

class CameraManager {
  CameraController? controller;
  final List<CameraDescription> cameras;
  final BarcodeScanner barcodeScanner = BarcodeScanner();

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
    await barcodeScanner.close();
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

  Future<String?> scanBarcode(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final List<Barcode> barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        return barcodes.first.rawValue;
      }
    } catch (e) {
      debugPrint('Error scanning barcode: $e');
    }
    return null;
  }
}

class _AdminAddToolPageState extends State<AdminAddToolPage> {
  final User user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _gageIDController = TextEditingController();
  final TextEditingController _calFreqController = TextEditingController();
  final TextEditingController _calNextDueController = TextEditingController();
  final TextEditingController _calLastController = TextEditingController();
  final TextEditingController _dateCreatedController = TextEditingController();
  final TextEditingController _gageTypeController = TextEditingController();
  final TextEditingController _gageDescController = TextEditingController();
  final TextEditingController _daysRemainController = TextEditingController();

  late CameraManager _cameraManager;
  FlashMode _flashMode = FlashMode.off;
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  String imagePath = '';
  String imageUrl = '';
  bool pictureTaken = false;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      setState(() {
        _cameraManager = CameraManager(availableCameras);
      });
      _initializeCamera();
    });
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
    _gageIDController.dispose();
    _calFreqController.dispose();
    _calNextDueController.dispose();
    _calLastController.dispose();
    _dateCreatedController.dispose();
    _gageTypeController.dispose();
    _gageDescController.dispose();
    _daysRemainController.dispose();
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

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Show top snackbar warning if any required field is not filled
      _showTopSnackBar(context, "Please fill in all required fields.");
      return;
    }

    // Use the parts as parameters for addWorkOrderWithParams
    await addToolWithParams(
      _calFreqController.text,
      _calLastController.text,
      _calNextDueController.text,
      _dateCreatedController.text,
      _gageIDController.text,
      _gageTypeController.text,
      imageUrl,
      _gageDescController.text,
      _daysRemainController.text,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
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

  void _showTopSnackBar(BuildContext context, String message) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: Colors.red,
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Tool Details'),
        backgroundColor: Colors.grey[900],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Text(
                        'Take a Picture of the Tool: *',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, size: 40, color: Colors.orange),
                      onPressed: () async {
                        await _showCameraDialog();
                      },
                    ),
                    if (pictureTaken) ...[
                      IconButton(
                        icon: const Icon(Icons.image, color: Colors.green, size: 40),
                        onPressed: () {
                          _showPictureDialog(imagePath);
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Tool Information'),
                _buildTextField(
                  controller: _gageIDController,
                  label: 'Enter Gage ID: *',
                  hintText: 'e.g. 00001',
                  validator: (value) => value!.isEmpty ? 'This field is required' : null,
                ),
                _buildDateField(
                  controller: _dateCreatedController,
                  label: 'Enter Creation Date: *',
                  hintText: 'MM/DD/YYYY',
                  validator: (value) => value!.isEmpty ? 'This field is required' : null,
                ),
                _buildTextField(
                  controller: _gageDescController,
                  label: 'Enter Gage Description: *',
                  hintText: 'e.g. 2-3" MITUTOYO MICROMETER',
                  validator: (value) => value!.isEmpty ? 'This field is required' : null,
                ),
                _buildDropdownField(
                  controller: _gageTypeController,
                  label: 'Gage Type: *',
                  hintText: 'Select Gage Type',
                  items: ['Thread Plug Gage', 'Ring Gage', 'Caliper', 'Micrometer'],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Calibration Information'),
                _buildTextField(
                  controller: _calFreqController,
                  label: 'Calibration Frequency (days): *',
                  hintText: 'e.g. 67',
                  validator: (value) => value!.isEmpty ? 'This field is required' : null,
                ),
                _buildDateField(
                  controller: _calNextDueController,
                  label: 'Calibration Next Due: *',
                  hintText: 'MM/DD/YYYY',
                ),
                _buildTextField(
                  controller: _daysRemainController,
                  label: 'Days Remaining Until Calibration (days): *',
                  hintText: 'e.g. 180',
                  validator: (value) => value!.isEmpty ? 'This field is required' : null,
                ),
                _buildDateField(
                  controller: _calLastController,
                  label: 'Calibration Last Completed: *',
                  hintText: 'MM/DD/YYYY',
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.orange,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hintText,
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
              hintText: hintText,
            ),
            validator: validator,
            onTap: () async {
              FocusScope.of(context).requestFocus(FocusNode());
              DateTime? date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                controller.text = DateFormat('MM/dd/yyyy').format(date);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: controller.text.isEmpty ? null : controller.text,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hintText,
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                controller.text = newValue!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
      ),
    );
  }
}
