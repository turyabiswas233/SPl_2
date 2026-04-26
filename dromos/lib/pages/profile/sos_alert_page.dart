import 'package:dromos/components/custom_input.dart';
import 'package:dromos/models/ride_model.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/location.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SosAlertPage extends StatefulWidget {
  const SosAlertPage({super.key, required this.ride});

  final RideModel ride;

  @override
  State<SosAlertPage> createState() => _SosAlertPageState();
}

class _SosAlertPageState extends State<SosAlertPage> {
  final _formKey = GlobalKey<FormState>();
  final _rideService = RideService();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  bool _isSubmitting = false;
  bool _isResolvingLocation = false;
  String? _selectedAlertType;

  static const List<String> _alertTypes = [
    'Emergency',
    'Medical',
    'Accident',
    'Security',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedAlertType = _alertTypes[0];
    _resolveCurrentLocation();
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _resolveCurrentLocation() async {
    setState(() => _isResolvingLocation = true);
    try {
      await LocationInfo.resolveCurrentCity(LocationAccuracy.high);
      final current = LocationInfo.getInstance().getLocation();
      if (current != null) {
        _latitudeController.text = current.latitude.toStringAsFixed(6);
        _longitudeController.text = current.longitude.toStringAsFixed(6);
      }
    } catch (e) {
      debugPrint('SosAlertPage.resolveCurrentLocation error: $e');
    } finally {
      if (mounted) {
        setState(() => _isResolvingLocation = false);
      }
    }
  }

  Future<void> _submitAlert() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAlertType == null) {
      _showSnackbar('Please select an alert type');
      return;
    }

    final rideId = widget.ride.rideId;
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    if (latitude == null || longitude == null) {
      _showSnackbar('Please enter valid coordinates');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final response = await _rideService.createSosAlert(
        rideId: rideId,
        alertType: _selectedAlertType!.toLowerCase(),
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      final message = response['message'] ?? 'SOS alert sent successfully';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: ConstColor.primaryPurple,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      _showSnackbar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade400
            : ConstColor.primaryPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Alert'),
        backgroundColor: ConstColor.primaryPurple,
      ),
      backgroundColor: ConstColor.primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Send SOS alert for your current ride.',
                  style: ConstFonts.normal(
                    size: 16,
                    color: ConstColor.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: ConstColor.primaryPurple.withAlpha(20),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride ID: ${widget.ride.rideId}',
                        style: ConstFonts.semibold(
                          size: 14,
                          color: ConstColor.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.ride.startLocation} → ${widget.ride.destinationName}',
                        style: ConstFonts.normal(
                          size: 14,
                          color: ConstColor.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: ${widget.ride.status.replaceAll('_', ' ')}',
                        style: ConstFonts.normal(
                          size: 12,
                          color: ConstColor.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _alertTypes[0],
                  items: _alertTypes
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedAlertType = value ?? _alertTypes[0]),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an alert type';
                    }
                    return null;
                  },
                  iconEnabledColor: ConstColor.primaryPurple,
                  dropdownColor: ConstColor.primaryBg,
                  style: ConstFonts.normal(
                    size: 14,
                    color: ConstColor.primaryColor,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Alert Type',
                    labelStyle: ConstFonts.normal(
                      size: 14,
                      color: ConstColor.primaryColor,
                    ),
                    prefixIcon: Icon(Icons.notifications_active, color: ConstColor.primaryPurple),
                    filled: true,
                    fillColor: ConstColor.primaryPurple.withAlpha(10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99.0),
                      borderSide: BorderSide(color: ConstColor.primaryPurple.withAlpha(50), width: 1.5)
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomInput(
                        title: 'Latitude',
                        hint: 'Lat',
                        enabled: false,
                        icon: Icons.location_on_outlined,
                        initialValue: '',
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Latitude required';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null) {
                            return 'Invalid latitude';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomInput(
                        title: 'Longitude',
                        hint: 'Lng',
                        enabled: false,
                        icon: Icons.location_on_outlined,
                        initialValue: '',
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Longitude required';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null) {
                            return 'Invalid longitude';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isResolvingLocation
                      ? null
                      : _resolveCurrentLocation,
                  icon: _isResolvingLocation
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_outlined, color: Colors.white, size: 16),
                  label: Text(
                    _isResolvingLocation
                        ? 'Detecting location...'
                        : 'Refresh current location',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ConstColor.secondaryColor,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ConstColor.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConstColor.primaryPurple,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Send SOS Alert',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
