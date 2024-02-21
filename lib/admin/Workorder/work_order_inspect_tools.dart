import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../classes/tool_class.dart';
import '../../classes/work_order_class.dart';

class ToolsListScreen extends StatefulWidget {
  final List<String> toolIds;

  const ToolsListScreen({super.key, required this.toolIds});

  @override
  _ToolsListScreenState createState() => _ToolsListScreenState();
}


class _ToolsListScreenState extends State<ToolsListScreen> {
  TextEditingController searchController = TextEditingController();
  List<Tool> tools = []; // List to store all tools
  List<Tool> filteredTools = []; // List to store filtered tools

  @override
  void initState() {
    super.initState();
    fetchTools();
  }

  // Asynchronous function to fetch tools
  void fetchTools() async {
    try {
      var fetchedTools = await getToolsFromToolIds(widget.toolIds);
      setState(() {
        tools = fetchedTools;
        filteredTools = fetchedTools;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching tools: $e");
      }
    }
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      setState(() {
        filteredTools = tools
            .where((tool) => tool.toolName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      });
    } else {
      setState(() {
        filteredTools = tools;
      });
    }
  }

  void onDeletePressed(Tool toolRemove) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          DeleteMachineDialog(tool: toolRemove),
    );
    if (result != null && result) {
      setState(() {
        tools.removeWhere((tool) => tool.toolName == toolRemove.toolName);
        filteredTools.removeWhere((tool) => tool.toolName == toolRemove.toolName);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools List'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterSearchResults,
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Search",
                hintText: "Search by tool name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredTools.isEmpty
                ? const Center(
              child: Text(
                'No tools',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey, // Optional: Changes color to grey
                ),
              ),
            )
                : ListView.builder(
              itemCount: filteredTools.length,
              itemBuilder: (context, index) {
                Tool tool = filteredTools[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: ListTile(
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        onDeletePressed(tool);
                      },// Assuming toolName is not nullable
                    ),
                    title: Text(
                      tool.toolName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Checked Out To: ${tool.personCheckedTool}'),
                        Text('Located At Machine: ${tool.whereBeingUsed}'),
                      ],
                    ),
                    onTap: () {
                      // Handle the tap event for each tool
                      if (kDebugMode) {
                        print('Tapped on tool: ${tool.toolName}');
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DeleteMachineDialog extends StatelessWidget {
  final Tool tool;

  const DeleteMachineDialog({super.key, required this.tool});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      buttonPadding: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      title: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
          ),
          SizedBox(width: 10),
          Text(
            'Confirm Delete',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      content: const Text(
          'Are you sure you want to remove this tool from this workorder?'),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black54,
            backgroundColor: Colors.grey[300],
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await tool.deleteToolFromWorkorder(tool);
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.redAccent,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
