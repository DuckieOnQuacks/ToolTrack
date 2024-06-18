import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/camera_manager.dart';
import '../../backend/message_helper.dart';
import '../../classes/tool_class.dart';

class AdminAddToolPage extends StatefulWidget {
  const AdminAddToolPage({super.key});

  @override
  State<StatefulWidget> createState() => _AdminAddToolPageState();
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
  final TextEditingController _diameterController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  late CameraManager _cameraManager;
  FlashMode _flashMode = FlashMode.off;
  bool isCameraInitialized = false;
  bool isLoading = false;
  String imagePath = '';
  bool pictureTaken = false;

  Future<void> initializeCamera() async {
    setState(() {
      isLoading = true;
    });
    await _cameraManager.initializeCamera();
    if (!mounted) return; // Ensure the widget is still mounted
    setState(() {
      isCameraInitialized = true;
      isLoading = false;
    });
  }

  Future<void> showCameraDialog() async {
    if (_cameraManager.controller != null &&
        _cameraManager.controller!.value.isInitialized) {
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
                        icon: Icon(_flashMode == FlashMode.torch
                            ? Icons.flash_on
                            : Icons.flash_off),
                        onPressed: toggleFlashMode,
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
                            // Ensure the widget is still mounted
                            setState(() {
                              imagePath = path;
                              pictureTaken = true;
                            });
                          }
                          if (context.mounted) Navigator.of(context).pop();
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

  void toggleFlashMode() {
    setState(() {
      _flashMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      _cameraManager.controller?.setFlashMode(_flashMode);
    });
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Show top snackbar warning if any required field is not filled
      showTopSnackBar(
          context, "Please fill in all required fields.", Colors.red,
          title: "Error", icon: Icons.error);
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
      imagePath,
      _gageDescController.text,
      _daysRemainController.text,
      _diameterController.text,
      _heightController.text
    );

    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      showTopSnackBar(
          context, "Added tool successfully", Colors.green, title: "Success",
          icon: Icons.check_circle);
    });
  }

  void showPictureDialog(String imagePath) {
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

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      if (!mounted) return; // Ensure the widget is still mounted
      setState(() {
        _cameraManager = CameraManager(availableCameras);
      });
      initializeCamera();
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
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt,
                          size: 40, color: Colors.orange),
                      onPressed: () async {
                        await showCameraDialog();
                      },
                    ),
                    if (pictureTaken) ...[
                      IconButton(
                        icon: const Icon(Icons.image,
                            color: Colors.green, size: 40),
                        onPressed: () {
                          showPictureDialog(imagePath);
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
                  validator: (value) =>
                      value!.isEmpty ? 'This field is required' : null,
                ),
                _buildDateFieldWithClear(
                  controller: _dateCreatedController,
                  label: 'Enter Creation Date:',
                  hintText: 'MM/DD/YYYY',
                ),
                _buildTextField(
                  controller: _gageDescController,
                  label: 'Enter Gage Description: *',
                  hintText: 'e.g. 2-3" MITUTOYO MICROMETER',
                  validator: (value) =>
                      value!.isEmpty ? 'This field is required' : null,
                ),
                _buildDropdownField(
                  controller: _gageTypeController,
                  label: 'Gage Type: *',
                  hintText: 'Select Gage Type',
                  items: [
                    'Thread Plug Gage',
                    'Thread Ring Gage',
                    'Caliper',
                    'Micrometer'
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Calibration Information'),
                _buildTextField(
                  controller: _calFreqController,
                  label: 'Calibration Frequency (days):',
                  hintText: 'e.g. 67',
                ),
                _buildDateFieldWithClear(
                  controller: _calNextDueController,
                  label: 'Calibration Next Due:',
                  hintText: 'MM/DD/YYYY',
                ),
                _buildTextField(
                  controller: _daysRemainController,
                  label: 'Days Remaining Until Calibration (days):',
                  hintText: 'e.g. 180',
                ),
                _buildDateFieldWithClear(
                  controller: _calLastController,
                  label: 'Calibration Last Completed:',
                  hintText: 'MM/DD/YYYY',
                ),
                _buildTextField(
                  controller: _diameterController,
                  label: 'Diameter (mm): ',
                  hintText: 'Enter the diameter in mm',
                ),
                _buildTextField(
                  controller: _heightController,
                  label: 'Height (mm): ',
                  hintText: 'Enter the height in mm',
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => submitForm(),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hintText, String? Function(String?)? validator}) {
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
  Widget _buildDropdownField({required TextEditingController controller, required String label, required String hintText, required List<String> items,}) {
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
        style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
      ),
    );
  }

  Widget _buildDateFieldWithClear({required TextEditingController controller, required String label, required String hintText,}) {
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
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
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
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
