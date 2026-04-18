import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Cord {
  final double latitude;
  final double longitude;

  const Cord({required this.latitude, required this.longitude});

  @override
  String toString() {
    return '{Cord: {lat: $latitude, lng: $longitude}}';
  }
}

class LocationInfo {
  static String? name;
  static String? locality;
  static String? subLocality;
  static String? isoCode;
  static Cord? cord;

  // Private constructor — not meant to be instantiated
  LocationInfo._();

  /// Singleton accessor (kept for backward compatibility)
  static final LocationInfo _instance = LocationInfo._();

  static LocationInfo getInstance() => _instance;

  String? getName() => name;

  String? getLocality() => locality;

  String? getSubLocality() => subLocality;

  String? getIsoCode() => isoCode;

  Cord? getLocation() => cord;

  /// Returns true if location has already been resolved.
  static bool get isResolved => cord != null;

  @override
  String toString() {
    return 'LocationInfo{name: $name, locality: $locality, subLocality: $subLocality, $cord}';
  }

  static Future<void> resolveCurrentCity(LocationAccuracy? locAcu) async {
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
      locationSettings: LocationSettings(
        accuracy: locAcu ?? LocationAccuracy.high,
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isEmpty || placemarks.first.locality == null) {
      throw Exception('Unable to resolve current city');
    }
    var place = placemarks.first;

    name = place.name;
    locality = place.locality;
    subLocality = place.subLocality ?? place.street;
    isoCode = place.isoCountryCode;
    cord = Cord(latitude: position.latitude, longitude: position.longitude);
  }

  void updateLocation(Position position) {
    cord = Cord(latitude: position.latitude, longitude: position.longitude);
  }
}
