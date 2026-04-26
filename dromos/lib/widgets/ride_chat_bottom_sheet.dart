import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dromos/models/message_model.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';

class RideChatBottomSheet extends StatefulWidget {
  final String rideId;
  final String rideName;

  const RideChatBottomSheet({
    super.key,
    required this.rideId,
    required this.rideName,
  });

  @override
  State<RideChatBottomSheet> createState() => _RideChatBottomSheetState();
}

class _RideChatBottomSheetState extends State<RideChatBottomSheet> {
  final _rideService = RideService();
  final _userService = UserService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _makingPhoneCall(String phoneText) async {
    if (phoneText.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No phone number provided")),
        );
      }
      return;
    }

    final status = await Permission.phone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone permission is required")),
        );
      }
      return;
    }
    // open phone app
    try {
      final res = await FlutterPhoneDirectCaller.callNumber(phoneText);
      debugPrint(res.toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _rideService.fetchRideMessages(widget.rideId);
      if (mounted) {
        setState(() => _messages = messages);
        _scrollToBottom();
      }
    } catch (e) {
      log('Error fetching messages: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final newMessage = await _rideService.sendRideMessage(
        rideId: widget.rideId,
        senderId: _userService.userId,
        messageText: messageText,
      );

      if (mounted && newMessage != null) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    } catch (e) {
      log('Error sending message: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(200),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withAlpha(70), width: 1.5),
        ),
        child: Column(
          children: [_buildHeader(), _buildMessageList(), _buildInputArea()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        border: Border(bottom: BorderSide(color: Colors.black.withAlpha(10))),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ConstColor.primaryPurple.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: ConstColor.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ride Chat',
                      style: ConstFonts.bold(size: 18, color: Colors.black87),
                    ),
                    Text(
                      widget.rideName,
                      style: ConstFonts.normal(size: 12, color: Colors.black45),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _fetchMessages,
                icon: const Icon(Icons.phone, color: ConstColor.primaryPurple),
                style: IconButton.styleFrom(
                  backgroundColor: ConstColor.primaryPurple25.withAlpha(50),
                ),
              ),
              IconButton(
                onPressed: _fetchMessages,
                icon: const Icon(Icons.refresh_rounded, color: Colors.black45),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withAlpha(20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ConstColor.primaryPurple),
            )
          : _messages.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == _userService.userId;
                return _buildMessageBubble(message, isMe);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 64,
            color: ConstColor.primaryPurple.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: ConstFonts.bold(size: 16, color: Colors.black38),
          ),
          Text(
            'Start the conversation!',
            style: ConstFonts.semibold(size: 14, color: Colors.black26),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(message),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.sender.fullName,
                      style: ConstFonts.bold(size: 10, color: Colors.black45),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? ConstColor.primaryPurple : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message.messageText,
                    style: ConstFonts.normal(
                      size: 14,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: ConstFonts.normal(size: 9, color: Colors.black38),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildAvatar(MessageModel message) {
    return GestureDetector(
      onTap: () => _showUserAction(message),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: ConstColor.primaryPurple.withAlpha(50),
        child: Text(
          message.sender.fullName[0].toUpperCase(),
          style: ConstFonts.bold(size: 12, color: ConstColor.primaryPurple),
        ),
      ),
    );
  }

  void _showUserAction(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: ConstColor.primaryPurple.withAlpha(25),
                child: Text(
                  message.sender.fullName[0],
                  style: ConstFonts.bold(
                    size: 32,
                    color: ConstColor.primaryPurple,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(message.sender.fullName, style: ConstFonts.bold(size: 20)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  overlayColor: WidgetStateProperty.all(
                    ConstColor.primaryPurple.withAlpha(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (message.sender.phoneNumber!.isNotEmpty) {
                    _makingPhoneCall(message.sender.phoneNumber ?? '');
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.phone, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      message.sender.phoneNumber ?? 'no - number',
                      style: ConstFonts.semibold(size: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(130),
        border: Border(top: BorderSide(color: Colors.black.withAlpha(13))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                style: ConstFonts.normal(size: 15),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey : ConstColor.primaryPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ConstColor.primaryPurple.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');

    if (messageDate == today) {
      return '$hour:$minute $period';
    } else {
      return '${dateTime.day}/${dateTime.month} $hour:$minute $period';
    }
  }
}
