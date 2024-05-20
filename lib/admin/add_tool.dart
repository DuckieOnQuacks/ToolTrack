import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../classes/toolClass.dart';

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

  late List<CameraDescription> cameras;
  late CameraController _cameraController;
  String imagePath = '';
  String imageUrl = '';
  bool pictureTaken = false;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      setState(() {
        cameras = availableCameras;
      });
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.high,
        );
        _cameraController.initialize().then((_) {
          if (!mounted) {
            return;
          }
          setState(() {});
        });
      }
    });
  }

  Future<void> _takePicture() async {
    if (_cameraController.value.isInitialized) {
      final XFile picture = await _cameraController.takePicture();
      setState(() {
        imagePath = picture.path;
        pictureTaken = true;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
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
  }

  @override
  void dispose() {
    _cameraController.dispose();
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
                  children: [
                    const Text(
                      'Take a Picture of the Tool: *',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, size: 40, color: Colors.blue),
                      onPressed: () async {
                        await _takePicture();
                      },
                    ),
                    if (pictureTaken)
                      const Icon(Icons.check_circle, color: Colors.green, size: 40),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Tool Information'),
                _buildTextField(
                  controller: _gageIDController,
                  label: 'Enter Gage ID: *',
                  hintText: 'e.g., G12345',
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
                  hintText: 'e.g., Thread Plug Gage',
                  validator: (value) => value!.isEmpty ? 'This field is required' : null,
                ),
                _buildDropdownField(
                  controller: _gageTypeController,
                  label: 'Gage Type:',
                  hintText: 'Select Gage Type',
                  items: ['Thread Plug Gage', 'Ring Gage', 'Caliper', 'Micrometer'],
                ),
                const SizedBox(height: 20),
                _buildSectionHeader('Calibration Information'),
                _buildTextField(
                  controller: _calFreqController,
                  label: 'Calibration Frequency:',
                  hintText: 'e.g., 6 months',
                ),
                _buildDateField(
                  controller: _calNextDueController,
                  label: 'Calibration Next Due:',
                  hintText: 'MM/DD/YYYY',
                ),
                _buildTextField(
                  controller: _daysRemainController,
                  label: 'Days Remaining Until Calibration:',
                  hintText: 'e.g., 180',
                ),
                _buildDateField(
                  controller: _calLastController,
                  label: 'Calibration Last Completed:',
                  hintText: 'MM/DD/YYYY',
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
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
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }
}
