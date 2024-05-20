import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vineburgapp/admin/tool_inspect.dart';
import '../classes/toolClass.dart';
import '../login.dart';
import 'add_tool.dart';

class AdminToolsPage extends StatefulWidget {
  const AdminToolsPage({super.key});

  @override
  State<AdminToolsPage> createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage> {
  Future<List<Tool>>? tools;
  TextEditingController searchController = TextEditingController();
  late Future<List<Tool>> filteredTools;

  @override
  void initState() {
    super.initState();
    tools = getAllTools();
    filteredTools = tools!; // Initially, filteredTools will show all tools
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      setState(() {
        filteredTools = tools!.then((allTools) => allTools.where((tool) {
          return tool.gageType.toLowerCase().contains(query.toLowerCase()) || tool.gageID.toLowerCase().contains(query.toLowerCase());
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
        title: const Text('Tool Search', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const AdminAddToolPage()), // Navigate to AdminAddToolPage
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showLogoutConfirmationDialog(context);
            },
          ),
        ],
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
                hintText: "Search by tool name or ID",
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
                  return Center(
                    child: Lottie.asset(
                      'assets/lottie/loading.json',
                      width: 200,
                      height: 200,
                    ),
                  );
                } else if (snapshot.hasData) {
                  final tools = snapshot.data!;
                  if (tools.isEmpty) {
                    return const Center(
                      child: Text(
                        "No Tools Found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
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
                            icon: const Icon(Icons.delete),
                            onPressed: () => onDeletePressed(tools[index]),
                          ),
                          title: Text(
                            tools[index].gageDesc,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text('Gage ID: ${tools[index].gageID}'),
                          onTap: () async {
                            var result = await Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => AdminInspectToolScreen(tool: tools[index]),
                            ));
                            if (result == true) {
                              refreshToolsList();
                            }
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return Center(
                    child: Lottie.asset(
                      'assets/lottie/error.json', // An error animation (make sure you have this asset)
                      width: 200,
                      height: 200,
                    ),
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
      tools = getAllTools();
      filteredTools = tools!;
    });
  }

  void onDeletePressed(Tool tool) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteToolDialog(tool: tool),
    );
    if (result != null && result) {
      // Implement tool deletion logic here
      refreshToolsList();
    }
  }

  void showLogoutConfirmationDialog(BuildContext context) {
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
                Icons.warning_amber_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: const Text('Are you sure you want to log out of your account?'),
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
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => const LoginPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}

class DeleteToolDialog extends StatelessWidget {
  final Tool tool;

  const DeleteToolDialog({super.key, required this.tool});

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
            foregroundColor: Colors.black54,
            backgroundColor: Colors.grey[300],
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Implement tool deletion logic here
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
