import 'package:dromos/models/ride_model.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapSample extends StatefulWidget {
  final RideModel? ride;

  const MapSample({super.key, required this.ride});

  @override
  State<MapSample> createState() => _MapSampleState();
}

class _MapSampleState extends State<MapSample> {
  MapboxMap? mapboxMap;
  PolylineAnnotationManager? polylineAnnotationManager;
  PointAnnotationManager? pointAnnotationManager;
  late List<Cord> coordinates = [];
  final LocationInfo _locationInfo = LocationInfo.getInstance();

  Future<void> _onMapCreated(MapboxMap map) async {
    try {
      // Ensure dotenv is loaded
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: '.env.local');
      }

      String? accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
      if (accessToken != null && accessToken.isNotEmpty) {
        MapboxOptions.setAccessToken(accessToken);
      } else {
        debugPrint(
          "Warning: MAPBOX_ACCESS_TOKEN is missing or empty in .env.local",
        );
      }

      mapboxMap = map;
      pointAnnotationManager = await map.annotations.createPointAnnotationManager();
      mapboxMap?.compass.updateSettings(CompassSettings(enabled: false));
      mapboxMap?.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
      mapboxMap?.annotations.createCircleAnnotationManager();
      mapboxMap?.location.updateSettings(
        LocationComponentSettings(
            enabled: true,
            pulsingEnabled: true,
            accuracyRingColor: ConstColor.primaryPurple.toARGB32(),
            accuracyRingBorderColor: ConstColor.primaryPurple.toARGB32(),
            puckBearingEnabled: true,
            pulsingColor: ConstColor.primaryPurple.toARGB32(),
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
      RideService rideService = RideService();
      dynamic routes = await rideService.getRoute(
        startLng: widget.ride!.startLng,
        startLat: widget.ride!.startLat,
        destLng: widget.ride!.destLng,
        destLat: widget.ride!.destLat,
      );

      List c = routes['coordinates'] as List;

      coordinates = c
          .map((c) => Cord(longitude: c['longitude'], latitude: c['latitude']))
          .toList();

      // Convert to mapbox Position list
      List<Position> positions = coordinates
          .map((cord) => Position(cord.longitude, cord.latitude))
          .toList();

      // Draw polyline
      if (polylineAnnotationManager != null) {
        await polylineAnnotationManager!.create(
          PolylineAnnotationOptions(
            geometry: LineString(coordinates: positions),
            lineColor: ConstColor.primaryPurple.toARGB32(),
            lineWidth: 4.0,
          ),
        );
      }
      // Add start and end markers
      if (pointAnnotationManager != null) {
        // Clear old markers if needed
        await pointAnnotationManager!.deleteAll();

        // Load custom icon from assets
        final ByteData startIcon = await rootBundle.load("assets/icons/start.png");
        final ByteData endIcon = await rootBundle.load("assets/icons/end.png");

        // Create start marker
        await pointAnnotationManager!.create(PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(widget.ride!.startLng, widget.ride!.startLat),
          ),
          image: startIcon.buffer.asUint8List(),
          iconSize: 1.0,
        ));

        // Create end marker
        await pointAnnotationManager!.create(PointAnnotationOptions(
          geometry: Point(
            coordinates: Position(widget.ride!.destLng, widget.ride!.destLat),
          ),
          image: endIcon.buffer.asUint8List(),
          iconSize: 1.0,
        ));
      }
    } catch (e) {
      debugPrint("Draw route error: $e");
    }
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
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MapWidget(
                  key: const ValueKey('mapWidget'),
                  styleUri: MapboxStyles.DARK,
                  onMapCreated: _onMapCreated,
                  onScrollListener: (position) {
                    debugPrint(position.toString());
                  },
                  cameraOptions: CameraOptions(
                    center: Point(
                      coordinates: Position(
                        _locationInfo.getLocation()!.longitude,
                        _locationInfo.getLocation()!.latitude,
                      ),
                    ),
                    zoom: 14,
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
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          LocationInfo.resolveCurrentCity();
          await _drawRoute();
        },
        foregroundColor: ConstColor.primaryPurple,
        splashColor: ConstColor.primaryPurple25,
        child: Icon(Icons.refresh_rounded),
      ),
      floatingActionButtonLocation: .miniEndTop,
    );
  }
}
