import 'package:flutter/material.dart';
import 'package:vineburgapp/admin/Workorder/work_order_inspect_tools.dart';
import '../../classes/work_order_class.dart';

class AdminInspectOrderScreen extends StatefulWidget {
  final WorkOrder workOrder; // Pass in currently selected work order.

  const AdminInspectOrderScreen({super.key, required this.workOrder});

  @override
  _AdminInspectOrderScreenState createState() => _AdminInspectOrderScreenState();
}

class _AdminInspectOrderScreenState extends State<AdminInspectOrderScreen> {
  late TextEditingController partNameController;
  late TextEditingController poNumberController;
  late TextEditingController partNumberController;
  late TextEditingController enteredByController;
  late TextEditingController statusController;

  @override
  void initState() {
    super.initState();
    partNameController = TextEditingController(text: widget.workOrder.partName);
    poNumberController = TextEditingController(text: widget.workOrder.po);
    partNumberController = TextEditingController(text: widget.workOrder.partNum);
    enteredByController = TextEditingController(text: widget.workOrder.enteredBy);
    statusController = TextEditingController(text: widget.workOrder.status);
  }

  @override
  void dispose() {
    partNameController.dispose();
    poNumberController.dispose();
    partNumberController.dispose();
    enteredByController.dispose();
    statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Order Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          IconButton(
            icon: const Icon(Icons.image),
            color: Colors.blueAccent,
            iconSize: 100.0,
            onPressed: () =>
                _showImageFullscreen(context, widget.workOrder.imagePath),
          ),
          const SizedBox(height: 20),
          const Text(
            'Part Name:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: partNameController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'PO Number:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: poNumberController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Part Number:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: partNumberController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Entered By:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: enteredByController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Status',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          DropdownButton<String>(
            value: widget.workOrder.status, // Assuming this is a string. Adjust if your implementation differs.
            icon: const Icon(Icons.arrow_drop_down), // Customizable icon
            elevation: 16, // Shadow elevation for the dropdown menu
            style: const TextStyle(color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.normal), // Text style
            underline: Container( // Custom underline styling
              height: 1,
              color: Colors.grey,
            ),
            onChanged: (String? newValue) {
              setState(() {
                widget.workOrder.status = newValue!; // Update the status
              });
            },
            items: <String>['Active', 'Completed'] // Dropdown menu items
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tools Used:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.view_list), // Choose an appropriate icon
            alignment: Alignment.centerLeft,
            color: Colors.blueAccent,
            iconSize: 40,
            onPressed: () async {
              final List<String> toolIds = await getToolIdsFromWorkOrder(widget.workOrder.id);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ToolsListScreen(toolIds: toolIds),
              ));
            },
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 50),
            child: ElevatedButton (
              onPressed: () => _confirmChanges(context),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue, // Button color
                onPrimary: Colors.white, // Text color
                elevation: 5, // Button shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ), // Button padding
              ),
              child: const Text('Submit Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

            ),
          ),
        ],
      ),
    );
  }

  void _confirmChanges(BuildContext context) {
    // Compare current values with original values and create a list of changes
    List<Widget> changesWidgets = [];
    if (partNameController.text != widget.workOrder.partName) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'Part Name: ',
          style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
          children: <TextSpan>[
            TextSpan(
              text: '${widget.workOrder.partName} -> ${partNameController.text}',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      );
    }
    const SizedBox(height: 10);
    if (poNumberController.text != widget.workOrder.po) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'PO Number: ',
            style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                text: '${widget.workOrder.po} -> ${poNumberController.text}',
                style: const TextStyle(fontWeight: FontWeight.normal)
              )
            ]
            ),
      ));
    }
    const SizedBox(height: 10);
    if (partNumberController.text != widget.workOrder.partNum) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'Part Number: ',
            style: const TextStyle(
            fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
              children: <TextSpan>[

              TextSpan(
                text: '${widget.workOrder.partNum} -> ${partNumberController.text}',
                style: const TextStyle(fontWeight: FontWeight.normal)
            ),
          ]
        ),
      ));
    }
    const SizedBox(height: 10);
    if (enteredByController.text != widget.workOrder.enteredBy) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Part Number: ',
            style: const TextStyle(
                fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
            children: <TextSpan>[

              TextSpan(
                  text: '${widget.workOrder.enteredBy} -> ${enteredByController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)
              ),
            ]
        ),
      ));
    }

    const SizedBox(height: 10);
    if (statusController.text != widget.workOrder.status) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Status: ',
            style: const TextStyle(
                fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
            children: <TextSpan>[

              TextSpan(
                  text: '${statusController.text} -> ${widget.workOrder.status} ',
                  style: const TextStyle(fontWeight: FontWeight.normal)
              ),
            ]
        ),
      ));
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Changes"),
          content: SingleChildScrollView(
            child: ListBody(
              children: changesWidgets.isNotEmpty
                  ? changesWidgets
                  : [const Text("No changes made.")],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () async {
                await updateWorkOrder(widget.workOrder.id,
                    partName: partNameController.text,
                    po: poNumberController.text,
                    partNum: partNumberController.text,
                    enteredBy: enteredByController.text);
                Navigator.of(context).pop();
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

}

  void _showImageFullscreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Workorder Image'),
          leading: const BackButton(), // Uses default back button
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    ));
  }



