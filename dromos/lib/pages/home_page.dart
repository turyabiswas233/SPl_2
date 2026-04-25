import 'package:dromos/pages/home/notifications_page.dart';
import 'package:dromos/screens/waiting_screen.dart';
import 'package:dromos/services/notification_handler.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/location.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = UserService().currentUser;
  final _notificationHandler = NotificationHandler();
  int _unreadCount = 0;

  List<AssetImage> carImages = [
    AssetImage('assets/cars/car1.jpg'),
    AssetImage('assets/cars/car2.png'),
    AssetImage('assets/cars/car3.png'),
    AssetImage('assets/cars/car4.jpg'),
  ];

  LocationInfo currentLocation = LocationInfo.getInstance();

  bool isLoadingLocation = false;
  bool _isLocationEnabled = false;

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      await LocationInfo.resolveCurrentCity(LocationAccuracy.bestForNavigation);
      LocationInfo loc = LocationInfo.getInstance();

      setState(() {
        currentLocation = loc;
      });
    } catch (e) {
      debugPrint('Error fetching location: $e');
    } finally {
      setState(() {
        isLoadingLocation = false;
      });
    }
  }

  Future<void> _checkLocationEnabled() async {
    bool enabled = await Permission.location.isGranted;
    setState(() {
      _isLocationEnabled = enabled;
    });
  }

  Future<void> _fetchNotifications() async {
    await _notificationHandler.fetchNotifications();
    if (mounted) {
      setState(() {
        _unreadCount = _notificationHandler.unreadCount;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLocationEnabled().then((_) {
      if (_isLocationEnabled) {
        _fetchCurrentLocation();
      }
    });
    if (user.isEmpty) {
      UserService().logout();
    }
    _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingLocation) {
      return const WaitingOverlay(captionText: "Fetching your location...");
    }
    return Scaffold(
      backgroundColor: ConstColor.primaryBg,
      body: Stack(
        children: [
          // Purple Header Background
          Container(
            height: MediaQuery.of(context).size.height * 40,
            decoration: BoxDecoration(color: ConstColor.primaryPurple),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20, width: 10),
                        // Location + Avatar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. The Location Button (Pill shape)
                                    ElevatedButton.icon(
                                      onPressed: _fetchCurrentLocation,
                                      // The Icon part
                                      icon: isLoadingLocation
                                          ? SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(ConstColor.primaryPurple),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.location_on,
                                              color: ConstColor.primaryPurple,
                                              size: 14,
                                            ),

                                      // The Text part
                                      label: Text(
                                        LocationInfo.getInstance()
                                                    .getLocation() ==
                                                null
                                            ? "Tap to detect location"
                                            : currentLocation
                                                      .getName()
                                                      .toString() +
                                                  (currentLocation.getName() ==
                                                          null
                                                      ? ''
                                                      : ', ') +
                                                  currentLocation
                                                      .getSubLocality()
                                                      .toString() +
                                                  (currentLocation
                                                              .getSubLocality() ==
                                                          null
                                                      ? ''
                                                      : ', ') +
                                                  currentLocation
                                                      .getLocality()
                                                      .toString(),
                                        style: const TextStyle(
                                          color: ConstColor
                                              .primaryPurple, // Text color
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                      // The Styling (White BG + Full Radius)
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.white, // White background
                                        elevation: 0, // Flat look
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ), // Add a little spacing between button and name
                                    // 2. The User Name
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 4.0,
                                      ), // Align slightly with the button curve
                                      child: Text(
                                        user.fullName,
                                        style: ConstFonts.semibold(
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // Notification bell + avatar
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsPage(),
                                      ),
                                    ).then((_) => _fetchNotifications());
                                  },
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                if (_unreadCount > 0)
                                  Positioned(
                                    right: 6,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 18,
                                      ),
                                      child: Text(
                                        '$_unreadCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        Text(
                          "Locate your\nchosen vehicle.",
                          style: ConstFonts.bold(size: 28, color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // White Rounded Container
                  Container(
                    padding: const EdgeInsets.only(
                      top: 10,
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 10),

                            // Highlight Card
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [
                                    ConstColor.primaryPurple,
                                    ConstColor.primaryPurple25,
                                  ],
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text(
                                    "Identify the closest\nvehicle",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),

                            // Available Near You
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  "Available Near You",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "See All",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),
                            SizedBox(
                              height: 150,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: carImages.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 15),
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 220,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      image: DecorationImage(
                                        image: carImages[index],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
