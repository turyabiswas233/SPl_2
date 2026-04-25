import 'package:dromos/screens/payment/payment_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/services/payment_service.dart';
import 'package:dromos/screens/payment/payment_screen.dart';

class PaymentIntegrationExample {
  /// Trigger payment flow for a completed ride
  static void initiateRidePayment(BuildContext context, {
    required double amount,
    required String rideId,
    String? description,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: amount,
          rideId: rideId,
          description: description ?? 'Payment for Dromos ride',
        ),
      ),
    );
  }

  /// Direct payment without ride association (e.g., deposit, subscription)
  static void initiateGenericPayment(BuildContext context, {
    required double amount,
    String? description,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: amount,
          description: description ?? 'Dromos payment',
        ),
      ),
    );
  }

  /// Check if user is logged in before allowing payment
  static bool canUserPay(UserService userService) {
    return userService.isLoggedIn && userService.userId.isNotEmpty;
  }

  /// Get user's payment history
  static Future<void> viewPaymentHistory(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentHistoryScreen(),
      ),
    );
  }

  /// Verify payment status manually (useful if payment status is ambiguous)
  static Future<bool> verifyPaymentStatus(String orderId) async {
    final result = await PaymentService.verifyPayment(orderId);
    return result['success'] == true;
  }
}
