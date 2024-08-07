import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vineburgapp/admin/workorder/add_workorder.dart';
import 'package:vineburgapp/admin/workorder/edit_workorder.dart';
import '../../backend/message_helper.dart';
import '../../classes/workorder_class.dart';

class AdminWorkOrdersPage extends StatefulWidget {
  const AdminWorkOrdersPage({super.key});

  @override
  State<AdminWorkOrdersPage> createState() => _AdminWorkOrdersPageState();
}

class _AdminWorkOrdersPageState extends State<AdminWorkOrdersPage> {
  Future<List<WorkOrder>>? workOrders;
  late Future<List<WorkOrder>> filteredWorkOrders;
  late List<Color> shuffledColors;
  TextEditingController searchController = TextEditingController();
  final ValueNotifier<int> workOrderCountNotifier = ValueNotifier<int>(0);

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
      if (query.isNotEmpty) {
        filteredWorkOrders = workOrders!
            .then((allWorkOrders) => allWorkOrders.where((workOrder) {
          return workOrder.id
              .toLowerCase()
              .contains(query.toLowerCase()) ||
              workOrder.enteredBy
                  .toLowerCase()
                  .contains(query.toLowerCase());
        }).toList());
      } else {
        filteredWorkOrders = workOrders!;
      }
    });
    updateWorkOrderCount();
  }

  void updateWorkOrderCount() {
    filteredWorkOrders.then((list) {
      workOrderCountNotifier.value = list.length;
    });
  }

  Future<void> refreshWorkOrdersList() async {
    setState(() {
      workOrders = getAllWorkOrders();
      filteredWorkOrders = workOrders!;
      shuffledColors = getRandomlyAssortedColors(cncShopColors);
    });
    updateWorkOrderCount();
  }

  void onDeletePressed(WorkOrder workOrder) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) =>
          DeleteWorkOrderDialog(workOrder: workOrder),
    );
    if (result != null && result) {
      // Implement work order deletion logic here
      refreshWorkOrdersList();
    }
  }

  @override
  void initState() {
    super.initState();
    workOrders = getAllWorkOrders();
    filteredWorkOrders = workOrders!;
    shuffledColors = getRandomlyAssortedColors(cncShopColors);
    searchController.addListener(onSearchChanged);
    updateWorkOrderCount();
  }

  @override
  void dispose() {
    searchController.removeListener(onSearchChanged);
    searchController.dispose();
    workOrderCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.question_mark_sharp, color: Colors.white),
          onPressed: () {
            showAdminInstructionsDialog(context, 'Work Orders');
          },
        ),
        title: const Text('Work Order Search',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                    const AdminAddWorkOrderPage(),
              ));
              if (result == true) {
                refreshWorkOrdersList();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ValueListenableBuilder<int>(
              valueListenable: workOrderCountNotifier,
              builder: (context, count, child) {
                return Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: "Search",
                        hintText: "Search by ID or entered by",
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
                            fontSize: 16,
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshWorkOrdersList,
              child: FutureBuilder<List<WorkOrder>>(
                future: filteredWorkOrders,
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
                    final workOrders = snapshot.data!;
                    if (workOrders.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Work Orders Found",
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
                      itemCount: workOrders.length,
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
                            leading: const Icon(Icons.assignment,
                                color: Colors.black),
                            trailing: IconButton(
                              icon:
                              const Icon(Icons.delete, color: Colors.black),
                              onPressed: () =>
                                  onDeletePressed(workOrders[index]),
                            ),
                            title: Text(
                              workOrders[index].id,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              'Entered by: ${workOrders[index].enteredBy}',
                              style: const TextStyle(color: Colors.black87,fontSize: 14),
                            ),
                            onTap: () async {
                              var result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AdminInspectWorkOrderScreen(
                                        workOrder: workOrders[index],
                                      ),
                                ),
                              );
                              if (result == true) {
                                refreshWorkOrdersList();
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
}

class DeleteWorkOrderDialog extends StatelessWidget {
  final WorkOrder workOrder;

  const DeleteWorkOrderDialog({super.key, required this.workOrder});

  Future<void> deleteWorkOrder(WorkOrder workOrder) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      await firestore.collection('WorkOrders').doc(workOrder.id).delete();
      if (kDebugMode) {
        print('Work order ${workOrder.id} deleted successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting work order ${workOrder.id}: $e');
      }
    }
  }

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
          'Are you sure you want to remove this work order from the database?'),
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
            // Implement work order deletion logic here
            deleteWorkOrder(workOrder);
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
