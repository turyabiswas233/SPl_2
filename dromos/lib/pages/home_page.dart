import 'package:dromos/pages/profile/account_page.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/location.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/colors.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final user = UserService().currentUser;
  List<AssetImage> carImages = [
    AssetImage('assets/cars/car1.jpg'),
    AssetImage('assets/cars/car2.png'),
    AssetImage('assets/cars/car3.png'),
    AssetImage('assets/cars/car4.jpg'),
  ];

  LocationInfo? currentLocation;

  bool isLoadingLocation = false;
  bool _isLocationEnabled = false;

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      LocationInfo location = await LocationInfo.resolveCurrentCity();
      setState(() {
        currentLocation = location;
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

  @override
  void initState() {
    super.initState();
    _checkLocationEnabled();
    if(_isLocationEnabled) {
      _fetchCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ConstColor.primaryBg,
      body: RefreshIndicator(
        onRefresh: _fetchCurrentLocation,
        child: Stack(
          children: [
            // Purple Header Background
            Container(
              height: MediaQuery.of(context).size.height * 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ConstColor.primaryPurple,
                    ConstColor.primaryPurple.withAlpha((0.8 * 255).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 1. The Location Button (Pill shape)
                                      ElevatedButton.icon(
                                        onPressed: _fetchCurrentLocation,
                                        // The Icon part
                                        icon: isLoadingLocation
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(
                                                        ConstColor
                                                            .primaryPurple,
                                                      ),
                                                ),
                                              )
                                            : const Icon(
                                                Icons.location_on,
                                                color: ConstColor.primaryPurple,
                                                size: 16,
                                              ),

                                        // The Text part
                                        label: Text(
                                          currentLocation?.latitude != null
                                              ? '${currentLocation!.subLocality}, ${currentLocation!.locality}'
                                              : "Tap to detect location",
                                          style: const TextStyle(
                                            color: ConstColor
                                                .primaryPurple, // Text color
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
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
                                          shape:
                                              const StadiumBorder(), // This creates the full corner radius (pill shape)
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // show avater but on click show profile page, so add a button class and wrap the avatar in it
                              ElevatedButton(
                                onPressed: () {
                                  // go to profile page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AccountPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: CircleBorder(),
                                  padding: const EdgeInsets.all(0),
                                  backgroundColor: Colors.white,
                                ),
                                child: user.avatar(size: 24),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          const Text(
                            "Locate your\nchosen vehicle.",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
                      ),
                      margin: const EdgeInsets.only(left: 10, right: 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 5,
                            width: 40,
                            child: Divider(
                              thickness: 4,
                              color: Colors.grey,
                              radius: BorderRadius.all(Radius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Search Bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search),
                                SizedBox(width: 10),
                                Text("Search vehicle.."),
                              ],
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Top Brands
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                "Top Brands",
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
                            height: 70,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: carImages.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(Icons.directions_car),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 25),

                          // Highlight Card
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  ConstColor.primaryPurple,
                                  ConstColor.primaryPurple.withAlpha(200),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  "Identify the closest\nvehicle",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Icon(Icons.arrow_forward, color: Colors.white),
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
                              separatorBuilder: (_, __) =>
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
                          const SizedBox(height: 200),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
