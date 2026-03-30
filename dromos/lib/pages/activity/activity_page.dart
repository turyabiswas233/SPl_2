import 'package:dromos/models/ride_model.dart';
import 'package:dromos/pages/ride/map_page.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/widgets/ride_chat_bottom_sheet.dart';
import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchRides();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchRides() async {
    setState(() => _isLoading = true);
    try {
      final rides = await _rideService.fetchMyRides();
      if (mounted) {
        setState(() => _rides = rides);
      }
    } catch (e) {
      debugPrint('Error fetching rides: $e');
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
      barrierColor: Color(0x88323244),
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
              overlayColor: WidgetStateProperty.all(Colors.red.withAlpha(50)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
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
        await _fetchRides();

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
            backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
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
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  List<RideModel> get _activeRides =>
      _rides.where((r) => r.status.toLowerCase() == 'open').toList();

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
        toolbarHeight: .minPositive,
      ),
      backgroundColor: ConstColor.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              decoration: BoxDecoration(
                color: ConstColor.primaryPurple,
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
                  const SizedBox(height: 16),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white70,
                    indicatorWeight: 5,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    overlayColor: WidgetStateProperty.all(Colors.white12),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    tabs: const [
                      Tab(text: 'Active'),
                      Tab(text: 'In Progress'),
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
                  _buildRideList(_activeRides, isActive: true),
                  // In Progress tab
                  _buildInProgressRide(_inProgressRides),
                  // History tab
                  _buildRideList(_pastRides, isActive: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideList(List<RideModel> rides, {required bool isActive}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: ConstColor.primaryPurple),
      );
    }

    rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (rides.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchRides,
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
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isActive ? 'No active rides' : 'No ride history yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isActive
                        ? 'Create a ride to get started!'
                        : 'Your completed rides will appear here',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchRides,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (context, index) {
          final ride = rides[index];
          return _RideCard(
            ride: ride,
            isActive: isActive,
            currentUserId: _userService.userId,
            onCancel: isActive && ride.initiatorId == _userService.userId
                ? () => _cancelRide(ride.rideId)
                : null,
            onRequest: isActive && ride.initiatorId != _userService.userId
                ? () => _requestRide(ride.rideId)
                : null,
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
        onRefresh: _fetchRides,
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
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No rides in progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your active rides will appear here',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
    return _InProgressRideView(ride: latestRide);
  }
}

class _RideCard extends StatelessWidget {
  final RideModel ride;
  final bool isActive;
  final String currentUserId;
  final VoidCallback? onCancel;
  final VoidCallback? onRequest;

  const _RideCard({
    required this.ride,
    required this.isActive,
    required this.currentUserId,
    this.onCancel,
    this.onRequest,
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
          // Route
          Text('Ride by ${ride.initiatorId == currentUserId ? "You" : ride.initiatorName}'),
          Row(
            children: [
              // Route icons
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: ConstColor.primaryPurple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 28,
                    color: ConstColor.primaryPurple.withAlpha(80),
                  ),
                  const Icon(Icons.flag, size: 14, color: Colors.red),
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
              if (isActive) _detailChip(Icons.pin, 'OTP: ${ride.tripOtp}'),
            ],
          ),

          // Cancel button for active rides (only if user is initiator)
          if (isActive && _isInitiator && onCancel != null) ...[
            const SizedBox(height: 16),
            GridView(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.5,
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                  ),
                  child: const Text(
                    'Chat',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showRideDetails(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade50,
                    foregroundColor: ConstColor.primaryPurple,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                  ),
                  child: const Text(
                    'QR Code',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
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
    if (_isInitiator && ride.tripQrCode.isNotEmpty) {
      // Show QR code
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
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
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: QrImageView(
                    data: ride.tripQrCode,
                    version: QrVersions.auto,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: ConstColor.primaryPurple,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      color: ConstColor.primaryColor,
                      dataModuleShape: QrDataModuleShape.square,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Trip OTP: ${ride.tripOtp}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ConstColor.primaryPurple,
                  ),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
    } else if (!_isInitiator && onRequest != null) {
      // Show request ride confirmation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request Ride?'),
          content: const Text('Do you want to request to join this ride?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onRequest?.call();
              },
              child: const Text(
                'Request',
                style: TextStyle(color: ConstColor.primaryPurple),
              ),
            ),
          ],
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
    debugPrint('Formatting date: $dt');
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
          initialChildSize: 0.25,
          minChildSize: 0.15,
          maxChildSize: 0.6,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: ConstColor.primaryPurple,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 20,
                              color: ConstColor.primaryPurple.withAlpha(80),
                            ),
                            const Icon(Icons.flag, size: 12, color: Colors.red),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetaItem(
                          icon: Icons.people,
                          label: 'Passengers',
                          value: '${widget.ride.maxSeats}',
                        ),
                        _buildMetaItem(
                          icon: Icons.lock_clock,
                          label: 'OTP',
                          value: widget.ride.tripOtp,
                        ),
                        _buildMetaItem(
                          icon: Icons.info_outline,
                          label: 'Status',
                          value: widget.ride.status.toUpperCase(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Call ride completion or additional action
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Complete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ConstColor.success,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _showChatBottomSheet(
                                    context,
                                    widget.ride.rideId,
                                    widget.ride.initiatorName,
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Chat'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Call emergency or support
                            },
                            icon: const Icon(Icons.call),
                            label: const Text('Contact Host'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
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
    return Column(
      children: [
        Icon(icon, color: ConstColor.primaryPurple, size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
}
