import 'dart:convert';
import 'package:dromos/models/payment_model.dart';
import 'package:dromos/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../utils/api.dart';

class StripePaymentService {
  static String get _baseUrl => Api.url;

  /// Initialize Stripe with publishable key
  static Future<void> initializeStripe({String? publishableKey}) async {
    try {
      if (publishableKey != null && publishableKey.trim().isNotEmpty) {
        Stripe.publishableKey = publishableKey.trim();
        await Stripe.instance.applySettings();
      }
      debugPrint('Stripe initialized for Flutter payments');
    } catch (e) {
      debugPrint('Error initializing Stripe: $e');
    }
  }

  /// Estimate cost for a ride
  static Future<Map<String, dynamic>> estimateCost({
    required double startLng,
    required double startLat,
    required double destLng,
    required double destLat,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/payments/estimate?startLng=$startLng&startLat=$startLat&destLng=$destLng&destLat=$destLat',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {
          'success': true,
          'distance': data['data']['distance'],
          'duration': data['data']['duration'],
          'estimatedCost': data['data']['estimatedCost'],
          'paymentAmount': data['data']['paymentAmount'],
          'currency': data['data']['currency'],
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to estimate cost'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Initiate payment and get client secret from backend
  static Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String customerPhone,
    String? rideId,
    String? customerName,
    String? customerEmail,
    String? description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'amount': amount,
          'rideId': rideId,
          'customerPhone': customerPhone,
          'customerName': customerName,
          'customerEmail': customerEmail,
          'description': description ?? 'Payment for Dromos ride',
        }),
      );

      final data = jsonDecode(response.body);
      debugPrint('Initiate Payment Response: ${response.statusCode} - $data');
      if (data['success'] == true) {
        return {
          'success': true,
          'clientSecret': data['data']['clientSecret'],
          'publishableKey': data['data']['publishableKey'],
          'paymentIntentId': data['data']['paymentIntentId'],
          'orderId': data['data']['orderId'],
          'amount': data['data']['amount'],
          'currency': data['data']['currency'],
        };
      } else {
        debugPrint('Initiate Payment Error: ${data['error']}');
        return {
          'success': false,
          'error': data['error'] ?? 'Payment initiation failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Process payment with Stripe
  static Future<Map<String, dynamic>> processPayment({
    required String clientSecret,
    String? publishableKey,
    String? paymentMethodId,
  }) async {
    try {
      await initializeStripe(publishableKey: publishableKey);

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Dromos',
          style: ThemeMode.light,
          googlePay: const PaymentSheetGooglePay(
            testEnv: true,
            merchantCountryCode: 'BD',
            currencyCode: 'USD',
          ),
        ),
      );

      // Display payment sheet and process payment
      await Stripe.instance.presentPaymentSheet();

      return {
        'success': true,
        'message': 'Payment processed successfully',
      };
    } on StripeException catch (e) {
      debugPrint('Stripe Error: ${e.error.localizedMessage}');
      return {
        'success': false,
        'error': e.error.localizedMessage ?? 'Payment failed',
      };
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return {
        'success': false,
        'error': 'An error occurred during payment processing',
      };
    }
  }

  /// Get payment status by orderId
  static Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/status/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {
          'success': true,
          'data': PaymentModel.fromJson(data['data']),
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to get status'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get user's payment history
  static Future<Map<String, dynamic>> getPaymentHistory(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/payments/user/$userId?page=$page&limit=$limit',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {
          'success': true,
          'count': data['count'],
          'total': data['total'],
          'page': data['page'],
          'pages': data['pages'],
          'data': (data['data'] as List)
              .map((item) => PaymentModel.fromJson(item))
              .toList(),
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to fetch history'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Verify payment manually
  static Future<Map<String, dynamic>> verifyPayment(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'orderId': orderId}),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {
          'success': true,
          'data': PaymentModel.fromJson(data['data']),
        };
      }
      return {'success': false, 'error': data['error'] ?? 'Verification failed'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Format amount in BDT
  static String formatAmount(double amount) {
    return '৳${amount.toStringAsFixed(2)}';
  }

  /// Format date
  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return ConstColor.success;
      case 'pending':
      case 'processing':
        return ConstColor.warning;
      case 'failed':
      case 'cancelled':
        return ConstColor.error;
      default:
        return ConstColor.primaryColor.withAlpha(180);
    }
  }
}
