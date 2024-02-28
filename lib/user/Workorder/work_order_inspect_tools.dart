import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../classes/tool_class.dart';

class UserToolsListScreen extends StatefulWidget {
  final List<String> toolIds;

  const UserToolsListScreen({super.key, required this.toolIds});

  @override
  _UserToolsListScreenState createState() => _UserToolsListScreenState();
}


class _UserToolsListScreenState extends State<UserToolsListScreen> {
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
              padding: const EdgeInsets.all(10),
              itemCount: filteredTools.length,
              itemBuilder: (context, index) {
                Tool tool = filteredTools[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: ListTile(
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


