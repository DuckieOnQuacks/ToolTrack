import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:vineburgapp/admin/bins/add_bin.dart';
import 'package:vineburgapp/admin/bins/edit_bin.dart';
import '../../classes/bin_class.dart';
import '../../login.dart';

class AdminBinsPage extends StatefulWidget {
  const AdminBinsPage({super.key});

  @override
  State<AdminBinsPage> createState() => _AdminBinsPageState();
}

class _AdminBinsPageState extends State<AdminBinsPage> {
  Future<List<Bin>>? bins;
  TextEditingController searchController = TextEditingController();
  late Future<List<Bin>> filteredBins;
  late List<Color> shuffledColors;
  final ValueNotifier<int> binCountNotifier = ValueNotifier<int>(0);

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
    bins = getAllBins();
    filteredBins = bins!;
    shuffledColors = getRandomlyAssortedColors(cncShopColors);
    searchController.addListener(_onSearchChanged);
    updateBinCount();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    binCountNotifier.dispose();
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
        filteredBins = bins!.then((allBins) => allBins.where((bin) {
          return bin.originalName.toLowerCase().contains(query.toLowerCase()) ||
              bin.location.toLowerCase().contains(query.toLowerCase());
        }).toList());
      } else {
        filteredBins = bins!;
      }
    });
    updateBinCount();
  }

  void updateBinCount() {
    filteredBins.then((list) {
      binCountNotifier.value = list.length;
    });
  }

  Future<void> refreshBinsList() async {
    setState(() {
      bins = getAllBins();
      filteredBins = bins!;
      shuffledColors = getRandomlyAssortedColors(cncShopColors);
    });
    updateBinCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin Search', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[900],
        automaticallyImplyLeading: false,
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (context) =>const AdminAddBinPage()));
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
                hintText: "Search by bin name or location",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: binCountNotifier,
            builder: (context, count, child) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Number of Results: $count',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refreshBinsList,
              child: FutureBuilder<List<Bin>>(
                future: filteredBins,
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
                    final bins = snapshot.data!;
                    if (bins.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Bins Found",
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
                      itemCount: bins.length,
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
                            leading: const Icon(Icons.storage, color: Colors.black),
                            trailing: IconButton(
                              icon:
                              const Icon(Icons.delete, color: Colors.black),
                              onPressed: () => onDeletePressed(bins[index]),
                            ),
                            title: Text(
                              bins[index].originalName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              'Location: ${bins[index].location}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            onTap: () async {
                              var result = await Navigator.of(context)
                                  .push(MaterialPageRoute(
                                builder: (context) =>
                                    AdminInspectBinScreen(
                                      bin: bins[index],
                                    ),
                              ));
                              if (result == true) {
                                refreshBinsList();
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

  void onDeletePressed(Bin bin) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteBinDialog(bin: bin),
    );
    if (result != null && result) {
      // Implement bin deletion logic here
      refreshBinsList();
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

class DeleteBinDialog extends StatelessWidget {
  final Bin bin;

  const DeleteBinDialog({super.key, required this.bin});

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
          'Are you sure you want to remove this bin from the database?'),
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
            // Implement bin deletion logic here
            deleteBin(bin);
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

