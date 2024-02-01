import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../classes/tool_class.dart';
import '../login_page.dart';
import '../user/scan_tool_page.dart';


// All code on this page was developed by the team using the flutter framework
class UserToolsPage extends StatefulWidget {
  const UserToolsPage({super.key});

  @override
  State<UserToolsPage> createState() => _UserToolsPageState();
}

class _UserToolsPageState extends State<UserToolsPage> {
  Future<List<Tool>>? tools;
  TextEditingController searchController = TextEditingController();
  late Future<List<Tool>> filteredTools;

  @override
  void initState() {
    super.initState();
    tools = getUserTools();
    filteredTools = tools!; // Initially, filteredTools will show all tools
  }

  void filterSearchResults(String query) {
    if (query.isNotEmpty) {
      setState(() {
        filteredTools = tools!.then((allTools) =>
            allTools.where((tool) {
              return tool.toolName.toLowerCase().contains(
                  query.toLowerCase()) ||
                  tool.personCheckedTool.toLowerCase().contains(
                      query.toLowerCase());
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
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
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
                        ]
                    ),
                    content: const Text(
                        'Are you sure you want to log out of your account?'),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.grey[300],
                          onPrimary: Colors.black54,
                        ),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (BuildContext context) {
                                    return const LoginPage();
                                  })
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.redAccent,
                          onPrimary: Colors.white,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  );
                },
              ).then((value) {
                if (value != null && value == true) {
                  // Perform deletion logic here
                }
              });
            },
          ),
        ],
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
                hintText: "Search by tool name",
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
                      child: Text("No Tools"),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: tools.length,
                    itemBuilder: (context, index) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 4,
                        child: ListTile(
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
                              Text('Checked Out On: ${tools[index].dateCheckedOut}'),
                              Text('Calibration Date: ${tools[index].calibrationDate}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.restore),
                            //border_color
                            onPressed: () {
                              // Define your action here
                              print('Return icon tapped for ${tools[index].toolName}');
                            },
                          ),
                          onTap: () => print('ListTile tapped for ${tools[index].toolName}'),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text("No Tools Checked Out"),
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }
}





