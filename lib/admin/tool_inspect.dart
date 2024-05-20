import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../classes/toolClass.dart';

class AdminInspectToolScreen extends StatefulWidget {
  final Tool tool;

  const AdminInspectToolScreen({super.key, required this.tool});

  @override
  _AdminInspectToolScreenState createState() => _AdminInspectToolScreenState();
}

class _AdminInspectToolScreenState extends State<AdminInspectToolScreen> {
  late List<CameraDescription> cameras;
  late TextEditingController toolNameController;
  String imagePath = '';
  late TextEditingController whereBeingUsedController;
  late TextEditingController personCheckedOutController;
  late TextEditingController dateCheckedOutController;

  @override
  void initState() {
    super.initState();
    availableCameras().then((availableCameras) {
      cameras = availableCameras;
    });
    toolNameController = TextEditingController(text: widget.tool.gageType);
    whereBeingUsedController =
        TextEditingController(text: widget.tool.atMachine);
    personCheckedOutController =
        TextEditingController(text: widget.tool.status);
    dateCheckedOutController =
        TextEditingController(text: widget.tool.atMachine);
  }

  @override
  void dispose() {
    toolNameController.dispose();
    whereBeingUsedController.dispose();
    personCheckedOutController.dispose();
    dateCheckedOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Tool Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          IconButton(
            icon: const Icon(Icons.image),
            color: Colors.orange[800],
            iconSize: 100.0,
            onPressed: () =>
                _showImageFullscreen(context, widget.tool.imagePath),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tool Name:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: toolNameController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Located At Machine: ',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: whereBeingUsedController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Checked Out To: ',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: personCheckedOutController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text(
            'Check Out Date: ',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          TextFormField(
            controller: dateCheckedOutController,
            decoration: const InputDecoration(border: UnderlineInputBorder()),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.only(left: 50, right: 50),
            child: ElevatedButton(
              onPressed: () => _confirmChanges(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange[800],
                // Text color
                elevation: 5,
                // Button shadow
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
    if (toolNameController.text != widget.tool.gageType) {
      changesWidgets.add(RichText(
        text: TextSpan(
          text: 'Tool Name: ',
          style: const TextStyle(
              fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.black),
          children: <TextSpan>[
            TextSpan(
              text: '${widget.tool.gageType} -> ${toolNameController.text}',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      );
    }
    const SizedBox(height: 10);
    if (whereBeingUsedController.text != widget.tool.atMachine) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Located At Machine: ',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool
                      .atMachine} -> ${whereBeingUsedController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)
              )
            ]
        ),
      ));
    }
    const SizedBox(height: 10);
    if (personCheckedOutController.text != widget.tool.status) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Checked Out To:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool
                      .status} -> ${personCheckedOutController
                      .text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)
              ),
            ]
        ),
      ));
    }
    const SizedBox(height: 10);
    if (dateCheckedOutController.text != widget.tool.dateCheckedOut) {
      changesWidgets.add(RichText(
        text: TextSpan(
            text: 'Check Out Date:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.black),
            children: <TextSpan>[
              TextSpan(
                  text: '${widget.tool
                      .dateCheckedOut} -> ${dateCheckedOutController.text}',
                  style: const TextStyle(fontWeight: FontWeight.normal)
              ),
            ]
        ),
      ));
    }
  }

  void _showImageFullscreen(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>
          Scaffold(
            appBar: AppBar(
              title: const Text('Tool Image'),
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

}