import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vineburgapp/user/Tools/tool_inspect.dart';
import '../../classes/tool_class.dart';
import '../../login_page.dart';
import '../Workorder/scan_tool_workOrder.dart';


// All code on this page was developed by the team using the flutter framework
// All code on this page was developed by the team using the flutter framework
class UserToolsPage extends StatefulWidget {
  const UserToolsPage({super.key});

  @override
  State<UserToolsPage> createState() => _UserToolsPage();
}

class _UserToolsPage extends State<UserToolsPage> {
  Future<List<Tool>>? tools;
  TextEditingController searchController = TextEditingController();
  late Future<List<Tool>> filteredTools;


  @override
  void initState() {
    super.initState();
    tools = getUserTools();
    filteredTools = tools!; // Initially, filteredTools will show all tools
  }

  //Filters based on tool name and person checked out to.
  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      setState(() {
        filteredTools = tools!.then((allTools) => allTools.where((tool) {
          return tool.toolName.toLowerCase().contains(query.toLowerCase()) ||
              tool.personCheckedTool.toLowerCase().contains(query.toLowerCase());
        }).toList());
      });
    } else {
      setState(() {
        filteredTools = tools!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Search'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField( // 2. Add TextField
              onChanged: (value) {
                filterSearchResults(value);
              },
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Search",
                hintText: "Search by tool name, or person",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Tool>>(
              future: filteredTools,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasData) {
                  final tools = snapshot.data!;
                  if (tools.isEmpty) {
                    return const Center(
                      child: Text("No Tools",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: tools.length,
                    itemBuilder: (context, index) {
                      Color tileColor = tools[index].pastelColors[index % tools[index].pastelColors.length];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        color: tileColor,
                        child: ListTile(
                            trailing: IconButton(
                              icon: const Icon(Icons.restart_alt_outlined),
                              onPressed: () {
                                //onDeletePressed(tools[index]),
                              }
                            ),
                            title: Text(
                              tools[index].toolName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Checked Out To: ${tools[index].personCheckedTool}'),
                                Text('Located At Machine: ${tools[index].whereBeingUsed}'),
                              ],
                            ),
                            onTap: () async {
                              await Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => UserInspectToolScreen(tool: tools[index])));
                            }
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text("No Favorite Machines"),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void refreshToolsList() {
    setState(() {
      tools = getUserTools();
      filteredTools = tools!;
    });
  }

 /* void onDeletePressed(Tool tool) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteMachineDialog(tool: tool),
    );
    if (result != null && result) {
      await tool.deleteToolEverywhere(tool);
      setState(() {
        //Scan for favorites again after deletion
        tools = getUserTools();
        refreshToolsList();
      });
    }
  }*/
}

/*class DeleteMachineDialog extends StatelessWidget {
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
      content: const Text('Are you sure you want to remove this tool from the database?'),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black54, backgroundColor: Colors.grey[300],
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await tool.deleteToolEverywhere(tool);
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.redAccent,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}*/






