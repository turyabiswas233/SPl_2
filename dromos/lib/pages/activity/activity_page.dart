import 'package:dromos/models/ride_model.dart';
import 'package:dromos/pages/ride/map_page.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/location.dart';
import 'package:dromos/widgets/ride_chat_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pinput/pinput.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rideService = RideService();
  final _userService = UserService();

  List<RideModel> _rides = [];
  List<RideModel> _myRequests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _rideService.fetchMyRides(),
        _rideService.fetchMyRequests(),
      ]);
      if (mounted) {
        setState(() {
          _rides = results[0];
          _myRequests = results[1];
        });
        _rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _myRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('Error fetching activity data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelRide(String rideId) async {
    // Show confirmation dialog
    final shouldCancel = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x88323244),
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Cancel ride?'),
        backgroundColor: Colors.white,
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(Colors.green.withAlpha(50)),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            style: ButtonStyle(
              overlayColor: WidgetStateProperty.all(
                ConstColor.error.withAlpha(50),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: ConstColor.error)),
          ),
        ],
      ),
    );

    if (shouldCancel != true) return;

    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(ConstColor.primaryPurple),
                ),
              ),
              SizedBox(width: 16),
              Text('Cancelling ride...'),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _rideService.cancelRide(rideId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result != null && result['success'] == true) {
        // Refresh rides list
        await _fetchData();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride cancelled successfully'),
            backgroundColor: ConstColor.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'Failed to cancel ride'),
            backgroundColor: Colors.red.shade100,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      debugPrint('Error cancelling ride: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade100,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _requestRide(String rideId) async {
    // Show loading indicator
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(ConstColor.primaryPurple),
                ),
              ),
              SizedBox(width: 16),
              Text('Requesting ride...'),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await _rideService.requestRide(rideId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result != null && result['success'] == true) {
        await _fetchData();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request sent successfully'),
            backgroundColor: ConstColor.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'Failed to request ride'),
            backgroundColor: ConstColor.error.withAlpha(150),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      debugPrint('Error requesting ride: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade100,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<RideModel> get _activeRides => _rides.where((r) => r.isOpen).toList();

  List<RideModel> get _inProgressRides =>
      _rides.where((r) => r.status.toLowerCase() == 'in_progress').toList();

  List<RideModel> get _pastRides => _rides
      .where(
        (r) =>
            r.status.toLowerCase() == 'cancelled' ||
            r.status.toLowerCase() == 'completed',
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ConstColor.primaryPurple,
        toolbarHeight: 0.0,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              decoration: BoxDecoration(
                color: ConstColor.primaryPurple.withAlpha(250),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your rides and history',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.grey.shade100,
                    indicatorWeight: 5,
                    dividerColor: Colors.transparent,
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorAnimation: TabIndicatorAnimation.elastic,
                    labelColor: Colors.white,
                    tabAlignment: TabAlignment.center,
                    unselectedLabelColor: Colors.white70,
                    overlayColor: WidgetStateProperty.all(Colors.white12),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    tabs: const [
                      Tab(text: 'Active'),
                      Tab(text: 'Requests'),
                      Tab(text: 'History'),
                    ],
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Active tab
                  // if (_rides.isNotEmpty && _rides.first.status == 'in_progress')
                  //   _buildInProgressRide(_inProgressRides)
                  // else
                  _buildRideList(
                    _activeRides,
                    isActive: true,
                    emptyMsg: 'No active rides',
                  ),

                  // Requests tab
                  _buildRideList(
                    _myRequests,
                    isActive: true,
                    emptyMsg: 'No ride requests made',
                    shortDesc: 'You will see previously made Ride Requests.',
                  ),
                  // History tab
                  _buildRideList(
                    _pastRides,
                    isActive: false,
                    emptyMsg: 'No ride history yet',
                    shortDesc: 'Your ride history will appear here.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideList(
    List<RideModel> rides, {
    required bool isActive,
    String emptyMsg = 'No rides found',
    String? shortDesc = 'Your current journey will appear here.',
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ConstColor.primaryPurple),
      );
    }

    rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (rides.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive
                        ? Icons.directions_car_outlined
                        : Icons.history_outlined,
                    size: 72,
                    color: ConstColor.primaryPurple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyMsg,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ConstColor.primaryColor.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shortDesc!,
                    style: TextStyle(
                      fontSize: 13,
                      color: ConstColor.primaryPurple.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return _RideCard(
            ride: ride,
            isActive: isActive,
            currentUserId: _userService.userId,
            onStart:
                isActive &&
                    ride.isOpen &&
                    ride.initiatorId == _userService.userId &&
                    ride.curPassengers > 0
                ? () async {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(
                          color: ConstColor.primaryPurple,
                        ),
                      ),
                    );

                    try {
                      final result = await _rideService.startRide(ride.rideId);
                      if (!context.mounted) return;
                      Navigator.pop(context); // Close loading

                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ride started successfully!'),
                            backgroundColor: ConstColor.success,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ?? 'Failed to start ride',
                            ),
                            backgroundColor: Colors.red.shade200,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted == false) return;
                      Navigator.pop(context); // Close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error: $e',
                            style: TextStyle(color: Colors.red),
                          ),
                          backgroundColor: Colors.red.shade100,
                        ),
                      );
                    }
                  }
                : null,
            onCancel: isActive && ride.initiatorId == _userService.userId
                ? () => _cancelRide(ride.rideId)
                : null,
            onRefresh: _fetchData,
          );
        },
      ),
    );
  }

  Widget _buildInProgressRide(List<RideModel> rides) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ConstColor.primaryPurple),
      );
    }

    if (rides.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchData,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    size: 72,
                    color: ConstColor.primaryPurple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No rides in progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ConstColor.primaryColor.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your active rides will appear here',
                    style: TextStyle(
                      fontSize: 13,
                      color: ConstColor.primaryPurple.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show the latest in progress ride
    final latestRide = rides.last;
    debugPrint(latestRide.toString());
    if (latestRide.isEmpty == false) {
      return _InProgressRideView(ride: latestRide);
    } else {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 72,
              color: ConstColor.primaryPurple,
            ),
          ],
        ),
      );
    }
  }
}

class _RideCard extends StatelessWidget {
  final RideModel ride;
  final bool isActive;
  final String currentUserId;

  final VoidCallback? onCancel;
  final VoidCallback? onStart;
  final VoidCallback onRefresh;

  const _RideCard({
    required this.ride,
    required this.isActive,
    required this.currentUserId,
    this.onStart,
    this.onCancel,
    required this.onRefresh,
  });

  bool get _isInitiator => ride.initiatorId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: .spaceBetween,
            children: [
              Text(
                'Ride by ${ride.initiatorId == currentUserId ? "You" : ride.initiatorName}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? ConstColor.success.withAlpha(25)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ride.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? ConstColor.success : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          // Route
          const SizedBox(height: 8),
          Row(
            children: [
              // Route icons
              Column(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: ConstColor.primaryPurple,
                  ),
                  Container(
                    width: 2,
                    height: 20,
                    color: ConstColor.primaryPurple.withAlpha(80),
                  ),
                  const Icon(
                    Icons.location_pin,
                    size: 12,
                    color: ConstColor.success,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Route text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.startLocation,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ride.destinationName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // Details row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _detailChip(
                Icons.people_outline,
                '${ride.maxSeats} ${ride.maxSeats > 1 ? 'seats' : 'seat'}',
              ),
              _detailChip(Icons.wc_outlined, ride.preferredGender),
              _detailChip(Icons.access_time, _formatDate(ride.createdAt)),
              if (isActive && _isInitiator)
                _detailChip(Icons.pin, 'OTP: ${ride.tripOtp}'),
            ],
          ),

          if (isActive) ...[
            const SizedBox(height: 16),
            if (ride.isOpen)
              GridView(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      (ride.initiatorId == currentUserId ||
                          !_isInitiator && ride.status == 'in_progress'
                      ? 3
                      : 2),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio:
                      ride.initiatorId == currentUserId ||
                          !_isInitiator && ride.status == 'in_progress'
                      ? 2.5
                      : 4,
                ),
                shrinkWrap: true,

                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ElevatedButton(
                    onPressed: () => _showChatBottomSheet(
                      context,
                      ride.rideId,
                      ride.initiatorName,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Chat',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showRideDetails(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConstColor.primaryPurple25,
                      foregroundColor: ConstColor.primaryPurple,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      _isInitiator ? 'QR Code' : 'Scan QR',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_isInitiator)
                    if (ride.status == ('open'))
                      ElevatedButton(
                        onPressed: ride.curPassengers > 0 ? onStart : onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ride.curPassengers > 0
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          foregroundColor: ride.curPassengers > 0
                              ? ConstColor.success
                              : ConstColor.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          ride.curPassengers > 0 ? 'Start' : 'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          // navigate to map view page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  _InProgressRideView(ride: ride),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: ConstColor.error,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Live',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  if (!_isInitiator && ride.status == 'in_progress')
                    ElevatedButton(
                      onPressed: () {
                        // navigate to map view page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                _InProgressRideView(ride: ride),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade100,
                        foregroundColor: ConstColor.error,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        'Live',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  void _showChatBottomSheet(
    BuildContext context,
    String rideId,
    String rideName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) =>
          RideChatBottomSheet(rideId: rideId, rideName: rideName),
    );
  }

  void _showRideDetails(BuildContext context) {
    if (_isInitiator) {
      // Show QR code for initiator
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ride QR Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: ride.tripQrCode,
                    version: QrVersions.auto,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: ConstColor.primaryPurple,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      color: ConstColor.primaryColor,
                      dataModuleShape: QrDataModuleShape.square,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Trip OTP: ${ride.tripOtp}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ConstColor.primaryPurple,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ask passenger to scan this QR',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConstColor.primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Show QR Scanner for non-initiator
      _showQrScanner(context);
    }
  }

  void _showQrScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Stack(
          children: [
            MobileScanner(
              onDetect: (capture) async {
                final List<Barcode> barcodes = capture.barcodes;
                try {
                  if (barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    debugPrint(code);
                    if (code != null) {
                      _handleJoinByQr(context, code);
                    }
                  }
                } catch (e) {
                  debugPrint("Error QR Scanner: $e");
                } finally {
                  if (!context.mounted) {
                  } else {
                    Navigator.pop(context); // Close scanner
                  }
                }
              },
              placeholderBuilder: (context) {
                return Container(
                  width: 300,
                  height: 300,
                  color: ConstColor.primaryPurple25,
                );
              },
            ),
            Positioned(
              top: 30,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Text(
                'Scan the Ride QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleJoinByQr(BuildContext context, String tripQrCode) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      final location = LocationInfo.cord;
      if (location == null) throw Exception('Location not available');

      final result = await RideService().joinByQr(
        tripQrCode: tripQrCode,
        userId: currentUserId,
        lat: location.latitude,
        lng: location.longitude,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (result['success'] == true) {
        // Show OTP field
        _showOtpDialog(context);
      } else {
        debugPrint(result.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to join ride'),
            backgroundColor: Colors.red.shade100,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: ConstColor.error),
      );
    }
  }

  void _showOtpDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Verify Ride', textAlign: TextAlign.center),
        backgroundColor: ConstColor.primaryBg,
        clipBehavior: Clip.hardEdge,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the OTP shown on the initiator\'s app',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Pinput(
              length: 6,
              controller: pinController,
              defaultPinTheme: PinTheme(
                width: 45,
                height: 45,
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: ConstColor.primaryPurple,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ConstColor.primaryPurple.withAlpha(100),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onCompleted: (pin) async {
                _handleVerifyOtp(context, pin);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(
                  Colors.white.withAlpha(50),
                ),
                backgroundColor: WidgetStateProperty.all(
                  Colors.red.withAlpha(220),
                ),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                elevation: WidgetStateProperty.all(0),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              onPressed: Navigator.of(context).pop,
              child: Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleVerifyOtp(BuildContext context, String otp) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: ConstColor.primaryPurple),
      ),
    );

    try {
      final result = await RideService().verifyRide(
        rideId: ride.rideId,
        userId: currentUserId,
        otp: otp,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      if (result['success'] == true) {
        Navigator.pop(context); // Close OTP dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride verified successfully!'),
            backgroundColor: ConstColor.success,
          ),
        );
        onRefresh(); // Refresh activity to show in progress
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Invalid OTP'),
            backgroundColor: Colors.red.shade100,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade100,
        ),
      );
    }
  }

  Widget _detailChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _InProgressRideView extends StatefulWidget {
  final RideModel ride;

  const _InProgressRideView({required this.ride});

  @override
  State<_InProgressRideView> createState() => _InProgressRideViewState();
}

class _InProgressRideViewState extends State<_InProgressRideView> {
  late DraggableScrollableController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map view
        MapSample(ride: widget.ride),

        // Draggable bottom sheet with ride info
        DraggableScrollableSheet(
          controller: _scrollController,
          initialChildSize: 0.3,
          minChildSize: 0.2,
          maxChildSize: 0.6,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Route info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: ConstColor.error,
                            ),
                            Container(
                              width: 2,
                              height: 32,
                              color: ConstColor.primaryPurple.withAlpha(80),
                            ),
                            const Icon(
                              Icons.location_pin,
                              size: 12,
                              color: ConstColor.success,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.ride.startLocation,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                widget.ride.destinationName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Ride details grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetaItem(
                          icon: Icons.people,
                          label: 'Passengers',
                          value: '${widget.ride.maxSeats}',
                        ),
                        _buildMetaItem(
                          icon: Icons.info_outline,
                          label: 'Status',
                          value: widget.ride.status == 'in_progress'
                              ? 'Going on'
                              : 'Completed',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: .all(20),
      decoration: BoxDecoration(
        color: ConstColor.primaryPurple25.withAlpha(100),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: ConstColor.primaryPurple, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: ConstFonts.normal(size: 11, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ConstFonts.semibold(size: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
