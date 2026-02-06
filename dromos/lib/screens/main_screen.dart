import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart'; // Import this
import 'package:dromos/screens/account_page.dart';
import 'package:dromos/utils/colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 3;

  static final List<Widget> _widgetOptions = <Widget>[
    const Center(child: Text('Home Page')),
    const Center(child: Text('Notifications Page')),
    const Center(child: Text('Activity Page')),
    AccountPage(),
  ];

  Color black = ConstColor.primaryColor;
  Color white = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        color: white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: SalomonBottomBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),

          // Optional: Add a subtle shadow
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              title: const Text("Home"),
              selectedColor: ConstColor.primaryPurple,
            ),

            SalomonBottomBarItem(
              icon: const Icon(Icons.notifications_outlined),
              activeIcon: const Icon(Icons.notifications),
              title: const Text("Notify"),
              selectedColor: Colors.pink, // You can vary colors per tab
            ),

            SalomonBottomBarItem(
              icon: const Icon(Icons.local_activity_outlined),
              activeIcon: const Icon(Icons.local_activity),
              title: const Text("Activity"),
              selectedColor: Colors.orange,
            ),

            SalomonBottomBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              title: const Text("Account"),
              selectedColor: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}