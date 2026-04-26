class NearbyRideModel {
  final String rideId;
  final String startLocation;
  final double startLat;
  final double startLng;
  final String destinationName;
  final double distance;
  final double travellingDistance;
  final double targetFare;  // New: Target fare for this ride
  final int maxSeats;
  final int currentPassengers;
  final int availableSeats;
  final String initiatorName;
  final String initiatorPhone;
  final String status;  // Add status field

  NearbyRideModel({
    required this.rideId,
    required this.startLocation,
    required this.startLat,
    required this.startLng,
    required this.destinationName,
    required this.distance,
    this.travellingDistance = 0,
    this.targetFare = 0,
    required this.status,
    required this.maxSeats,
    required this.currentPassengers,
    required this.availableSeats,
    required this.initiatorName,
    required this.initiatorPhone,
  });

  factory NearbyRideModel.fromJson(Map<String, dynamic> json) {
    return NearbyRideModel(
      rideId: json['rideId'] ?? '',
      startLocation: json['startLocation'] ?? '',
      startLat: (json['startLat'] ?? 0).toDouble(),
      startLng: (json['startLng'] ?? 0).toDouble(),
      destinationName: json['destinationName'] ?? '',
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : 0.0,
      travellingDistance: json['travelDistance'] != null ? (json['travelDistance'] as num).toDouble() : 0.0,
      targetFare: json['targetFare'] != null ? (json['targetFare'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'open',
      maxSeats: json['maxSeats'] ?? 4,
      currentPassengers: json['current_passengers'] ?? 0,
      availableSeats: json['available_seats'] ?? 0,
      initiatorName: json['initiatorName'] ?? '',
      initiatorPhone: json['initiatorPhone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'startLocation': startLocation,
      'startLat': startLat,
      'startLng': startLng,
      'destinationName': destinationName,
      'distance': distance,
      'travelDistance': travellingDistance,
      'targetFare': targetFare,
      'status': status,
      'maxSeats': maxSeats,
      'current_passengers': currentPassengers,
      'available_seats': availableSeats,
      'initiator_name': initiatorName,
      'initiator_phone': initiatorPhone,
    };
  }
}

  Map<String, dynamic> toJson() {
    return {
      'rideId': rideId,
      'startLocation': startLocation,
      'startLat': startLat,
      'startLng': startLng,
      'destinationName': destinationName,
      'status': status,
      'maxSeats': maxSeats,
      'current_passengers': currentPassengers,
      'available_seats': availableSeats,
      'initiator_name': initiatorName,
      'initiator_phone': initiatorPhone,
    };
  }
}
