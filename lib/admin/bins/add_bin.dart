import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/message_helper.dart';
import '../../classes/bin_class.dart';

class AdminAddBinPage extends StatefulWidget {
  const AdminAddBinPage({super.key});

  @override
  State<StatefulWidget> createState() => _AdminAddBinPageState();
}

class _AdminAddBinPageState extends State<AdminAddBinPage> {
  final User user = FirebaseAuth.instance.currentUser!;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _binNameController = TextEditingController();
  final TextEditingController _binLocationController = TextEditingController();
  final TextEditingController _toolsController = TextEditingController();

  @override
  void dispose() {
    _binNameController.dispose();
    _binLocationController.dispose();
    _toolsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Show top snackbar warning if any required field is not filled
      showTopSnackBar(context, "Please fill in all required fields.", Colors.red, title: "Error", icon: Icons.error);
      return;
    }
    try {
      // Use the parts as parameters for addBinWithParams
      await addBinWithParams(
        _binNameController.text,
        _binLocationController.text,
        _toolsController.text.split(',').map((tool) => tool.trim()).toList(),
      );
      // Simulate a delay
      // Navigate back to the first route and show the snack-bar
      if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
      Future.delayed(const Duration(milliseconds: 100), () {
        showTopSnackBar(context, "Added bin successfully", Colors.green, title: "Success", icon: Icons.check_circle);
      });
    } catch (e) {
      showTopSnackBar(context, "Failed to add new bin. Please try again.", Colors.red, title: "Error", icon: Icons.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter Bin Details'),
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
                _buildSectionHeader('Bin Information'),
                _buildTextField(
                  controller: _binNameController,
                  label: 'Enter Bin Name: *',
                  hintText: 'e.g. Bin A',
                  validator: (value) =>
                  value!.isEmpty ? 'This field is required' : null,
                ),
                _buildTextField(
                  controller: _binLocationController,
                  label: 'Enter Bin Location: *',
                  hintText: 'e.g. Shelf 1',
                  validator: (value) =>
                  value!.isEmpty ? 'This field is required' : null,
                ),
                _buildTextField(
                  controller: _toolsController,
                  label: 'Enter Tools (separated by commas): *',
                  hintText: 'e.g. Tool1, Tool2, Tool3',
                  validator: (value) =>
                  value!.isEmpty ? 'This field is required' : null,
                ),
                const SizedBox(height: 20),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submitForm(),
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
}
