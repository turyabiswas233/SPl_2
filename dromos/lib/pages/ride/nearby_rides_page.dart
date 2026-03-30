import 'package:dromos/models/nearby_ride_model.dart';
import 'package:dromos/screens/waiting_screen.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/location.dart';
import 'package:dromos/widgets/ride_chat_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyRidesPage extends StatefulWidget {
  const NearbyRidesPage({super.key});

  @override
  State<NearbyRidesPage> createState() => _NearbyRidesPageState();
}

class _NearbyRidesPageState extends State<NearbyRidesPage> {
  final _rideService = RideService();

  List<NearbyRideModel> _nearbyRides = [];
  bool _isLoading = false;
  bool _isLocationEnabled = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLocationAndFetchRides();
  }

  Future<void> _checkLocationAndFetchRides() async {
    bool enabled = await Permission.location.isGranted;

    if (!enabled) {
      setState(() {
        _isLocationEnabled = false;
        _errorMessage = 'Location permission required to find nearby rides';
      });
      return;
    }

    setState(() {
      _isLocationEnabled = true;
    });
    _fetchNearbyRides();
  }

  Future<void> _fetchNearbyRides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      dynamic location = LocationInfo.getInstance();
      if (LocationInfo.isResolved == false) {
        await LocationInfo.resolveCurrentCity();
        location = LocationInfo.getInstance();
      }

      final rides = await _rideService.fetchNearbyRides(
        lng: location.getLocation().longitude,
        lat: location.getLocation().latitude,
      );

      if (mounted) {
        setState(() {
          _nearbyRides = rides;
          if (_nearbyRides.isEmpty) {
            _errorMessage = 'No nearby rides available at the moment';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching nearby rides: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load nearby rides. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestRide(String rideId) async {
    try {
      final result = await _rideService.requestRide(rideId);

      if (mounted) {
        if (result != null && result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request sent successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          debugPrint(
            'Request failed: ${result?['message'] ?? 'Unknown error'}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result?['message'] ?? 'Failed to send request',
                style: const TextStyle(color: Colors.red),
              ),
              backgroundColor: Colors.red.shade50,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error requesting ride: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error sending request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChatBottomSheet(
    BuildContext context,
    String rideId,
    String initiatorName,
    String destinationName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => RideChatBottomSheet(
        rideId: rideId,
        rideName: '$initiatorName - $destinationName',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _nearbyRides.isEmpty) {
      return const WaitingOverlay(captionText: "Finding nearby rides...");
    }

    return Scaffold(
      backgroundColor: ConstColor.primaryBg,
      appBar: AppBar(
        backgroundColor: ConstColor.primaryPurple,
        title: const Text(
          'Nearby Rides',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLocationEnabled == false
          ? _buildPermissionError()
          : _errorMessage != null && _nearbyRides.isEmpty
          ? _buildEmptyState()
          : _buildRidesList(),
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: ConstColor.primaryPurple.withAlpha(100),
          ),
          const SizedBox(height: 20),
          const Text(
            'Location Permission Required',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'Enable location to find nearby rides in your area',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ConstColor.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: openAppSettings,
            child: const Text(
              'Enable Location',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: ConstColor.primaryPurple.withAlpha(100),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Nearby Rides Available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              _errorMessage ?? 'Check back later for available rides',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ConstColor.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _fetchNearbyRides,
            child: const Text('Refresh', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildRidesList() {
    return RefreshIndicator(
      onRefresh: _fetchNearbyRides,
      color: ConstColor.primaryPurple,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _nearbyRides.length,
        itemBuilder: (context, index) {
          final ride = _nearbyRides[index];
          return _buildRideCard(ride);
        },
      ),
    );
  }

  Widget _buildRideCard(NearbyRideModel ride) {
    final availablePercentage = ride.maxSeats > 0
        ? (ride.availableSeats / ride.maxSeats * 100).toInt()
        : 0;

    String _parseDistance(double distance) {
      if (distance < 1000) {
        return '${distance.toStringAsFixed(0)} m';
      } else {
        final kilometers = distance / 1000;
        return '${kilometers.toStringAsFixed(1)} km';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ConstColor.primaryPurple.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: ConstColor.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${ride.startLocation} (${ride.distance} m away)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${ride.destinationName} (${_parseDistance(ride.travellingDistance)})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Seats Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Seats',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: availablePercentage > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${ride.availableSeats}/${ride.maxSeats}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Occupancy',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: availablePercentage / 100,
                          minHeight: 6,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            availablePercentage > 50
                                ? Colors.green
                                : availablePercentage > 25
                                ? Colors.orange
                                : Colors.red,
                          ),
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConstColor.primaryPurple.withAlpha(50),
                      foregroundColor: ConstColor.primaryPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    onPressed: () => _showChatBottomSheet(
                      context,
                      ride.rideId,
                      ride.initiatorName,
                      ride.destinationName,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      overlayColor: Colors.white12,
                      backgroundColor: ride.availableSeats > 0
                          ? ConstColor.primaryPurple
                          : Colors.grey,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    onPressed: ride.availableSeats > 0
                        ? () => _requestRide(ride.rideId)
                        : null,
                    child: Text(
                      ride.availableSeats > 0 ? 'Request' : 'Full',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
