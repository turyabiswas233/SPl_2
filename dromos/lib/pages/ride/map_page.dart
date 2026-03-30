import 'package:dromos/models/ride_model.dart';
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
    'Streets': 'mapbox://styles/mapbox/streets-v12',
    'Outdoors': 'mapbox://styles/mapbox/outdoors-v12',
    'Light': 'mapbox://styles/mapbox/light-v11',
    'Dark': 'mapbox://styles/mapbox/dark-v11',
    'Satellite': 'mapbox://styles/mapbox/satellite-v9',
    'Satellite Streets': 'mapbox://styles/mapbox/satellite-streets-v12',
    'Navigation Day': 'mapbox://styles/mapbox/navigation-day-v1',
    'Navigation Night': 'mapbox://styles/mapbox/navigation-night-v1',
  };

  String _currentStyle = _mapStyles['Navigation Day']!;

  MapboxMap? mapboxMap;
  PolylineAnnotationManager? polylineAnnotationManager;

  Future<void> _onMapCreated(MapboxMap map) async {
    try {
      dynamic accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
      if (accessToken.isNotEmpty) {
        MapboxOptions.setAccessToken(accessToken);
      } else {
        debugPrint(
          "Warning: MAPBOX_ACCESS_TOKEN is not set in .env. Map features may not work properly.",
        );
      }
      mapboxMap = map;
      mapboxMap?.compass.updateSettings(CompassSettings(enabled: false));
      mapboxMap?.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

      polylineAnnotationManager = await map.annotations
          .createPolylineAnnotationManager();
      await _drawRoute();
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

  Future<void> _drawRoute() async {
    // your existing route drawing logic
  }

  void _changeStyle(String styleUri) {
    setState(() {
      _currentStyle = styleUri;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Theme buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _mapStyles.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton(
                  onPressed: () => _changeStyle(entry.value),
                  child: Text(entry.key),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              MapWidget(
                key: const ValueKey('mapWidget'),
                styleUri: _currentStyle,
                onMapCreated: _onMapCreated,
                cameraOptions: CameraOptions(
                  center: Point(
                    coordinates: Position(
                      LocationInfo.cord!.longitude,
                      LocationInfo.cord!.latitude,
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
    );
  }
}
