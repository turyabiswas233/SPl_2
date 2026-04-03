import 'package:dromos/models/ride_model.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/utils/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapSample extends StatefulWidget {
  final RideModel? ride;

  const MapSample({super.key, required this.ride});

  @override
  State<MapSample> createState() => _MapSampleState();
}

class _MapSampleState extends State<MapSample> {
  static const Map<String, String> _mapStyles = {
    'Light': 'mapbox://styles/mapbox/light-v11',
    'Dark': 'mapbox://styles/mapbox/dark-v11',
  };

  String _currentStyle = _mapStyles['Light']!;

  MapboxMap? mapboxMap;
  PolylineAnnotationManager? polylineAnnotationManager;

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
      mapboxMap?.compass.updateSettings(CompassSettings(enabled: false));
      mapboxMap?.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

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
      debugPrint(routes['routes'][0].toString());
    } catch (e) {
      debugPrint("Draw route error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    // Determine camera center safely
    final Point cameraCenter = widget.ride != null
        ? Point(
            coordinates: Position(widget.ride!.startLng, widget.ride!.startLat),
          )
        : Point(coordinates: Position(0.0, 0.0)); // Fallback center

    return Column(
      children: [
          Expanded(
          child: Stack(
            children: [
              MapWidget(
                key: const ValueKey('mapWidget'),
                styleUri: _currentStyle,
                onMapCreated: _onMapCreated,
                onScrollListener: (position) {
                  debugPrint(position.toString());
                },
                cameraOptions: CameraOptions(
                  center: cameraCenter,
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
    );
  }
}
