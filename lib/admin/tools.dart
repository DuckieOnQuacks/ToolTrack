import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_debounce/easy_debounce.dart';
import '../classes/tool_class.dart';
import '../login.dart';
import 'add_tool.dart';
import 'edit_tool.dart';

class AdminToolsPage extends StatefulWidget {
  const AdminToolsPage({super.key});

  @override
  State<AdminToolsPage> createState() => _AdminToolsPageState();
}

class _AdminToolsPageState extends State<AdminToolsPage> {
  Future<List<Tool>>? tools;
  TextEditingController searchController = TextEditingController();
  late Future<List<Tool>> filteredTools;
  late List<Color> shuffledColors;

  final List<Color> cncShopColors = [
    const Color(0xFF2E7D32), // Green
    const Color(0xFF607D8B), // Blue Grey
    const Color(0xFF546E7A), // Light Blue Grey
    const Color(0xFF4CAF50), // Medium Green
    const Color(0xFF78909C), // Greyish Blue
    const Color(0xFF00695C), // Teal
    const Color(0xFF00796B), // Medium Teal
    const Color(0xFF8D6E63), // Light Brown
    const Color(0xFF9E9E9E), // Grey
    const Color(0xFFBDBDBD), // Light Grey
    const Color(0xFFE0E0E0), // Very Light Grey
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFFFF9800), // Orange
    const Color(0xFFFFE0B2), // Light Orange
    const Color(0xFF8BC34A), // Light Green
  ];

  List<Color> getRandomlyAssortedColors(List<Color> colors) {
    final random = Random();
    final colorList = List<Color>.from(colors);
    colorList.shuffle(random);
    return colorList;
  }

  @override
  void initState() {
    super.initState();
    tools = getAllTools();
    filteredTools = tools!;
    shuffledColors = getRandomlyAssortedColors(cncShopColors);
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    EasyDebounce.debounce(
      'search-debouncer', // <-- An identifier for this particular debouncer
      const Duration(milliseconds: 500), // <-- The debounce duration
      () => filterSearchResults(searchController.text), // <-- The target method
    );
  }

  void filterSearchResults(String query) {
    setState(() {
      if (query.isNotEmpty) {
        filteredTools = tools!.then((allTools) => allTools.where((tool) {
              return tool.status.toLowerCase().contains(query.toLowerCase()) ||
                  tool.gageID.toLowerCase().contains(query.toLowerCase()) ||
                  tool.checkedOutTo.toLowerCase().contains(query.toLowerCase());
            }).toList());
      } else {
        filteredTools = tools!;
      }
    });
  }

  Future<void> refreshToolsList() async {
    setState(() {
      tools = getAllTools();
      filteredTools = tools!;
      shuffledColors = getRandomlyAssortedColors(cncShopColors);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tool Search', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const AdminAddToolPage()),
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
              controller: searchController,
              decoration: const InputDecoration(
                labelText: "Search",
                hintText: "Search by user, tool ID, or tool status",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshToolsList,
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
                        Color tileColor =
                            shuffledColors[index % shuffledColors.length];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                          color: tileColor,
                          child: ListTile(
                            trailing: IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.black),
                              onPressed: () => onDeletePressed(tools[index]),
                            ),
                            title: Text(
                              tools[index].gageID,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              'Type: ${tools[index].gageType}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            onTap: () async {
                              var result = await Navigator.of(context)
                                  .push(MaterialPageRoute(
                                builder: (context) =>
                                    AdminInspectToolScreen(tool: tools[index]),
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
                        'assets/lottie/error.json',
                        width: 200,
                        height: 200,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
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
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content:
              const Text('Are you sure you want to log out of your account?'),
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
              color: Colors.white,
            ),
          ),
        ],
      ),
      content: const Text(
          'Are you sure you want to remove this tool from the database?'),
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
            deleteTool(tool);
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
