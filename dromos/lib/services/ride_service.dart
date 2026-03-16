import 'dart:convert';

import 'package:dromos/models/ride_model.dart';
import 'package:dromos/utils/api.dart';
import 'package:dromos/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Singleton service for ride-related API operations.
class RideService {
  static final RideService _instance = RideService._internal();
  factory RideService() => _instance;
  RideService._internal();

  final _userService = UserService();

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_userService.token}',
  };

  /// Create a new ride session.
  /// Returns [RideModel] on success, throws on failure.
  Future<RideModel> createRide({
    required String startLocation,
    required double startLat,
    required double startLng,
    required String destination,
    required double destLat,
    required double destLng,
    int maxSeats = 4,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Api.url}/rides'),
        headers: _authHeaders,
        body: jsonEncode({
          'start_location': startLocation,
          'start_lat': startLat,
          'start_lng': startLng,
          'destination': destination,
          'dest_lat': destLat,
          'dest_lng': destLng,
          'max_seats': maxSeats,
        }),
      );

      debugPrint('createRide status: ${response.statusCode}');
      debugPrint('createRide body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return RideModel.fromJson(body['data']);
        }
        throw Exception(body['message'] ?? 'Failed to create ride');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
          body['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('RideService.createRide error: $e');
      rethrow;
    }
  }

  /// Fetch all rides for the current user (history).
  Future<List<RideModel>> fetchMyRides() async {
    try {
      final response = await http.get(
        Uri.parse('${Api.url}/rides'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> ridesJson = body['data'] is List
              ? body['data']
              : [body['data']];
          return ridesJson.map((r) => RideModel.fromJson(r)).toList();
        }
      }
    } catch (e) {
      debugPrint('RideService.fetchMyRides error: $e');
    }
    return [];
  }

  /// Fetch a single ride by ID.
  Future<RideModel?> fetchRide(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('${Api.url}/rides/$rideId'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return RideModel.fromJson(body['data']);
        }
      }
    } catch (e) {
      debugPrint('RideService.fetchRide error: $e');
    }
    return null;
  }
}
