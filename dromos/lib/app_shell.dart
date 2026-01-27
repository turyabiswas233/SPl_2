import 'package:dromos/pages/account/login_page.dart';
import 'package:dromos/pages/home/home_page.dart';
import 'package:dromos/utils/_colors.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0; // 0 for Home, 1 for Settings

  // List of the pages to be displayed
  static final List<Widget> _pages = <Widget>[
    const HomeScreen(), // Your HomeScreen
    const LoginScreen(), // The LoginScreen from before
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body is now an IndexedStack, which keeps the state
      // of the pages when switching tabs.
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: ConstColor.primary_purple,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.login), label: 'Login'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple[100],
        onTap: _onItemTapped,
      ),
    );
  }
}
