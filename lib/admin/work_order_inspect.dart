import 'package:flutter/material.dart';
import '../classes/work_order_class.dart';

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

  @override
  void initState() {
    super.initState();
    partNameController = TextEditingController(text: widget.workOrder.partName);
    poNumberController = TextEditingController(text: widget.workOrder.po);
    partNumberController = TextEditingController(text: widget.workOrder.partNum);
    enteredByController = TextEditingController(text: widget.workOrder.enteredBy);
  }

  @override
  void dispose() {
    partNameController.dispose();
    poNumberController.dispose();
    partNumberController.dispose();
    enteredByController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
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
            'Tools Used:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          FutureBuilder<List<String>>(
            future: getToolIdsFromWorkOrder(widget.workOrder.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                List<String> toolIds = snapshot.data!;
                return Column(
                  children: toolIds.map((toolId) => ListTile(
                    title: Text(toolId),
                  )).toList(),
                );
              } else {
                return const ListTile(
                  title: Text('No tools listed'),
                );
              }
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _showImageFullscreen(context, widget.workOrder.imagePath),
            child: const Text('Workorder Image'),
          ),
        ],
      ),
    );
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


// Function to display the image in full screen
  void _showImageDialog(BuildContext context, String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black, // Fullscreen with black background
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Transparent AppBar
          elevation: 0, // No shadow
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white), // White close icon
            onPressed: () => Navigator.of(context).pop(), // Close the fullscreen
          ),
        ),
        body: Center( // Center the image
          child: InteractiveViewer( // Allows pinch-to-zoom
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    ));
  }
}

