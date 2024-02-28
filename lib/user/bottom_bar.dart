import 'package:flutter/material.dart';
import 'package:vineburgapp/profile_page.dart';
import 'package:vineburgapp/user/Workorder/work_order.dart';

import 'Tools/tools.dart';

// All code on this page was developed by the team using the flutter framework
class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int selectedIndex = 0;
  // What pages to load depending on the bottom bar index
  final Map<int, Widget> widgetOptions = {
    0: const UserWorkOrderPage(),
    1: const UserToolsPage(),
    2: ProfilePage(),
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
            label: 'Work Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: 'Your Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: selectedIndex,
        backgroundColor: Colors.white,
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }
}