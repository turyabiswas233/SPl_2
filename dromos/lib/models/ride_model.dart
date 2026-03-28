class RideStatus {
  static const String open = 'open';
  static const String inProgress = 'in_progress';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
}

class RideModel {
  final String rideId;
  final String initiatorId;
  final String startLocation;
  final double startLat;
  final double startLng;
  final String destinationName;
  final double destLat;
  final double destLng;
  final String tripQrCode;
  final String tripOtp;
  final int maxSeats;
  final String status;
  final DateTime createdAt;

  RideModel({
    this.rideId = '',
    this.initiatorId = '',
    this.startLocation = '',
    this.startLat = 0.0,
    this.startLng = 0.0,
    this.destinationName = '',
    this.destLat = 0.0,
    this.destLng = 0.0,
    this.tripQrCode = '',
    this.tripOtp = '',
    this.maxSeats = 4,
    this.status = 'open',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      rideId: json['rideId'] ?? '',
      initiatorId: json['initiatorId'] ?? '',
      startLocation: json['startLocation'] ?? '',
      startLat: (json['startLat'] ?? 0).toDouble(),
      startLng: (json['startLng'] ?? 0).toDouble(),
      destinationName: json['destinationName'] ?? json['destination'] ?? '',
      destLat: (json['destLat'] ?? 0).toDouble(),
      destLng: (json['destLng'] ?? 0).toDouble(),
      tripQrCode: json['tripQrCode'] ?? '',
      tripOtp: json['tripOtp'] ?? '',
      maxSeats: json['maxSeats'] ?? 4,
      status: json['status'] ?? RideStatus.open,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
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
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Body format for the create ride API
  Map<String, dynamic> toCreateBody() {
    return {
      'startLocation': startLocation,
      'startLat': startLat,
      'startLng': startLng,
      'destinationName': destinationName,
      'destLat': destLat,
      'destLng': destLng,
      'maxSeats': maxSeats,
    };
  }

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isEmpty => rideId.isEmpty;

  @override
  String toString() {
    return 'RideModel{rideId: $rideId, from: $startLocation, to: $destinationName, status: $status}';
  }
}
