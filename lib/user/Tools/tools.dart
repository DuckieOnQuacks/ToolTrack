import 'package:flutter/material.dart';
import 'package:vineburgapp/user/Tools/tool_inspect.dart';
import 'package:vineburgapp/user/Tools/tool_return.dart';
import '../../classes/tool_class.dart';

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
        title: const Text('Your Tools'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
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
                              onPressed: () async {
                                bool? shouldRefresh = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ToolReturnPage(toolToReturn: tools[index])),
                                );
                                if (shouldRefresh == true) {
                                  // Call your refreshTools function here
                                  refreshToolsList();
                                }
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
}






