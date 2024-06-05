import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../backend/message_helper.dart';
import '../../classes/bin_class.dart';

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

  late List<String> tools;
  late List<String> initialTools;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.bin.originalName;
    locationController.text = widget.bin.location;
    tools = List.from(widget.bin.tools ?? []);
    initialTools = List.from(widget.bin.tools ?? []);
    finished = widget.bin.finished;
  }

  @override
  void dispose() {
    nameController.dispose();
    locationController.dispose();
    newToolController.dispose();
    super.dispose();
  }

  void _confirmChanges(BuildContext context) {
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
              text:
              '${widget.bin.location} -> ${locationController.text}',
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
            tool,
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
            tool,
            style: const TextStyle(
                fontWeight: FontWeight.normal, color: Colors.white),
          )),
        ],
      ));
    }
    if (finished != widget.bin.finished) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Modeled: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.white),
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
                  tools: tools,
                  finished: finished
                );
                await updateBinIfDifferent(widget.bin, newBin);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  showTopSnackBar(context, "Changes Saved Successfully", Colors.green, title: "Success", icon: Icons.check_circle);
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

  void _addTool() {
    if (newToolController.text.isNotEmpty) {
      setState(() {
        tools.add(newToolController.text);
        newToolController.clear();
      });
    }
  }

  void _removeTool(int index) {
    setState(() {
      tools.removeAt(index);
    });
  }

  void _copyToolToClipboard(String tool) {
    Clipboard.setData(ClipboardData(text: tool));
    showTopSnackBar(context, "Tool ID copied to clipboard", Colors.blue, title: "Note:", icon: Icons.copy);
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
                    _buildTextField(
                      controller: locationController,
                      label: 'Location: ',
                      hintText: 'e.g. Shelf 1',
                    ),
                    _buildToolsList(),
                    const SizedBox(height: 20),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _confirmChanges(context),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
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
                      onPressed: () => _copyToolToClipboard(tools[index]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeTool(index),
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
                    onPressed: _addTool,
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


