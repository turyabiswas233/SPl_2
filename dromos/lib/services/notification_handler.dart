import 'dart:convert';
import 'dart:async';

import 'package:dromos/models/notification_model.dart';
import 'package:dromos/utils/api.dart';
import 'package:dromos/utils/notification_service.dart';
import 'package:dromos/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Singleton handler for fetching and managing API notifications.
///
/// Usage:
///   final handler = NotificationHandler();
///   await handler.fetchNotifications();
///   final unread = handler.unreadCount;
class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();

  factory NotificationHandler() => _instance;

  NotificationHandler._internal();

  final _userService = UserService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  int get totalCount => _notifications.length;

  /// Stream controller to broadcast notification updates.
  final _controller = StreamController<List<NotificationModel>>.broadcast();

  Stream<List<NotificationModel>> get notificationStream => _controller.stream;

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_userService.token}',
  };

  /// Fetch notifications from the server.
  Future<List<NotificationModel>> fetchNotifications() async {
    if (_userService.token.isEmpty) return [];

    _isLoading = true;
    _controller.add(_notifications);

    try {
      final response = await http.get(
        Uri.parse('${Api.url}/notifications'),
        headers: _authHeaders,
      );

      debugPrint('fetchNotifications status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> list = body['data'];
          final fetched = list
              .map((n) => NotificationModel.fromJson(n))
              .toList();

          // Check for new unread notifications and show local notification
          for (final n in fetched) {
            final alreadyExists = _instance._notifications.any(
              (e) => e.notificationId == n.notificationId,
            );
            if (!alreadyExists && !n.isRead) {
              NotificationController.createNewNotification(
                id: n.notificationId.hashCode,
                title: 'Dromos',
                body: n.message,
                payload: n.notificationId,
              );
            }
          }

          _notifications = fetched;
          _controller.add(_notifications);
        }
      }
    } catch (e) {
      debugPrint('NotificationHandler.fetchNotifications error: $e');
    } finally {
      _isLoading = false;
    }

    return _notifications;
  }

  Future<void> markAsRead(String notificationId) async {
    if (_userService.token.isEmpty) return;
    try {
      final response = await http.put(
        Uri.parse('${Api.url}/notifications/$notificationId/read'),
        headers: _authHeaders,
      );
      debugPrint('markAsRead status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final index = _notifications.indexWhere(
            (n) => n.notificationId == notificationId,
          );
          if (index != -1) {
            _notifications[index].isRead = true;
            _controller.add(_notifications);
          }
        }
      }
    } catch (e) {
      debugPrint('NotificationHandler.markAsRead error: $e');
      rethrow;
    }
  }

  /// Clear all cached notifications locally.
  void clearLocal() {
    _notifications = [];
    _controller.add(_notifications);
  }

  void dispose() {
    _controller.close();
  }
}
