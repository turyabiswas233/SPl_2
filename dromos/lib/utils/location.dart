import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationInfo {
  String? locality;
  String? subLocality;
  double latitude;
  double longitude;

  LocationInfo({
    required this.locality,
    required this.subLocality,
    required this.latitude,
    required this.longitude,
  });  

  @override
  String toString() {
    return 'LocationInfo{locality: $locality, subLocality: $subLocality, latitude: $latitude, longitude: $longitude}';
  }

  static Future<LocationInfo> resolveCurrentCity() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      } else if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 5),
        distanceFilter: 5,
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty || placemarks.first.locality == null) {
      throw Exception('Unable to resolve current city');
    }
    debugPrint('Resolved location: ${placemarks.first}');
    LocationInfo currentLocation = LocationInfo(
      locality: placemarks.first.locality,
      subLocality: placemarks.first.name,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    return currentLocation;
  }
}
