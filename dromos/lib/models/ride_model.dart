import 'package:flutter/rendering.dart';

class RideStatus {
  static const String open = 'open';
  static const String inProgress = 'in_progress';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
}

class RideModel {
  final String rideId;
  final String initiatorId;
  final String initiatorName;
  final String startLocation;
  final double startLat;
  final double startLng;
  final String destinationName;
  final double destLat;
  final double destLng;
  final String tripQrCode;
  final String tripOtp;
  final int maxSeats;
  final int curPassengers;
  final String status;
  final String preferredGender;
  final DateTime createdAt;
  final double? totalFare;  // New: Total fare for the ride
  final String? currency;   // New: Currency code

  RideModel({
    this.rideId = '',
    this.initiatorId = '',
    this.initiatorName = '',
    this.startLocation = '',
    this.startLat = 0.0,
    this.startLng = 0.0,
    this.destinationName = '',
    this.destLat = 0.0,
    this.destLng = 0.0,
    this.tripQrCode = '',
    this.tripOtp = '',
    this.maxSeats = 1,
    this.curPassengers = 1,
    this.status = 'open',
    this.preferredGender = 'other',
    DateTime? createdAt,
    this.totalFare,
    this.currency,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RideModel.fromJson(Map<String, dynamic> json) {
    debugPrint(json.toString());
    return RideModel(
      rideId: json['rideId'] ?? '',
      initiatorId: json['initiatorId'] ?? '',
      initiatorName: json['initiator'] != null ? json['initiator']['fullName'] ?? '' : '',
      startLocation: json['startLocation'] ?? '',
      startLat: (json['startLat'] ?? 0).toDouble(),
      startLng: (json['startLng'] ?? 0).toDouble(),
      destinationName: json['destinationName'] ?? json['destination'] ?? '',
      destLat: (json['destLat'] ?? 0).toDouble(),
      destLng: (json['destLng'] ?? 0).toDouble(),
      tripQrCode: json['tripQrCode'] ?? '',
      tripOtp: json['tripOtp'] ?? '',
      maxSeats: json['maxSeats'] ?? 1,
      curPassengers: (json['participants'] as List).length,
      status: json['status'] ?? RideStatus.open,
      preferredGender: json['preferredGender'] ?? 'other',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      totalFare: (json['totalFare'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'BDT',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ride_id': rideId,
      'initiator_id': initiatorId,
      'startLocation': startLocation,
      'startLat': startLat,
      'startLng': startLng,
      'destinationName': destinationName,
      'destLat': destLat,
      'destLng': destLng,
      'tripQrCode': tripQrCode,
      'tripOtp': tripOtp,
      'maxSeats': maxSeats,
      'status': status,
      'preferredGender': preferredGender,
      'created_at': createdAt.toIso8601String(),
      'totalFare': totalFare,
      'currency': currency,
    };
  }

  bool get isOpen => status.toLowerCase() == 'open' || status.toLowerCase() == 'in_progress';
  bool get isEmpty => rideId.isEmpty;

  @override
  String toString() {
    return 'RideModel{rideId: $rideId, from: $startLocation, to: $destinationName, status: $status}';
  }
}
