import 'package:flutter/rendering.dart';

class NotificationModel {
  final String notificationId;
  final String userId;
  final String rideId;
  final String message;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    this.notificationId = '',
    this.userId = '',
    this.rideId = '',
    this.message = '',
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    debugPrint(json.toString());
    return NotificationModel(
      notificationId: json['notificationId'] ?? '',
      userId: json['userId'] ?? '',
      rideId: json['rideId'] ?? '',
      message: json['messageText'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'ride_id': rideId,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// How long ago the notification was created
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  String toString() {
    return 'NotificationModel{id: $notificationId, message: $message, isRead: $isRead}';
  }
}
