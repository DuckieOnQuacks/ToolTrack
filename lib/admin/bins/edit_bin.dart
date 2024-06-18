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

  final Map<int, List<String>> drawerNames = {
    1: [
      'Unlabelled',
      'Unlabelled',
      '.0000s-1400s',
      '.1500s-.2600s',
      '.2000s-.4370s',
      'Unlabelled',
      'Unlabelled',
      'Unlabelled',
      'Unlabelled'
    ],
    2: [
      'Unlabelled',
      'Unlabelled',
      'Gage Pin Sets .011-.060',
      'Gage Pin Sets .061-.250',
      'Gage Pin Sets .061-.250',
      'Gage Pin Sets .251-.500',
      'Gage Pin Sets .251-.500',
      'Gage Pin Sets .501-.625',
      'Gage Pin Sets .626-.750',
      'Gage Pin Sets .751-1.000'
    ],
    3: [
      'Depth & Groove Mics',
      'Pitch Mics',
      'Mueller Gages/Recess Indicators',
      '9"-10" Mics',
      '0"-1" Mics',
      '3"-4" & 4"-5" Mics',
      '1"-2" Mics',
      '2"-3" Mics & Indicator Mics',
      '5"-6" & 6"-7" Mics',
      '7"-8" & 8"-9" Mics',
      'Drop Indicators',
      'Bore Gages',
      'Torque Wrench',
      'Unlabelled',
      'Bore Mics'
    ],
    4: [
      'Thread Plug Gages Standard',
      'Thread Plug Gages Standard',
      'Thread Plug Gages Large',
      'Thread Plug Gages Large',
      'Thread Plug Gages Metric',
      'Thread Ring Gages',
      'Pipe Thread Ring Gages',
      'Thread Ring Gages Standard',
      'Thread Ring Gages Standard',
      'Large Thread Ring Gages Standard',
      'Thread Ring Gages Metric',
      'Misc & Custom Gage Pins',
      'Misc & Custom Pin Gages'
    ],
  };

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
                                  locationController.text =
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
                                  locationController.text =
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
                                  locationController.text =
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
                                  locationController.text =
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
                              locationController.text = 'No Location Set';
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
                    if (locationController.text.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          locationController.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildTextField({required TextEditingController controller, required String label, required String hintText}) {
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
                    const SizedBox(height: 4),
                    Text(tool.gageDesc,
                        style: const TextStyle(fontSize: 14, color: Colors.white70)), // Added for description
                    const SizedBox(height: 4),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 1.25,
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
          const Text(
            'Finished',
            style: TextStyle(
              fontSize: 18,
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
