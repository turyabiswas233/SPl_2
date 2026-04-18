import 'package:dromos/models/ride_model.dart';
import 'package:dromos/pages/ride/place_search_page.dart';
import 'package:dromos/screens/waiting_screen.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class CreateRidePage extends StatefulWidget {
  const CreateRidePage({super.key, this.onRideCreated});

  final VoidCallback? onRideCreated;

  @override
  State<CreateRidePage> createState() => _CreateRidePageState();
}

class _CreateRidePageState extends State<CreateRidePage> {
  // Location state
  PlaceResult? _startPlace;
  PlaceResult? _destPlace;
  bool _useMyLocation = true;
  bool _isLoadingMyLocation = false;

  // Seats
  int _maxSeats = 1;

  // Preferred Gender
  String _preferredGender = 'other';

  // Submission
  bool _isCreating = false;

  final _rideService = RideService();

  @override
  void initState() {
    super.initState();
    // Auto-fetch current location as default start
    if (LocationInfo.isResolved) {
      _fetchMyLocation();
    } else {
      if (!mounted) return;
      setState(() {
        final loc = LocationInfo.getInstance();
        _startPlace = PlaceResult(
          name: [
            loc.getName(),
            loc.getSubLocality(),
            loc.getLocality(),
          ].where((e) => e != null && e.isNotEmpty).join(', '),
          address: loc.getLocality() ?? '',
          lat: loc.getLocation()?.latitude ?? 0,
          lng: loc.getLocation()?.longitude ?? 0,
        );
        _useMyLocation = true;
      });
    }
  }

  Future<void> _fetchMyLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingMyLocation = true);
    try {
      await LocationInfo.resolveCurrentCity(LocationAccuracy.best);
      final loc = LocationInfo.getInstance();
      if (!mounted) return;
      setState(() {
        _startPlace = PlaceResult(
          name: [
            loc.getName(),
            loc.getSubLocality(),
            loc.getLocality(),
          ].where((e) => e != null && e.isNotEmpty).join(', '),
          address: loc.getLocality() ?? '',
          lat: loc.getLocation()!.latitude,
          lng: loc.getLocation()!.longitude,
        );
        _useMyLocation = true;
      });
    } catch (e) {
      debugPrint('Error fetching location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not detect your location')),
        );
      }
      setState(() {
        _useMyLocation = false;
      });
    } finally {
      if (mounted) setState(() => _isLoadingMyLocation = false);
    }
  }

  Future<void> _openStartSearch() async {
    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PlaceSearchPage(hintText: 'Search pickup location...'),
      ),
    );
    if (result != null) {
      setState(() {
        _startPlace = result;
        _useMyLocation = false;
      });
    } else {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: Colors.white,
            clipBehavior: Clip.antiAlias,
            shadowColor: Colors.black45,
            content: const Text("Wrong Place Location"),
            actions: [
              TextButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    ConstColor.error.withAlpha(100),
                  ),
                  overlayColor: WidgetStateProperty.all(
                    ConstColor.primaryColor.withAlpha(20),
                  ),
                  foregroundColor: WidgetStateProperty.all(ConstColor.error),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _openDestSearch() async {
    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const PlaceSearchPage(hintText: 'Search destination...'),
      ),
    );
    if (result != null) {
      if (!mounted) return;
      setState(() => _destPlace = result);
    }
  }

  Future<void> _createRide() async {
    if (_startPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location')),
      );
      return;
    }
    if (_destPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }

    try {
      if (!mounted) return;
      setState(() => _isCreating = true);
      final ride = await _rideService.createRide(
        startLocation: _startPlace!.name,
        startLat: _startPlace!.lat,
        startLng: _startPlace!.lng,
        destination: _destPlace!.name,
        preferredGender: _preferredGender,
        destLat: _destPlace!.lat,
        destLng: _destPlace!.lng,
        maxSeats: _maxSeats,
      );

      if (!mounted) return;

      _showSuccessDialog(ride);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(color: ConstColor.error),
            ),
            backgroundColor: Colors.red.shade100,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 60),
            showCloseIcon: true,
            closeIconColor: ConstColor.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showSuccessDialog(RideModel ride) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ConstColor.success.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: ConstColor.success,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ride Created!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${ride.startLocation} → ${ride.destinationName}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // OTP & QR section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ConstColor.primaryPurple.withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trip OTP',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          Text(
                            ride.tripOtp,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ConstColor.primaryPurple,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: ride.tripOtp),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OTP copied!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Max Seats',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${ride.maxSeats}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ConstColor.success.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          ride.status.toUpperCase(),
                          style: const TextStyle(
                            color: ConstColor.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
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
                onPressed: () {
                  Navigator.pop(ctx);
                  _resetForm();
                  widget.onRideCreated?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ConstColor.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Done', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _destPlace = null;
        _maxSeats = 1;
        _preferredGender = 'other';
        _useMyLocation = true;
      });
      _fetchMyLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _isCreating || _isLoadingMyLocation;

    return PopScope(
      canPop: !isBusy,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: ConstColor.primaryPurple,
          toolbarHeight: .minPositive,
        ),
        backgroundColor: ConstColor.primaryBg,
        body: isBusy
            ? const WaitingOverlay(captionText: "Setting up your ride")
            : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                        decoration: BoxDecoration(
                          color: ConstColor.primaryPurple,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Create a Ride',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Set your route and invite passengers',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── FROM section ──
                            const Text(
                              'FROM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // My Location toggle
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // My Location option
                                  InkWell(
                                    onTap: () {
                                      setState(() => _useMyLocation = true);
                                      _fetchMyLocation();
                                    },
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _useMyLocation
                                                  ? ConstColor.primaryPurple
                                                        .withAlpha(20)
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.my_location,
                                              color: _useMyLocation
                                                  ? ConstColor.primaryPurple
                                                  : Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'My Location',
                                                  style: ConstFonts.semibold(
                                                    size: 12,
                                                    color: ConstColor
                                                        .primaryColor
                                                        .withAlpha(
                                                          _useMyLocation
                                                              ? 255
                                                              : 100,
                                                        ),
                                                  ),
                                                ),
                                                if (_useMyLocation &&
                                                    _startPlace != null)
                                                  Text(
                                                    _startPlace!.name,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                if (_useMyLocation &&
                                                    _isLoadingMyLocation)
                                                  const Text(
                                                    'Detecting...',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: ConstColor
                                                          .primaryPurple,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            _useMyLocation
                                                ? Icons.check_circle_rounded
                                                : Icons.check_circle_outline,
                                            color: _useMyLocation
                                                ? ConstColor.primaryPurple
                                                : ConstColor.primaryPurple25,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  Divider(
                                    height: 1,
                                    indent: 68,
                                    color: Colors.grey.shade200,
                                  ),

                                  // Search option
                                  InkWell(
                                    onTap: _openStartSearch,
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: !_useMyLocation
                                                  ? ConstColor.primaryPurple
                                                        .withAlpha(20)
                                                  : Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.search,
                                              color: !_useMyLocation
                                                  ? ConstColor.primaryPurple
                                                  : Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Search Location',
                                                  style: ConstFonts.semibold(
                                                    color: ConstColor
                                                        .primaryColor
                                                        .withAlpha(
                                                          !_useMyLocation
                                                              ? 255
                                                              : 100,
                                                        ),
                                                    size: 12,
                                                  ),
                                                ),
                                                if (!_useMyLocation &&
                                                    _startPlace != null)
                                                  Text(
                                                    _startPlace!.name,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  )
                                                else if (!_useMyLocation)
                                                  Text(
                                                    'Tap to search',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade400,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            !_useMyLocation
                                                ? Icons.check_circle_rounded
                                                : Icons.check_circle_outline,
                                            color: !_useMyLocation
                                                ? ConstColor.primaryPurple
                                                : ConstColor.primaryPurple25,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Route connector decoration
                            Row(
                              children: [
                                const SizedBox(width: 36),
                                Column(
                                  children: List.generate(
                                    3,
                                    (_) => Container(
                                      width: 3,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: ConstColor.primaryPurple
                                            .withAlpha(80),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            // ── TO section ──
                            const Text(
                              'TO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            InkWell(
                              onTap: _openDestSearch,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _destPlace != null
                                            ? ConstColor.success.withAlpha(20)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.flag_outlined,
                                        color: _destPlace != null
                                            ? ConstColor.success
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _destPlace != null
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _destPlace!.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                Text(
                                                  _destPlace!.address,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              'Search destination...',
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── PREFERRED GENDER ──
                            const Text(
                              'PREFERRED GENDER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _preferredGender,
                                  dropdownColor: Colors.white,
                                  style: ConstFonts.semibold(
                                    color: ConstColor.primaryColor,
                                    size: 12,
                                  ),
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: 'male',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: ConstColor.primaryPurple,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text('Male'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'female',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: ConstColor.primaryPurple,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text('Female'),
                                        ],
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'other',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.group,
                                            color: ConstColor.primaryPurple,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          const Text('Both'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _preferredGender = value);
                                    }
                                  },
                                  iconEnabledColor: ConstColor.primaryPurple,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),
                            const Text(
                              'MAX SEATS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(12),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        color: ConstColor.primaryPurple,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Passengers',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      _seatButton(
                                        icon: Icons.remove,
                                        onTap: _maxSeats > 1
                                            ? () => setState(() => _maxSeats--)
                                            : null,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          '$_maxSeats',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: ConstColor.primaryPurple,
                                          ),
                                        ),
                                      ),
                                      _seatButton(
                                        icon: Icons.add,
                                        onTap: _maxSeats < 10
                                            ? () => setState(() => _maxSeats++)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // ── CREATE BUTTON ──
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isCreating ? null : _createRide,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ConstColor.primaryPurple,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: ConstColor
                                      .primaryPurple
                                      .withAlpha(120),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isCreating
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.directions_car, size: 22),
                                          SizedBox(width: 10),
                                          Text(
                                            'Create Ride',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _seatButton({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled
              ? ConstColor.primaryPurple.withAlpha(20)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? ConstColor.primaryPurple : Colors.grey.shade400,
        ),
      ),
    );
  }
}
