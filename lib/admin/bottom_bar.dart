import 'package:flutter/material.dart';
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
    1: const AdminWorkOrdersPage()
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
              icon: Icon(Icons.work),
              label: 'Work Orders',
            ),

          ],
          currentIndex: selectedIndex,
          unselectedItemColor: Colors.grey[600],
          selectedItemColor: Colors.white,
          selectedIconTheme: IconThemeData(size: 30, color: Colors.white),
          unselectedIconTheme: IconThemeData(size: 25, color: Colors.grey),
          showSelectedLabels: true,
          showUnselectedLabels: false,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
