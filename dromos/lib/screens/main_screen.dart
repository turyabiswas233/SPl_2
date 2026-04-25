import 'package:dromos/pages/home_page.dart';
import 'package:dromos/pages/ride/create_ride_page.dart';
import 'package:dromos/pages/ride/nearby_rides_page.dart';
import 'package:dromos/pages/activity/activity_page.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:dromos/pages/profile/account_page.dart';
import 'package:dromos/utils/colors.dart';

class MainScreenNavigation {
  static final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

  static void setPage(int index) {
    if (index < 0 || index >= widgetOptions.length) return;
    currentIndex.value = index;
  }

  static final List<Widget> widgetOptions = <Widget>[
    const HomePage(),
    CreateRidePage(onRideCreated: () => setPage(3)),
    const NearbyRidesPage(),
    const ActivityPage(),
    const AccountPage(),
  ];
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainScreenNavigation.currentIndex,
      builder: (context, selectedIndex, _) => Scaffold(
        backgroundColor: Colors.white,
        body: MainScreenNavigation.widgetOptions.elementAt(selectedIndex),
        bottomNavigationBar: Container(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: SalomonBottomBar(
                currentIndex: selectedIndex,
                curve: Curves.fastEaseInToSlowEaseOut,
                onTap: MainScreenNavigation.setPage,
                itemPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                items: [
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.home_outlined),
                    title: Text(
                      "Home",
                      style: ConstFonts.semibold(
                        color: ConstColor.primaryPurple,
                      ),
                    ),
                    selectedColor: ConstColor.primaryPurple,
                  ),
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.add_circle_outline),
                    title: Text(
                      "Create",
                      style: ConstFonts.semibold(
                        color: ConstColor.primaryPurple,
                      ),
                    ),
                    selectedColor: ConstColor.primaryPurple,
                  ),
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.directions_car_outlined),
                    title: Text(
                      "Browse",
                      style: ConstFonts.semibold(
                        color: ConstColor.primaryPurple,
                      ),
                    ),
                    selectedColor: ConstColor.primaryPurple,
                  ),
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.local_activity_outlined),
                    title: Text(
                      "Activity",
                      style: ConstFonts.semibold(
                        color: ConstColor.primaryPurple,
                      ),
                    ),
                    selectedColor: ConstColor.primaryPurple,
                  ),
                  SalomonBottomBarItem(
                    icon: const Icon(Icons.settings_rounded),
                    title: Text(
                      "Settings",
                      style: ConstFonts.semibold(
                        color: ConstColor.primaryPurple,
                      ),
                    ),
                    selectedColor: ConstColor.primaryPurple,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
