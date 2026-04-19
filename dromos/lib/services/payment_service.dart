import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/api.dart';

class PaymentService {
  static String get _baseUrl => Api.URL;

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
        Uri.parse('$_baseUrl/api/v1/payment/initiate'),
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

  static Future<Map<String, dynamic>> checkPaymentStatus(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v1/payment/status/$orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

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
          '$_baseUrl/api/v1/payment/user/$userId?page=$page&limit=$limit',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
