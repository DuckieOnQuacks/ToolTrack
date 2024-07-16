import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:vineburgapp/user/home.dart';
import '../../backend/message_helper.dart';
import '../../classes/tool_class.dart';
import '../../user/return_tool.dart';
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
  final ValueNotifier<int> toolCountNotifier = ValueNotifier<int>(0);
  String selectedFilter = 'All'; // Default filter option
  String selectedGageType = 'All';

  final List<String> filterOptions = ['All', 'Available', 'Checked Out', 'Ring Gage', "Plug Gage", "Caliper", "Micrometer"];
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

  void onSearchChanged() {
    EasyDebounce.debounce(
      'search-debouncer', // <-- An identifier for this particular debouncer
      const Duration(milliseconds: 500), // <-- The debounce duration
          () => filterSearchResults(searchController.text), // <-- The target method
    );
  }

  void filterSearchResults(String query) {
    setState(() {
      filteredTools = tools!.then((allTools) => allTools.where((tool) {
        bool matchesQuery =
            tool.gageID.toLowerCase().contains(query.toLowerCase()) ||
                tool.gageType.toLowerCase().contains(query.toLowerCase()) ||
                tool.checkedOutTo.toLowerCase().contains(query.toLowerCase()) ||
                tool.gageDesc.toLowerCase().contains(query.toLowerCase()) ||
                tool.diameter.toLowerCase().contains(query.toLowerCase()) ||
                tool.height.toLowerCase().contains(query.toLowerCase());

        bool matchesFilter = selectedFilter == 'All' ||
            (selectedFilter == 'Available' && tool.status == 'Available') ||
            (selectedFilter == 'Checked Out' && tool.status == 'Checked Out') ||
            (selectedFilter == "Ring Gage" && (tool.gageType == "THREAD RING GAGE" || tool.gageType == "Thread Ring Gage")) ||
            (selectedFilter == "Plug Gage" && (tool.gageType == "THREAD PLUG GAGE" || tool.gageType == "Thread Plug Gage")) ||
            (selectedFilter == "Caliper" && tool.gageType == "Caliper") ||
            (selectedFilter == "Micrometer" && (tool.gageType == "MICROMETER" || tool.gageType == "Micrometer"));

        bool matchesGageType = selectedGageType == 'All' ||
            tool.gageType == selectedGageType;

        return matchesQuery && matchesFilter && matchesGageType;
      }).toList());
    });
    updateToolCount();
  }

  void updateToolCount() {
    filteredTools.then((list) {
      toolCountNotifier.value = list.length;
    });
  }

  Future<void> refreshToolsList() async {
    setState(() {
      tools = getAllTools();
      filteredTools = tools!;
      shuffledColors = getRandomlyAssortedColors(cncShopColors);
    });
    updateToolCount();
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

  void confirmReturn(Tool tool) async {
    if (context.mounted) {
      try {
        if (tool.status == "Available") {
          showTopSnackBar(context, "Tool is marked as already returned.", Colors.red, title: "Error", icon: Icons.error);
          return;
        }
        await returnTool(tool.gageID, tool.checkedOutTo);
        showTopSnackBar(context, "Return successful!", Colors.green, title: "Success", icon: Icons.check_circle);
      } catch (e) {
        showTopSnackBar(context, "Failed to return. Please try again.", Colors.red, title: "Error", icon: Icons.error);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    tools = getAllTools();
    filteredTools = tools!;
    shuffledColors = getRandomlyAssortedColors(cncShopColors);
    searchController.addListener(onSearchChanged);
    updateToolCount();
  }

  @override
  void dispose() {
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    toolCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.question_mark_sharp, color: Colors.white),
          onPressed: () {
            showAdminInstructionsDialog(context, 'Tools');
          },
        ),
        title: const Text('Tool Search', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.grey[900],
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () async {
              var result = await Navigator.of(context)
                  .push(MaterialPageRoute(
                builder: (context) =>
                const AdminAddToolPage(),
              ));
              if (result == true) {
                refreshToolsList();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) => const HomePage(), // Change to the user home page
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ValueListenableBuilder<int>(
              valueListenable: toolCountNotifier,
              builder: (context, count, child) {
                return Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: "Search",
                        hintText: "Search by user, tool ID, type, or description",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                    Positioned(
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(25.0),
                        ),
                        child: Text(
                          '$count Results',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterOptions.map((option) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: ChoiceChip(
                            label: Text(option),
                            selected: selectedFilter == option,
                            onSelected: (selected) {
                              setState(() {
                                selectedFilter = option;
                                filterSearchResults(searchController.text);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
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
                        Color tileColor = shuffledColors[index % shuffledColors.length];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [tileColor.withOpacity(0.8), tileColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.build, color: Colors.black),
                              trailing: PopupMenuButton<int>(
                                icon: const Icon(Icons.more_vert, color: Colors.black),
                                onSelected: (int result) {
                                  if (result == 0) {
                                    confirmReturn(tools[index]);
                                  } else if (result == 1) {
                                    onDeletePressed(tools[index]);
                                  }
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
                                  const PopupMenuItem<int>(
                                    value: 0,
                                    child: ListTile(
                                      leading: Icon(Icons.assignment_return, color: Colors.white),
                                      title: Text('Return Tool'),
                                    ),
                                  ),
                                  const PopupMenuItem<int>(
                                    value: 1,
                                    child: ListTile(
                                      leading: Icon(Icons.delete, color: Colors.white),
                                      title: Text('Delete Tool'),
                                    ),
                                  ),
                                ],
                              ),
                              title: Text(
                                tools[index].gageID,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tools[index].gageType,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                var result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => AdminInspectToolScreen(
                                      tool: tools[index],
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  refreshToolsList();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(
                      child: Lottie.asset(
                        'assets/lottie/loading.json',
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
            size: 24,
          ),
          SizedBox(width: 10),
          Text(
            'Confirm Delete',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      content: Text('Remove tool ${tool.gageID} from the database?'),
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
