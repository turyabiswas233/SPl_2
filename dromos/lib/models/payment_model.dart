class PaymentModel {
  final String orderId;
  final String userId;
  final String? rideId;
  final double amount;
  final String currency;
  final String status;
  final String? transactionId;
  final String? paymentMethod;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final DateTime? paymentTime;
  final DateTime createdAt;

  PaymentModel({
    required this.orderId,
    required this.userId,
    this.rideId,
    required this.amount,
    this.currency = 'BDT',
    required this.status,
    this.transactionId,
    this.paymentMethod,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.paymentTime,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      orderId: json['orderId'] ?? json['order_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      rideId: json['rideId'] ?? json['ride_id'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'BDT',
      status: json['status'] ?? 'pending',
      transactionId: json['transactionId'] ?? json['transaction_id'],
      paymentMethod: json['paymentMethod'] ?? json['payment_method'],
      customerName: json['customerName'] ?? json['customer_name'] ?? '',
      customerEmail: json['customerEmail'] ?? json['customer_email'] ?? '',
      customerPhone: json['customerPhone'] ?? json['customer_phone'] ?? '',
      paymentTime: json['paymentTime'] != null
          ? DateTime.parse(json['paymentTime'])
          : (json['payment_time'] != null
              ? DateTime.parse(json['payment_time'])
              : null),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'userId': userId,
      'rideId': rideId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'paymentTime': paymentTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
}
