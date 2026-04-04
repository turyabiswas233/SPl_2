import 'package:dromos/models/notification_model.dart';
import 'package:dromos/services/notification_handler.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _handler = NotificationHandler();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _handler.fetchNotifications();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _handler.notifications;

    return Scaffold(
      backgroundColor: ConstColor.primaryBg,
      appBar: AppBar(
        backgroundColor: ConstColor.primaryPurple,
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_handler.unreadCount} unread',
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ConstColor.primaryPurple),
            )
          : notifications.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notifications.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) {
                  return _NotificationTile(
                    notification: notifications[index],
                    handler: _handler,
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see ride updates here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final NotificationHandler handler;

  const _NotificationTile({required this.notification, required this.handler});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead
          ? Colors.transparent
          : ConstColor.primaryPurple.withAlpha(8),
      child: ListTile(
        onTap: () => handler.markAsRead(notification.notificationId),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.grey.shade100
                : ConstColor.primaryPurple.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIcon(),
            color: notification.isRead ? Colors.grey : ConstColor.primaryPurple,
            size: 22,
          ),
        ),
        title: Text(
          notification.message,
          style: !notification.isRead
              ? ConstFonts.bold(size: 14)
              : ConstFonts.normal(size: 14, color: Colors.grey.shade600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            notification.timeAgo,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ConstColor.primaryPurple,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  IconData _getIcon() {
    final msg = notification.message.toLowerCase();
    if (msg.contains('created')) return Icons.directions_car;
    if (msg.contains('joined')) return Icons.person_add;
    if (msg.contains('cancelled')) return Icons.cancel;
    if (msg.contains('completed')) return Icons.check_circle;
    return Icons.notifications_outlined;
  }
}
