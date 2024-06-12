import 'package:flutter/material.dart';
import 'package:vineburgapp/admin/bins/bins.dart';
import 'package:vineburgapp/admin/tools/tools.dart';
import 'package:vineburgapp/admin/workorder/workorder.dart';

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
    0: const AdminToolsPage(),
    1: const AdminWorkOrdersPage(),
    2: const AdminBinsPage()
  };

  void onItemTapped(int index) {
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.build),
              label: 'Tools',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Work Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inbox),
              label: 'Bins',
            ),
          ],
          currentIndex: selectedIndex,
          unselectedItemColor: Colors.grey[600],
          selectedItemColor: Colors.white,
          selectedIconTheme: const IconThemeData(size: 30, color: Colors.white),
          unselectedIconTheme: const IconThemeData(size: 25, color: Colors.grey),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          onTap: onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
