import 'package:dromos/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:dromos/pages/profile/account_page.dart';
import 'package:dromos/utils/colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomePage(),
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
      backgroundColor: Colors.white,
      body: _widgetOptions.elementAt(_selectedIndex),

      bottomNavigationBar: Container(
        color: Colors.transparent,

        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: SalomonBottomBar(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              itemPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              items: [
                SalomonBottomBarItem(
                  icon: const Icon(Icons.home_outlined),
                  title: const Text("Home"),
                  selectedColor: ConstColor.primaryPurple,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.chat_bubble_outline),
                  title: const Text("Chat"),
                  selectedColor: ConstColor.primaryPurple,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.local_activity_outlined),
                  title: const Text("Activity"),
                  selectedColor: ConstColor.primaryPurple,
                ),
                SalomonBottomBarItem(
                  icon: const Icon(Icons.person_outline),
                  title: const Text("Account"),
                  selectedColor: ConstColor.primaryPurple,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
