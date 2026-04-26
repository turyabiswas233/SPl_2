import 'package:dromos/screens/payment/payment_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/services/stripe_payment_service.dart';
import 'package:dromos/screens/payment/payment_screen.dart';

/// Example integration for Stripe payment flows
class PaymentIntegrationExample {
  /// Trigger payment flow for a completed ride using Stripe
  /// 
  /// Usage:
  /// ```dart
  /// PaymentIntegrationExample.initiateRidePayment(
  ///   context,
  ///   amount: 250.0,
  ///   rideId: 'ride_123',
  ///   description: 'Ride from DHK to CTG',
  /// );
  /// ```
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

  /// Direct payment without ride association (e.g., deposit, subscription) using Stripe
  /// 
  /// Usage:
  /// ```dart
  /// PaymentIntegrationExample.initiateGenericPayment(
  ///   context,
  ///   amount: 500.0,
  ///   description: 'Wallet top-up',
  /// );
  /// ```
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

  /// Payment with cost estimation from route
  /// 
  /// Usage:
  /// ```dart
  /// PaymentIntegrationExample.initiatePaymentWithEstimate(
  ///   context,
  ///   startLat: 23.8103,
  ///   startLng: 90.4125,
  ///   destLat: 23.7804,
  ///   destLng: 90.3599,
  ///   rideId: 'ride_456',
  /// );
  /// ```
  static void initiatePaymentWithEstimate(BuildContext context, {
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
    String? rideId,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          startLat: startLat,
          startLng: startLng,
          destLat: destLat,
          destLng: destLng,
          rideId: rideId,
          description: 'Payment for Dromos ride',
        ),
      ),
    );
  }

  /// Check if user is logged in before allowing payment
  static bool canUserPay(UserService userService) {
    return userService.isLoggedIn && userService.userId.isNotEmpty;
  }

  /// Get user's payment history with Stripe
  /// 
  /// Usage:
  /// ```dart
  /// await PaymentIntegrationExample.viewPaymentHistory(context);
  /// ```
  static Future<void> viewPaymentHistory(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentHistoryScreen(),
      ),
    );
  }

  /// Verify payment status manually (useful if payment status is ambiguous)
  /// 
  /// Usage:
  /// ```dart
  /// final isVerified = await PaymentIntegrationExample.verifyPaymentStatus('order_123');
  /// ```
  static Future<bool> verifyPaymentStatus(String orderId) async {
    final result = await StripePaymentService.verifyPayment(orderId);
    return result['success'] == true;
  }

  /// Get payment status for a specific order
  /// 
  /// Usage:
  /// ```dart
  /// final status = await PaymentIntegrationExample.getPaymentStatus('order_123');
  /// print('Payment Status: ${status['data']['status']}');
  /// ```
  static Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    return await StripePaymentService.getPaymentStatus(orderId);
  }

  /// Initialize Stripe payment system (call this once at app startup)
  /// 
  /// Usage:
  /// ```dart
  /// void main() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await PaymentIntegrationExample.initializePaymentSystem();
  ///   runApp(const DromosApp());
  /// }
  /// ```
  static Future<void> initializePaymentSystem() async {
    await StripePaymentService.initializeStripe();
  }
}

