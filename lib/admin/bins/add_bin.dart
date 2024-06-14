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

  final Map<int, List<String>> drawerNames = {
    1: ['Unlabelled', 'Unlabelled',
      '.0000s-1400s', '.1500s-.2600s',
      '.2000s-.4370s', 'Unlabelled',
      'Unlabelled', 'Unlabelled',
      'Unlabelled'],
    2: ['Unlabelled', 'Unlabelled',
      'Gage Pin Sets .011-.060', 'Gage Pin Sets .061-.250',
      'Gage Pin Sets .061-.250', 'Gage Pin Sets .251-.500',
      'Gage Pin Sets .251-.500', 'Gage Pin Sets .501-.625',
      'Gage Pin Sets .626-.750', 'Gage Pin Sets .751-1.000'],
    3: ['Depth & Groove Mics', 'Pitch Mics',
      'Mueller Gages/Recess Indicators', '9"-10" Mics',
      '0"-1" Mics', '3"-4" & 4"-5" Mics',
      '1"-2" Mics', '2"-3" Mics & Indicator Mics',
      '5"-6" & 6"-7" Mics', '7"-8" & 8"-9" Mics',
      'Drop Indicators', 'Bore Gages',
      'Torque Wrench', 'Unlabelled',
      'Bore Mics'],
    4: ['Thread Plug Gages Standard', 'Thread Plug Gages Standard',
      'Thread Plug Gages Large', 'Thread Plug Gages Large',
      'Thread Plug Gages Metric', 'Thread Ring Gages',
      'Pipe Thread Ring Gages', 'Thread Ring Gages Standard',
      'Thread Ring Gages Standard', 'Large Thread Ring Gages Standard',
      'Thread Ring Gages Metric', 'Misc & Custom Gage Pins',
      'Misc & Custom Pin Gages'],
  };

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Show top snackbar warning if any required field is not filled
      showTopSnackBar(
          context, "Please fill in all required fields.", Colors.red,
          title: "Error", icon: Icons.error);
      return;
    }
    try {
      final location = 'Cabinet $selectedCabinet - Drawer ${drawerNames[selectedCabinet]?[selectedDrawer - 1]}';
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

  void _showDrawerSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        const totalHeight = 675.0; // Total height allocated for drawer boxes
        const drawerMargin = 4.0;
        const drawerPadding = 8.0;
        final heights = [
          (totalHeight / 9) - drawerMargin, // Cabinet 1: 9 drawers
          (totalHeight / 10) - drawerMargin, // Cabinet 2: 10 drawers
          (totalHeight / 15) - drawerMargin, // Cabinet 3: 15 drawers
          (totalHeight / 13) - drawerMargin, // Cabinet 4: 13 drawers
        ];

        return SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Cabinet 1',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          for (int drawer = 1; drawer <= 9; drawer++)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCabinet = 1;
                                  selectedDrawer = drawer;
                                  _binLocationController.text =
                                  'Cabinet $selectedCabinet - ${drawerNames[1]?[drawer - 1]}';
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: heights[0],
                                margin: const EdgeInsets.symmetric(vertical: drawerMargin / 2),
                                padding: const EdgeInsets.all(drawerPadding),
                                decoration: BoxDecoration(
                                  color: (selectedCabinet == 1 && selectedDrawer == drawer)
                                      ? Colors.orange
                                      : Colors.blue,
                                  border: Border.all(color: Colors.black, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    drawerNames[1]?[drawer - 1] ?? 'Drawer $drawer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: (selectedCabinet == 1 && selectedDrawer == drawer)
                                          ? Colors.white
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Cabinet 2',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          for (int drawer = 1; drawer <= 10; drawer++)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCabinet = 2;
                                  selectedDrawer = drawer;
                                  _binLocationController.text =
                                  'Cabinet $selectedCabinet - ${drawerNames[2]?[drawer - 1]}';
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: heights[1],
                                margin: const EdgeInsets.symmetric(vertical: drawerMargin / 2),
                                padding: const EdgeInsets.all(drawerPadding),
                                decoration: BoxDecoration(
                                  color: (selectedCabinet == 2 && selectedDrawer == drawer)
                                      ? Colors.orange
                                      : Colors.grey[700],
                                  border: Border.all(color: Colors.black, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    drawerNames[2]?[drawer - 1] ?? 'Drawer $drawer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: (selectedCabinet == 2 && selectedDrawer == drawer)
                                          ? Colors.white
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Cabinet 3',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          for (int drawer = 1; drawer <= 15; drawer++)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCabinet = 3;
                                  selectedDrawer = drawer;
                                  _binLocationController.text =
                                  'Cabinet $selectedCabinet - ${drawerNames[3]?[drawer - 1]}';
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: heights[2],
                                margin: const EdgeInsets.symmetric(vertical: drawerMargin / 2),
                                padding: const EdgeInsets.all(drawerPadding),
                                decoration: BoxDecoration(
                                  color: (selectedCabinet == 3 && selectedDrawer == drawer)
                                      ? Colors.orange
                                      : Colors.grey[700],
                                  border: Border.all(color: Colors.black, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    drawerNames[3]?[drawer - 1] ?? 'Drawer $drawer',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: (selectedCabinet == 3 && selectedDrawer == drawer)
                                          ? Colors.white
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Cabinet 4',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          for (int drawer = 1; drawer <= 13; drawer++)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCabinet = 4;
                                  selectedDrawer = drawer;
                                  _binLocationController.text =
                                  'Cabinet $selectedCabinet - ${drawerNames[4]?[drawer - 1]}';
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                height: heights[3],
                                margin: const EdgeInsets.symmetric(vertical: drawerMargin / 2),
                                padding: const EdgeInsets.all(drawerPadding),
                                decoration: BoxDecoration(
                                  color: (selectedCabinet == 4 && selectedDrawer == drawer)
                                      ? Colors.orange
                                      : Colors.green,
                                  border: Border.all(color: Colors.black, width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    drawerNames[4]?[drawer - 1] ?? 'Drawer $drawer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: (selectedCabinet == 4 && selectedDrawer == drawer)
                                          ? Colors.white
                                          : Colors.white,
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Center(
                      child: Container(
                        width: 150,
                        height: 35,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCabinet = 0;
                              selectedDrawer = 0;
                              _binLocationController.text = 'No Location Set';
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.grey[600],
                          ),
                          child: const Text('No Location'),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 150,
                        height: 35,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.redAccent,
                          ),
                          child: const Text('Close'),
                        ),
                      ),
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
                const SizedBox(height: 10),
                _buildSectionHeader('Bin Information'),
                _buildTextField(
                  controller: _binNameController,
                  label: 'Enter Bin Name: *',
                  hintText: 'e.g. 5/8 - 32',
                  validator: (value) =>
                  value!.isEmpty ? 'This field is required' : null,
                ),
                _buildLocationPicker(),
                if (_binLocationController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _binLocationController.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _buildToolsList(),
                const SizedBox(height: 10),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Location:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _showDrawerSelectionSheet(context),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                ),
                child: const Icon(Icons.add),
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
            padding: const EdgeInsets.only(left: 16), // Add left padding here
            child: SizedBox(
              width: 450, // Adjust this width to match the list items
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
