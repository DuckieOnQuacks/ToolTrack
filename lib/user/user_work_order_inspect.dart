import 'package:flutter/material.dart';
import '../classes/work_order_class.dart';

class InspectOrderScreen extends StatefulWidget {
  final WorkOrder workOrder; //Pass in currently selected work order.

  const InspectOrderScreen({super.key, required this.workOrder});

  @override
  _InspectOrderScreenState createState() => _InspectOrderScreenState();
}

class _InspectOrderScreenState extends State<InspectOrderScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspect Order'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          RichText(
            text: TextSpan(
              text: 'Part Name: ',
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
              children: <TextSpan>[
                TextSpan(
                  text: widget.workOrder.partName,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              text: 'PO Number: ',
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
              children: <TextSpan>[
                TextSpan(
                  text: widget.workOrder.po,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              text: 'Part Number: ',
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
              children: <TextSpan>[
                TextSpan(
                  text: widget.workOrder.partNum,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              text: 'Entered By: ',
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
              children: <TextSpan>[
                TextSpan(
                  text: widget.workOrder.enteredBy,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
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
          GestureDetector(
            onTap: () {
              _showImageDialog(context, widget.workOrder.imagePath);
            },
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: Image.network(
                widget.workOrder.imagePath,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ],
      ),
    );
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

