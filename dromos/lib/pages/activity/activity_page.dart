import 'package:dromos/models/ride_model.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  List<RideModel> _rides = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      if (mounted) setState(() => _rides = rides);
    } catch (e) {
      debugPrint('Error fetching rides: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<RideModel> get _activeRides =>
      _rides.where((r) => r.status.toLowerCase() == 'open').toList();

  List<RideModel> get _pastRides =>
      _rides.where((r) => r.status.toLowerCase() != 'open').toList();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Scaffold(
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
                      indicatorColor: Colors.white,
                      indicatorWeight: 5,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Active'),
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
                    // History tab
                    _buildRideList(_pastRides, isActive: false),
                  ],
                ),
              ),
            ],
          ),
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
          return GestureDetector(
            onTap: () => _showQrDialog(context, ride),
            child: _RideCard(ride: ride, isActive: isActive),
          );
        },
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideModel ride;
  final bool isActive;

  const _RideCard({required this.ride, required this.isActive});

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
          if (isActive)
            Row(
              children: [
                Icon(
                  Icons.qr_code_outlined,
                  size: 16,
                  color: ConstColor.primaryPurple.withAlpha(200),
                ),
                SizedBox(width: 10),
                Text('Tap To See QR Code', style: ConstFonts.thin(size: 12)),
              ],
            ),
          SizedBox(height: 10),

          // Route
          Row(
            children: [
              // Route icons
              Column(
                children: [
                  const Icon(Icons.circle, color: ConstColor.error, size: 12),
                  Container(
                    width: 2,
                    height: 28,
                    color: ConstColor.primaryPurple.withAlpha(80),
                  ),
                  const Icon(Icons.flag, size: 14, color: ConstColor.success),
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
                    color: isActive
                        ? ConstColor.success.withGreen(150)
                        : ConstColor.primaryColor.withAlpha(100),
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
              _detailChip(Icons.people_outline, '${ride.maxSeats} seats'),
              _detailChip(Icons.access_time, _formatDate(ride.createdAt)),
              if (isActive) _detailChip(Icons.pin, 'OTP: ${ride.tripOtp}'),
            ],
          ),
        ],
      ),
    );
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

void _showQrDialog(BuildContext context, RideModel ride) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Trip QR Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${ride.startLocation} → ${ride.destinationName}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ConstColor.primaryPurple.withAlpha(40),
                  width: 2,
                ),
              ),
              child: QrImageView(
                data: ride.tripQrCode,
                version: QrVersions.auto,
                size: 200,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.circle,
                  color: ConstColor.primaryColor,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: ConstColor.primaryPurple,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // OTP row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: ConstColor.primaryPurple.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'OTP',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Row(
                    children: [
                      Text(
                        ride.tripOtp,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ConstColor.primaryPurple,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: ride.tripOtp));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('OTP copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.copy,
                          size: 16,
                          color: ConstColor.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ConstColor.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
