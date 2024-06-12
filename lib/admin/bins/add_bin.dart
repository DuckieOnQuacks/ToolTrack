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
  int selectedCabinet = 0;
  int selectedDrawer = 0;

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Show top snackbar warning if any required field is not filled
      showTopSnackBar(
          context, "Please fill in all required fields.", Colors.red,
          title: "Error", icon: Icons.error);
      return;
    }
    try {
      final location = 'Cabinet $selectedCabinet - Drawer $selectedDrawer';
      // Use the parts as parameters for addBinWithParams
      await addBinWithParams(
          _binNameController.text,
          location,
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
                _buildLocationPicker(),
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

  Widget _buildLocationPicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Location:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (int cabinet = 1; cabinet <= 4; cabinet++)
                Expanded(
                  child: Column(
                    children: [
                      Text('Cabinet $cabinet',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      for (int drawer = 1; drawer <= 10; drawer++)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCabinet = cabinet;
                              selectedDrawer = drawer;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (cabinet == selectedCabinet && drawer == selectedDrawer)
                                  ? Colors.orange
                                  : Colors.grey[600],
                              border: Border.all(color: Colors.black, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                'Drawer $drawer',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: (cabinet == selectedCabinet && drawer == selectedDrawer)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
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
