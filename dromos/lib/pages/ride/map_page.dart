import 'dart:async';
import 'dart:developer';
import 'package:dromos/screens/waiting_screen.dart';
import 'package:dromos/utils/location.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => _MapSampleState();
}

class _MapSampleState extends State<MapSample> {
  bool _isLoadingMap = true;
  String? _errorMessage;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  CameraPosition get _initialCameraPosition {
    final cord = LocationInfo.cord;
    if (cord != null) {
      return CameraPosition(
        target: LatLng(cord.latitude, cord.longitude),
        zoom: 14.4746,
      );
    }
    return const CameraPosition(target: LatLng(0, 0), zoom: 2);
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      // If location is already resolved, skip fetching
      if (LocationInfo.cord == null) {
        await LocationInfo.resolveCurrentCity();
      }
      log('Location resolved: ${LocationInfo.cord}');
    } catch (e) {
      log('Failed to resolve location: $e');
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingMap = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMap) {
      return const WaitingOverlay(captionText: "Loading map...");
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Could not fetch location',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoadingMap = true;
                      _errorMessage = null;
                    });
                    _initLocation();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialCameraPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,

        zoomControlsEnabled: false,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    LocationInfo.resolveCurrentCity().catchError((e) {
      log('Failed to resolve location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching location: $e')));
      }
    });
    final cord = LocationInfo.cord;
    if (cord == null) {
      log('Location is null, cannot move camera');
      return;
    }

    final GoogleMapController controller = await _controller.future;
    final position = CameraPosition(
      target: LatLng(cord.latitude, cord.longitude),
      zoom: 16,
    );
    await controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }
}
