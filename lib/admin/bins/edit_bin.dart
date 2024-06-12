import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../../backend/message_helper.dart';
import '../../classes/bin_class.dart';
import '../../classes/tool_class.dart';

class AdminInspectBinScreen extends StatefulWidget {
  final Bin bin;
  const AdminInspectBinScreen({super.key, required this.bin});

  @override
  State<AdminInspectBinScreen> createState() => _AdminInspectBinScreenState();
}

class _AdminInspectBinScreenState extends State<AdminInspectBinScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController newToolController = TextEditingController();
  late List<Tool> tools;
  late List<Tool> initialTools;
  bool finished = false;
  bool isLoading = true;
  int selectedCabinet = 0;
  int selectedDrawer = 0;
  bool noLocationSelected = false;

  Future<void> fetchInitialTools(List<String?> toolIds) async {
    List<Tool> fetchedTools = [];
    for (var toolId in toolIds) {
      final toolDoc = await FirebaseFirestore.instance
          .collection('Tools')
          .doc(toolId)
          .get();
      if (toolDoc.exists) {
        fetchedTools.add(Tool.fromJson(toolDoc.data()!));
      }
    }
    setState(() {
      tools = fetchedTools;
      initialTools = List.from(fetchedTools);
      isLoading = false;
    });
  }

  void confirmChanges(BuildContext context) {
    List<Widget> changesWidgets = [];

    if (nameController.text != widget.bin.originalName) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'Name: ',
          style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
          children: <TextSpan>[
            TextSpan(
              text: '${widget.bin.originalName} -> ${nameController.text}',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ));
    }
    const SizedBox(height: 10);
    if (locationController.text != widget.bin.location) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'Location: ',
          style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
          children: <TextSpan>[
            TextSpan(
              text: '${widget.bin.location} -> ${locationController.text}',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ));
    }
    const SizedBox(height: 10);
    final addedTools =
    tools.where((tool) => !initialTools.contains(tool)).toList();
    final removedTools =
    initialTools.where((tool) => !tools.contains(tool)).toList();

    if (addedTools.isNotEmpty) {
      changesWidgets.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Added Tools:',
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          ...addedTools.map((tool) => Text(
            tool.gageID,
            style: const TextStyle(
                fontWeight: FontWeight.normal, color: Colors.white),
          )),
        ],
      ));
    }

    if (removedTools.isNotEmpty) {
      changesWidgets.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Removed Tools:',
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          ...removedTools.map((tool) => Text(
            tool.gageID,
            style: const TextStyle(
                fontWeight: FontWeight.normal, color: Colors.white),
          )),
        ],
      ));
    }
    if (finished != widget.bin.finished) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Finished: ',
            style: const TextStyle(
                fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.bin.finished} -> $finished',
                  style: const TextStyle(fontWeight: FontWeight.normal)),
            ]),
      ));
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          buttonPadding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Text(
                'Confirm Changes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: changesWidgets,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newBin = Bin(
                    originalName: nameController.text,
                    location: locationController.text,
                    tools: tools.map((tool) => tool.gageID).toList(),
                    finished: finished);
                await updateBinIfDifferent(widget.bin, newBin);
                if (context.mounted) {
                  Navigator.of(context).pop(true);
                  Navigator.of(context).pop(true);
                  showTopSnackBar(
                      context, "Changes Saved Successfully", Colors.green,
                      title: "Success", icon: Icons.check_circle);
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> addTool() async {
    final toolId = newToolController.text.trim();
    if (toolId.isNotEmpty) {
      bool alreadyExists = tools.any((tool) => tool.gageID == toolId);
      if (alreadyExists) {
        showTopSnackBar(
            context, "Tool ID $toolId is already in the list.", Colors.red,
            title: "Error", icon: Icons.error);
      } else {
        Tool? validTool = await validateAndFetchTool(context, toolId);
        if (validTool != null) {
          setState(() {
            tools.add(validTool);
            newToolController.clear();
          });
        }
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
    showTopSnackBar(context, "Tool ID copied to clipboard", Colors.blue,
        title: "Note:", icon: Icons.copy);
  }

  @override
  void initState() {
    super.initState();
    nameController.text = widget.bin.originalName;
    locationController.text = widget.bin.location;
    tools = [];
    initialTools = [];
    fetchInitialTools(widget.bin.tools);
    finished = widget.bin.finished;

    // Parse initial location
    final initialLocation = parseLocation(widget.bin.location);
    selectedCabinet = initialLocation['cabinet'] ?? 0;
    selectedDrawer = initialLocation['drawer'] ?? 0;
    noLocationSelected = (selectedCabinet == 0 && selectedDrawer == 0);
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    newToolController.dispose();
    super.dispose();
  }

  // Parse the location string to get cabinet and drawer numbers
  Map<String, int?> parseLocation(String location) {
    final regex = RegExp(r'Cabinet (\d+) - Drawer (\d+)');
    final match = regex.firstMatch(location);
    if (match != null) {
      return {
        'cabinet': int.parse(match.group(1)!),
        'drawer': int.parse(match.group(2)!)
      };
    }
    return {'cabinet': null, 'drawer': null}; // Default values if parsing fails
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
                              locationController.text =
                              'Cabinet $selectedCabinet - Drawer $selectedDrawer';
                              noLocationSelected = false;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (cabinet == selectedCabinet &&
                                  drawer == selectedDrawer)
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
                                  color: (cabinet == selectedCabinet &&
                                      drawer == selectedDrawer)
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
                    locationController.text = 'No Location Set';
                    noLocationSelected = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                  noLocationSelected ? Colors.red : Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Set No Location'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit/View Bin Details'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Bin Information'),
                    _buildModeledCheckbox(),
                    _buildTextField(
                      controller: nameController,
                      label: 'Bin Name: ',
                      hintText: 'e.g. Bin A',
                    ),
                    _buildLocationPicker(),
                    _buildToolsList(),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => confirmChanges(context),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
        required String label,
        required String hintText}) {
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
      padding: const EdgeInsets.only(bottom: 20, top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tools:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          isLoading
              ? Center(
            child: Lottie.asset(
              'assets/lottie/loading.json',
              width: 100,
              height: 100,
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              Tool tool = tools[index];
              String status = tool.status;
              IconData statusIcon;
              Color statusColor;

              switch (status.toLowerCase()) {
                case 'available':
                  statusIcon = Icons.check_circle_outline;
                  statusColor = Colors.green;
                  break;
                case 'checked out':
                  statusIcon = Icons.cancel_outlined;
                  statusColor = Colors.red;
                  break;
                default:
                  statusIcon = Icons.help_outline;
                  statusColor = Colors.grey;
              }

              return ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tool.gageID,
                        style: const TextStyle(fontSize: 18)),
                    Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.blue),
                      onPressed: () => copyToolToClipboard(tool.gageID),
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

  Widget _buildModeledCheckbox() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.5,
            child: Checkbox(
              value: finished,
              onChanged: (bool? value) {
                setState(() {
                  finished = value ?? false;
                });
              },
              activeColor: Colors.orange[800],
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Finished',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
