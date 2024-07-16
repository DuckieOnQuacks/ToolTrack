import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_debounce/easy_debounce.dart';
import '../../backend/message_helper.dart';
import '../../classes/tool_class.dart';

class UserToolsPage extends StatefulWidget {
  const UserToolsPage({super.key});

  @override
  State<UserToolsPage> createState() => _UserToolsPageState();
}

class _UserToolsPageState extends State<UserToolsPage> {
  Future<List<Tool>>? tools;
  TextEditingController searchController = TextEditingController();
  late Future<List<Tool>> filteredTools;
  late List<Color> shuffledColors;
  final ValueNotifier<int> toolCountNotifier = ValueNotifier<int>(0);
  String selectedFilter = 'All'; // Default filter option

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

        return matchesQuery && matchesFilter;
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
        title: const Text('Tool Search', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.grey[900],
        automaticallyImplyLeading: true,
        centerTitle: true,
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
                              onTap: () {
                                // Implement what happens when a tool is tapped, e.g., show tool details
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
