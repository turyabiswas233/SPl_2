class MessageModel {
  final String messageId;
  final String rideId;
  final String senderId;
  final String messageText;
  final DateTime createdAt;
  final SenderInfo sender;

  MessageModel({
    required this.messageId,
    required this.rideId,
    required this.senderId,
    required this.messageText,
    required this.createdAt,
    required this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'] ?? '',
      rideId: json['rideId'] ?? '',
      senderId: json['senderId'] ?? '',
      messageText: json['messageText'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      sender: SenderInfo.fromJson(json['sender'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'rideId': rideId,
      'senderId': senderId,
      'messageText': messageText,
      'createdAt': createdAt.toString(),
      'sender': sender.toJson(),
    };
  }
}

class SenderInfo {
  final String userId;
  final String fullName;
  String? phoneNumber;

  SenderInfo({required this.userId, required this.fullName, this.phoneNumber});

  factory SenderInfo.fromJson(Map<String, dynamic> json) {
    return SenderInfo(
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? 'Unknown',
      phoneNumber: json['phoneNumber'] ?? '--',
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'fullName': fullName};
  }
}
