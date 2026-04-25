import 'package:flutter/material.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/services/payment_service.dart';
import 'package:dromos/screens/payment/payment_screen.dart';

/// Example: How to initiate a payment from a ride completion screen
///
/// Usage:
/// 1. After ride ends, calculate fare
/// 2. Navigate to PaymentScreen with amount and rideId
///
/// Example:
/// ```dart
/// // In your ride completion screen:
/// void _onRideComplete() {
///   final double fare = 150.50; // Calculate fare
///   final String rideId = 'ride_uuid_here';
///
///   Navigator.push(
///     context,
///     MaterialPageRoute(
///       builder: (context) => PaymentScreen(
///         amount: fare,
///         rideId: rideId,
///         description: 'Payment for ride from University to Airport',
///       ),
///     ),
///   );
/// }
/// ```
///
/// The PaymentScreen will:
/// 1. Pre-fill amount if provided
/// 2. Allow user to enter/confirm phone number
/// 3. Initiate payment via backend
/// 4. Open AamarPay in WebView
/// 5. Handle redirects to success/failure screens

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
