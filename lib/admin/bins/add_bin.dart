import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController newToolController = TextEditingController();
  List<String> tools = [];

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Show top snackbar warning if any required field is not filled
      showTopSnackBar(
          context, "Please fill in all required fields.", Colors.red,
          title: "Error", icon: Icons.error);
      return;
    }
    try {
      // Use the parts as parameters for addBinWithParams
      await addBinWithParams(
          _binNameController.text,
          _binLocationController.text,
          tools,
          false
      );
      // Simulate a delay
      // Navigate back to the first route and show the snack-bar
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
      Future.delayed(const Duration(milliseconds: 100), () {
        showTopSnackBar(
            context, "Bin added successfully", Colors.green, title: "Success",
            icon: Icons.check_circle);
      });
    } catch (e) {
      showTopSnackBar(
          context, "Failed to add new bin. Please try again.", Colors.red,
          title: "Error", icon: Icons.error);
    }
  }

  Future<void> addTool() async {
    final toolId = newToolController.text.trim();
    if (toolId.isNotEmpty) {
      final toolDoc = await FirebaseFirestore.instance.collection('Tools').doc(toolId).get();
      if (toolDoc.exists) {
        setState(() {
          tools.add(toolId);
          newToolController.clear();
        });
      } else {
        showTopSnackBar(context, "Tool ID does not exist in the database. Please add the new tool before assigning it to a bin.", Colors.red, title: "Error", icon: Icons.error);
      }
    }
  }

  void removeTool(int index) {
    setState(() {
      tools.removeAt(index);
    });
  }

  void copyToolToClipboard(String tool) {
    Clipboard.setData(ClipboardData(text: tool));
    showTopSnackBar(context, "Tool ID copied to clipboard", Colors.green, title: "Copied", icon: Icons.check_circle);
  }

  @override
  void dispose() {
    _binNameController.dispose();
    _binLocationController.dispose();
    _toolsController.dispose();
    newToolController.dispose();
    super.dispose();
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
                  hintText: 'e.g. 5/8 - 32',
                  validator: (value) =>
                  value!.isEmpty ? 'This field is required' : null,
                ),
                _buildTextField(
                  controller: _binLocationController,
                  label: 'Enter Bin Location: ',
                  hintText: 'e.g. Drawer 1 Column 2',
                ),
                _buildToolsList(),
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

  Widget _buildTextField({required TextEditingController controller, required String label, required String hintText, String? Function(String?)? validator,}) {
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

  Widget _buildToolsList() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tools:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(tools[index]),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.blue),
                      onPressed: () => copyToolToClipboard(tools[index]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => removeTool(index),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: SizedBox(
              width: 450,
              child: TextFormField(
                controller: newToolController,
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  hintText: 'Add Tool ID',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: addTool,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
