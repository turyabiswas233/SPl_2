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
      rideId: json['ride_id'] ?? '',
      initiatorId: json['initiator_id'] ?? '',
      startLocation: json['start_location'] ?? '',
      startLat: (json['start_lat'] ?? 0).toDouble(),
      startLng: (json['start_lng'] ?? 0).toDouble(),
      destinationName: json['destination_name'] ?? json['destination'] ?? '',
      destLat: (json['dest_lat'] ?? 0).toDouble(),
      destLng: (json['dest_lng'] ?? 0).toDouble(),
      tripQrCode: json['trip_qr_code'] ?? '',
      tripOtp: json['trip_otp'] ?? '',
      maxSeats: json['max_seats'] ?? 4,
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ride_id': rideId,
      'initiator_id': initiatorId,
      'start_location': startLocation,
      'start_lat': startLat,
      'start_lng': startLng,
      'destination_name': destinationName,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'trip_qr_code': tripQrCode,
      'trip_otp': tripOtp,
      'max_seats': maxSeats,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Body format for the create ride API
  Map<String, dynamic> toCreateBody() {
    return {
      'start_location': startLocation,
      'start_lat': startLat,
      'start_lng': startLng,
      'destination': destinationName,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'max_seats': maxSeats,
    };
  }

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isEmpty => rideId.isEmpty;

  @override
  String toString() {
    return 'RideModel{rideId: $rideId, from: $startLocation, to: $destinationName, status: $status}';
  }
}
