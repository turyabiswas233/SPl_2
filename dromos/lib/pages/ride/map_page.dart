import 'dart:async';
import 'package:dromos/models/ride_model.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;

class MapSample extends StatefulWidget {
  final RideModel? ride;

  const MapSample({super.key, required this.ride});

  @override
  State<MapSample> createState() => _MapSampleState();
}

class _MapSampleState extends State<MapSample> {
  // Inside _MapSampleState
  StreamSubscription<Position>? _positionStream;
  mp.MapboxMap? mapboxMap;
  mp.PolylineAnnotationManager? polylineAnnotationManager;
  mp.PointAnnotationManager? pointAnnotationManager;
  late List<Cord> coordinates = [];
  final LocationInfo _locationInfo = LocationInfo.getInstance();
  late DraggableScrollableController _scrollController;
  late double distance = 0;
  late double duration = 0;

  Future<void> _onMapCreated(mp.MapboxMap map) async {
    try {
      // Ensure dotenv is loaded
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: '.env.local');
      }

      String? accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
      if (accessToken != null && accessToken.isNotEmpty) {
        mp.MapboxOptions.setAccessToken(accessToken);
      } else {
        debugPrint(
          "Warning: MAPBOX_ACCESS_TOKEN is missing or empty in .env.local",
        );
      }

      await LocationInfo.resolveCurrentCity(LocationAccuracy.bestForNavigation);

      mapboxMap = map;
      pointAnnotationManager = await map.annotations
          .createPointAnnotationManager();
      mapboxMap?.compass.updateSettings(mp.CompassSettings(enabled: false));
      mapboxMap?.scaleBar.updateSettings(mp.ScaleBarSettings(enabled: false));
      mapboxMap?.annotations.createCircleAnnotationManager();
      mapboxMap?.location.updateSettings(
        mp.LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          accuracyRingColor: ConstColor.primaryPurple.toARGB32(),
          accuracyRingBorderColor: ConstColor.primaryPurple.toARGB32(),
          puckBearingEnabled: true,
          pulsingColor: ConstColor.primaryPurple.toARGB32(),
          pulsingMaxRadius: 10,
        ),
      );

      polylineAnnotationManager = await map.annotations
          .createPolylineAnnotationManager();

      if (widget.ride != null) {
        await _drawRoute();
      }
    } catch (e) {
      debugPrint("Map creation error: $e");
    }
  }

  Future<void> _drawRoute() async {
    if (widget.ride == null) return;
    try {
      await LocationInfo.resolveCurrentCity(LocationAccuracy.bestForNavigation);
      RideService rideService = RideService();
      dynamic routes = await rideService.getRoute(
        startLng: _locationInfo.getLocation()!.longitude,
        startLat: _locationInfo.getLocation()!.latitude,
        destLng: widget.ride!.destLng,
        destLat: widget.ride!.destLat,
      );

      // 1. Clear previous annotations
      await polylineAnnotationManager!.deleteAll();

      List c = routes['coordinates'] as List;
      debugPrint("DISTANCE_TB ${routes['distance']}");
      debugPrint("duration ${routes['duration']}");

      coordinates = c
          .map((c) => Cord(longitude: c['longitude'], latitude: c['latitude']))
          .toList();

      // Convert to mapbox Position list
      List<mp.Position> positions = coordinates
          .map((cord) => mp.Position(cord.longitude, cord.latitude))
          .toList();

      // Draw polyline
      if (polylineAnnotationManager != null) {
        await polylineAnnotationManager!.create(
          mp.PolylineAnnotationOptions(
            geometry: mp.LineString(coordinates: positions),
            lineColor: ConstColor.primaryPurple25.toARGB32(),
            lineWidth: 5.0,
            lineJoin: mp.LineJoin.ROUND,
          ),
        );
      }
      setState(() {
        distance = double.parse(routes['distance'].toString());
        duration = double.parse(routes['duration'].toString());
      });
    } catch (e) {
      debugPrint("Draw route error: $e");
    }
  }

  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Update only if the user moves 10 meters
      timeLimit: Duration(seconds: 5), // setting a time limit to 5s.
    );

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          // Update your local singleton/model
          _locationInfo.updateLocation(position);

          // Refresh the map route
          _drawRoute();

          // Optional: Smoothly move the camera to follow the user
          mapboxMap?.flyTo(
            mp.CameraOptions(
              center: mp.Point(
                coordinates: mp.Position(position.longitude, position.latitude),
              ),
            ),
            mp.MapAnimationOptions(duration: 500),
          );
        });
  }

  String _formateToDurationTime(double durationInSeconds) {
    int hours = durationInSeconds ~/ 3600;
    int minutes = durationInSeconds ~/ 60 - hours * 60;
    return '${hours.toString().padLeft(2, '0')}h:${minutes.toString().padLeft(2, '0')}m';
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
            style: ConstFonts.semibold(
              color: ConstColor.primaryColor,
              size: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: ConstFonts.semibold(
              color: ConstColor.primaryColor,
              size: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDistance(double d) {
    if (d < 1000) {
      return '${d.toStringAsFixed(1)} m';
    } else {
      return '${(d / 1000).toStringAsFixed(1)} km';
    }
  }

  void _centerMap() {
    if (mapboxMap != null) {
      mapboxMap!.flyTo(
        mp.CameraOptions(
          center: mp.Point(
            coordinates: mp.Position(
              _locationInfo.getLocation()!.longitude,
              _locationInfo.getLocation()!.latitude,
            ),
          ),
          zoom: 16,
          pitch: 0,
          bearing: 0,
        ),
        mp.MapAnimationOptions(duration: 2500),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController = DraggableScrollableController();
    _startLocationTracking(); // Start listening when the widget loads
  }

  @override
  void dispose() {
    _positionStream!.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ConstColor.primaryPurple,
        toolbarHeight: 0.0,
        title: const Text('Live Map', style: TextStyle(color: Colors.white)),
        bottomOpacity: 0,
        elevation: 0,
        leading: BackButton(
          color: ConstColor.primaryPurple,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: ConstColor.primaryPurple,
      body: Stack(
        children: [
          Expanded(
            child: Stack(
              children: [
                mp.MapWidget(
                  key: const ValueKey('mapWidget'),
                  styleUri: mp.MapboxStyles.DARK,
                  textureView: false,
                  onMapCreated: _onMapCreated,
                  onScrollListener: (position) {
                    debugPrint(position.toString());
                  },
                  cameraOptions: mp.CameraOptions(
                    center: mp.Point(
                      coordinates: mp.Position(
                        _locationInfo.getLocation()!.longitude,
                        _locationInfo.getLocation()!.latitude,
                      ),
                    ),
                    zoom: 16,
                    pitch: 0,
                    bearing: 0,
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: IgnorePointer(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withAlpha(210),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Draggable bottom sheet with ride info
          DraggableScrollableSheet(
            controller: _scrollController,
            initialChildSize: 0.2,
            minChildSize: 0.18,
            maxChildSize: 0.7,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: ConstColor.primaryBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: ConstColor.primaryPurple,
                    blurRadius: 40,
                    spreadRadius: 10,
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
                          width: 30,
                          height: 2,
                          decoration: BoxDecoration(
                            color: ConstColor.primaryPurple.withAlpha(200),
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
                                color: ConstColor.primaryPurple25,
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
                                  widget.ride!.startLocation,
                                  style: ConstFonts.semibold(
                                    color: ConstColor.primaryColor,
                                    size: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  widget.ride!.destinationName,
                                  style: ConstFonts.semibold(
                                    color: ConstColor.primaryColor,
                                    size: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _centerMap();
                            },
                            icon: Icon(Icons.my_location),
                            color: ConstColor.primaryPurple,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                ConstColor.primaryPurple25.withAlpha(100),
                              ),
                              overlayColor: WidgetStateProperty.all(
                                ConstColor.primaryPurple.withAlpha(20),
                              ),
                              foregroundColor: WidgetStateProperty.all(
                                ConstColor.primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Ride details grid
                      Center(
                        child: Wrap(
                          direction: .horizontal,
                          alignment: .start,
                          runSpacing: 10,
                          spacing: 10,
                          children: [
                            _buildMetaItem(
                              icon: Icons.directions_car_rounded,
                              label: 'Distance',
                              value: _formatDistance(distance),
                            ),
                            _buildMetaItem(
                              icon: Icons.people,
                              label: 'Passengers',
                              value: '${widget.ride!.maxSeats}',
                            ),
                            _buildMetaItem(
                              icon: Icons.info_outline,
                              label: 'Status',
                              value: widget.ride!.status == 'in_progress'
                                  ? 'Going on'
                                  : 'Completed',
                            ),
                            _buildMetaItem(
                              icon: Icons.timer,
                              label: 'Estimated Time',
                              value: _formateToDurationTime(duration),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      floatingActionButtonLocation: .miniEndTop,
    );
  }
}
