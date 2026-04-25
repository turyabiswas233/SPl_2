import 'package:flutter/material.dart';

class PaymentUtils {
  // AamarPay colors
  static const Color aamarPayGreen = Color(0xFF00796B);
  static const Color aamarPayDarkGreen = Color(0xFF00574B);
  static const Color aamarPayTeal = Color(0xFF00ACC1);

  // Payment status colors
  static const Color statusCompleted = Colors.green;
  static const Color statusPending = Colors.orange;
  static const Color statusProcessing = Colors.blue;
  static const Color statusFailed = Colors.red;
  static const Color statusCancelled = Colors.grey;

  // Payment types
  static const String typeRideFare = 'ride_fare';
  static const String typeDeposit = 'deposit';
  static const String typeSubscription = 'subscription';

  // Currency
  static const String currencyBdt = 'BDT';
  static const String currencyUsd = 'USD';

  // Payment methods
  static const String methodCard = 'card';
  static const String methodQr = 'qr';
  static const String methodNfc = 'nfc';
  static const String methodBank = 'bank';

  // AamarPay endpoints
  static const String sandboxUrl = 'https://sandbox.aamarpay.com';
  static const String liveUrl = 'https://secure.aamarpay.com';

  // Return URLs (should match backend config)
  static const String returnUrlSuccess = '/payment/success';
  static const String returnUrlCancel = '/payment/cancel';
  static const String returnUrlFailed = '/payment/failed';

  // Validator patterns
  static final RegExp phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
  static final RegExp emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  static final RegExp amountRegex = RegExp(r'^\d+(\.\d{1,2})?$');

  // Format helpers
  static String formatCurrency(double amount, {String currency = currencyBdt}) {
    if (currency == currencyBdt) {
      return '৳${amount.toStringAsFixed(2)}';
    } else if (currency == currencyUsd) {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return '${amount.toStringAsFixed(2)} $currency';
  }

  static String formatOrderId(String orderId) {
    // Shorten order ID for display (e.g., DRM-12345678-ABCD -> DRM-1234...ABCD)
    if (orderId.length > 16) {
      final start = orderId.substring(0, 4);
      final end = orderId.substring(orderId.length - 4);
      return '$start...$end';
    }
    return orderId;
  }

  static bool isValidPhone(String phone) {
    return phoneRegex.hasMatch(phone);
  }

  static bool isValidEmail(String email) {
    return emailRegex.hasMatch(email);
  }

  static bool isValidAmount(String amountStr) {
    return amountRegex.hasMatch(amountStr);
  }

  static String maskCardNumber(String? cardNumber) {
    if (cardNumber == null || cardNumber.length < 4) return cardNumber ?? '';
    final last4 = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $last4';
  }
}
