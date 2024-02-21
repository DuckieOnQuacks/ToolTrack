import 'package:flutter/material.dart';
import 'package:vineburgapp/admin/Workorder/work_order_inspect_tools.dart';
import '../../classes/work_order_class.dart';

class UserInspectOrderScreen extends StatefulWidget {
  final WorkOrder workOrder; // Pass in currently selected work order.

  const UserInspectOrderScreen({super.key, required this.workOrder});

  @override
  _UserInspectOrderScreenState createState() => _UserInspectOrderScreenState();
}

class _UserInspectOrderScreenState extends State<UserInspectOrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          IconButton(
            icon: const Icon(Icons.image),
            color: Colors.blueAccent,
            iconSize: 100.0,
            onPressed: () => _showImageFullscreen(context, widget.workOrder.imagePath),
          ),
          const SizedBox(height: 20),
          // Title is bold
          const Text(
            'Part Name:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          // Data is normal
          Text(
            widget.workOrder.partName,
            style: const TextStyle(fontSize: 18.0),
          ),
          const SizedBox(height: 20),
          // Title is bold
          const Text(
            'PO Number:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          // Data is normal
          Text(
            widget.workOrder.po,
            style: const TextStyle(fontSize: 18.0),
          ),
          const SizedBox(height: 20),
          // Title is bold
          const Text(
            'Part Number:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          // Data is normal
          Text(
            widget.workOrder.partNum,
            style: const TextStyle(fontSize: 18.0),
          ),
          const SizedBox(height: 20),
          // Title is bold
          const Text(
            'Entered By:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          // Data is normal
          Text(
            widget.workOrder.enteredBy,
            style: const TextStyle(fontSize: 18.0),
          ),
          // Title is bold
          const SizedBox(height: 20),
          const Text(
            'Status:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          // Data is normal
          Text(
            widget.workOrder.status,
            style: const TextStyle(fontSize: 18.0),
          ),
          const SizedBox(height: 20),
          // Title is bold
          const Text(
            'Tools Used:',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
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
        ],
      ),
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



