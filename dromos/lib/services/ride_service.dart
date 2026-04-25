import 'dart:convert';

import 'package:dromos/models/ride_model.dart';
import 'package:dromos/models/nearby_ride_model.dart';
import 'package:dromos/models/message_model.dart';
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

  Map<String, String> get _authHeaders =>
      {
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
    required String preferredGender,
    required double destLat,
    required double destLng,
    int maxSeats = 4,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Api.url}/rides'),
        headers: _authHeaders,
        body: jsonEncode({
          'startLocation': startLocation,
          'startLat': startLat,
          'startLng': startLng,
          'destination': destination,
          'destLat': destLat,
          'destLng': destLng,
          'preferredGender': preferredGender,
          'maxSeats': maxSeats,
        }),
      );

      debugPrint('createRide status: ${response.statusCode}');
      debugPrint('createRide body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return RideModel.fromJson(body['data']);
        }
        throw Exception(body['error'] ?? 'Failed to create ride');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(
          body['error'] ?? 'Server error: ${response.statusCode}',
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
        Uri.parse('${Api.url}/users/ride-history'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> ridesJson = body['data'] is List
              ? body['data']
              : [body['data']].toList();
          debugPrint(
            'fetchMyRides ${ridesJson.toString()} rides',
          );
          return ridesJson.map((r) => RideModel.fromJson(r)).toList();
        }
      }
    } catch (e) {
      debugPrint('RideService.fetchMyRides error: $e');
    }
    return [];
  }

  /// Fetch all ride requests made by the current user.
  Future<List<RideModel>> fetchMyRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${Api.url}/users/my-requests'),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> requestsJson = body['data'] is List
              ? body['data']
              : [body['data']].toList();
          return requestsJson.map((r) => RideModel.fromJson(r)).toList();
        }
      }
    } catch (e) {
      debugPrint('RideService.fetchMyRequests error: $e');
    }
    return [];
  }

  /// Fetch nearby rides based on current location.
  /// [lng] - Longitude of current location
  /// [lat] - Latitude of current location
  /// Returns [List<NearbyRideModel>] of available nearby rides.
  Future<List<NearbyRideModel>> fetchNearbyRides({
    required double lng,
    required double lat,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${Api.url}/rides/nearby?lng=$lng&lat=$lat'),
        headers: _authHeaders,
      );

      debugPrint('fetchNearbyRides status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> ridesJson = body['data'] is List
              ? body['data']
              : [body['data']];
          debugPrint(ridesJson.toString());
          return ridesJson.map((r) => NearbyRideModel.fromJson(r)).toList();
        }
      }
    } catch (e) {
      debugPrint('RideService.fetchNearbyRides error: $e');
      rethrow;
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
      rethrow;
    }
    return null;
  }

  /// Cancel a ride by ID.
  Future<dynamic> cancelRide(String rideId) async {
    try {
      final response = await http.patch(
        Uri.parse('${Api.url}/rides/$rideId/cancel'),
        headers: _authHeaders,
      );

      final body = jsonDecode(response.body);
      return body;
    } catch (e) {
      debugPrint('RideService.cancelRide error: $e');
      rethrow ;
    }
  }

  /// Start a ride by ID.
  Future<dynamic> startRide(String rideId) async {
    try {
      final response = await http.patch(
        Uri.parse('${Api.url}/rides/$rideId/start'),
        headers: _authHeaders,
      );

      final body = jsonDecode(response.body);
      debugPrint('RideService.startRide body: $body');
      return body;
    } catch (e) {
      debugPrint('RideService.startRide error: $e');
      rethrow;
    }
  }

  /// Request to join a ride.
  Future<dynamic> requestRide(String rideId) async {
    try {
      final response = await http.post(
        Uri.parse('${Api.url}/rides/$rideId/requests'),
        headers: _authHeaders,
      );

      final body = jsonDecode(response.body);
      return body;
    } catch (e) {
      debugPrint('RideService.requestRide error: $e');
      rethrow;
    }
  }

  /// Get route information from MapBox.
  Future<dynamic> getRoute({
    required double startLng,
    required double startLat,
    required double destLng,
    required double destLat,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Api
              .url}/mapbox/route?startLng=$startLng&startLat=$startLat&destLng=$destLng&destLat=$destLat&steps=false',
        ),
        headers: _authHeaders,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body;
      }
    } catch (e) {
      debugPrint('RideService.getRoute error: $e');
      rethrow;
    }
    return null;
  }

  /// Fetch all messages for a specific ride.
  /// [rideId] - The ID of the ride
  /// Returns [List<MessageModel>] of messages for the ride.
  Future<List<MessageModel>> fetchRideMessages(String rideId) async {
    try {
      final response = await http.get(
        Uri.parse('${Api.url}/rides/$rideId/messages'),
        headers: _authHeaders,
      );

      debugPrint('fetchRideMessages status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> messagesJson = body['data'] is List
              ? body['data']
              : [body['data']];
          return messagesJson.map((m) => MessageModel.fromJson(m)).toList();
        }
      }
    } catch (e) {
      debugPrint('RideService.fetchRideMessages error: $e');
    }
    return [];
  }

  /// Send a message to a ride chat.
  /// [rideId] - The ID of the ride
  /// [senderId] - The ID of the sender
  /// [messageText] - The message content
  Future<MessageModel?> sendRideMessage({
    required String rideId,
    required String senderId,
    required String messageText,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Api.url}/rides/$rideId/messages'),
        headers: _authHeaders,
        body: jsonEncode({
          'sender_id': senderId,
          'message_text': messageText,
        }),
      );

      debugPrint('sendRideMessage status: ${response.statusCode}');
      debugPrint('sendRideMessage body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return MessageModel.fromJson(body['data']);
        }
      }
      else {
        final body = jsonDecode(response.body);
        throw Exception(
        body['message'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Join a ride by scanning QR code.
  Future<dynamic> joinByQr({
    required String tripQrCode,
    required String userId,
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Api.url}/handshake/join-by-qr'),
        headers: _authHeaders,
        body: jsonEncode({
          'tripQrCode': tripQrCode,
          'userId': userId,
          'met': {'lat': lat, 'lng': lng},
        }),
      );

      debugPrint('joinByQr status: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('RideService.joinByQr error: $e');
      rethrow;
    }
  }

  /// Verify ride with OTP.
  Future<dynamic> verifyRide({
    required String rideId,
    required String userId,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Api.url}/handshake/verify'),
        headers: _authHeaders,
        body: jsonEncode({
          'ride_id': rideId,
          'user_id': userId,
          'otp': otp,
        }),
      );

      debugPrint('verifyRide status: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('RideService.verifyRide error: $e');
      rethrow;
    }
  }
}
