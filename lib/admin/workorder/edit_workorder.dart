import 'package:another_flushbar/flushbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../classes/workorder_class.dart';

class AdminInspectWorkOrderScreen extends StatefulWidget {
  final WorkOrder workOrder;

  const AdminInspectWorkOrderScreen({super.key, required this.workOrder});

  @override
  State<AdminInspectWorkOrderScreen> createState() => _AdminInspectWorkOrderScreenState();
}

class _AdminInspectWorkOrderScreenState extends State<AdminInspectWorkOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController idController = TextEditingController();
  final TextEditingController enteredByController = TextEditingController();
  final TextEditingController newToolController = TextEditingController();

  late List<String> tools;
  late List<String> initialTools;

  @override
  void initState() {
    super.initState();
    idController.text = widget.workOrder.id;
    enteredByController.text = widget.workOrder.enteredBy;
    tools = List.from(widget.workOrder.tool ?? []);
    initialTools = List.from(widget.workOrder.tool ?? []);
  }

  @override
  void dispose() {
    idController.dispose();
    enteredByController.dispose();
    newToolController.dispose();
    super.dispose();
  }

  void showTopSnackBar(BuildContext context, String message, Color color) {
    Flushbar(
      message: message,
      duration: const Duration(seconds: 3),
      flushbarPosition: FlushbarPosition.TOP,
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: color,
    ).show(context);
  }

  void _confirmChanges(BuildContext context) {
    List<Widget> changesWidgets = [];

    if (idController.text != widget.workOrder.id) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'ID: ',
          style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
          children: <TextSpan>[
            TextSpan(
              text: '${widget.workOrder.id} -> ${idController.text}',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ));
    }

    const SizedBox(height: 10);

    if (enteredByController.text != widget.workOrder.enteredBy) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'Entered By: ',
          style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
          children: <TextSpan>[
            TextSpan(
              text: '${widget.workOrder.enteredBy} -> ${enteredByController.text}',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ));
    }

    const SizedBox(height: 10);

    final addedTools = tools
        .where((tool) => !initialTools.contains(tool))
        .toList();
    final removedTools = initialTools
        .where((tool) => !tools.contains(tool))
        .toList();

    if (addedTools.isNotEmpty) {
      changesWidgets.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Added Tools:',
            style: TextStyle(
                fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
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
                fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.white),
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
                final newWorkOrder = WorkOrder(
                  id: idController.text,
                  enteredBy: enteredByController.text,
                  tool: tools,
                  imagePath: "",
                );
                await updateWorkOrderIfDifferent(widget.workOrder, newWorkOrder);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  showTopSnackBar(
                      context, "Changes saved successfully", Colors.green);
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
    showTopSnackBar(context, "Tool ID copied to clipboard", Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit/View Work Order Details'),
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
                    const SizedBox(height: 20),
                    _buildSectionHeader('Work Order Information'),
                    _buildTextField(
                      controller: idController,
                      label: 'Work Order ID: ',
                      hintText: 'e.g. 2345',
                    ),
                    _buildTextField(
                      controller: enteredByController,
                      label: 'Entered By: ',
                      hintText: 'e.g. 12402',
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

  Widget _buildTextField({required TextEditingController controller, required String label, required String hintText,}) {
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
          const Text(
            'Tools:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
          TextFormField(
            controller: newToolController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'Enter tool ID',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                onPressed: _addTool,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateWorkOrderIfDifferent(WorkOrder oldWorkOrder, WorkOrder newWorkOrder) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    if (oldWorkOrder.toJson() != newWorkOrder.toJson()) {
      await firestore.collection('WorkOrders').doc(newWorkOrder.id).set(newWorkOrder.toJson());
    }
  }
}
