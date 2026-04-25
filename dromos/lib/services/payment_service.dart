import 'dart:convert';
import 'package:dromos/models/payment_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/api.dart';

class PaymentService {
  static String get _baseUrl => Api.url;

  /// Initiate payment and get payment URL
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
        Uri.parse('$_baseUrl/payment/initiate'),
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

      if (data['success'] == true) {
        return {
          'success': true,
          'paymentUrl': data['data']['paymentUrl'],
          'orderId': data['data']['orderId'],
          'amount': data['data']['amount'],
          'currency': data['data']['currency'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Payment initiation failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Get payment status by orderId
  static Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment/status/$orderId'),
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
        Uri.parse('$_baseUrl/payment/verify'),
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

  /// Launch payment URL in browser
  static Future<bool> launchPaymentUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
      return false;
    }
    return true;
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
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
