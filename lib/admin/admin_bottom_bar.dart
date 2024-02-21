import 'package:flutter/material.dart';
import 'package:vineburgapp/admin/Tools/tools.dart';
import 'package:vineburgapp/admin/Workorder/work_order.dart';

// All code on this page was developed by the team using the flutter framework
class AdminBottomBar extends StatefulWidget {
  const AdminBottomBar({super.key});

  @override
  State<AdminBottomBar> createState() => _AdminBottomBarState();
}

class _AdminBottomBarState extends State<AdminBottomBar> {
  int selectedIndex = 0;
  // What pages to load depending on the bottom bar index
  final Map<int, Widget> widgetOptions = {
    0: const WorkOrderPage(),
    1: const AdminToolsPage(),
  };

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: widgetOptions[selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'All Work Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'All Tools',
          ),
        ],
        currentIndex: selectedIndex,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
  }