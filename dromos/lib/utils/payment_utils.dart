import 'package:flutter/material.dart';

class PaymentUtils {
  // Stripe colors
  static const Color stripeBlue = Color(0xFF0A66C2);
  static const Color stripeLightBlue = Color(0xFF635BFF);
  static const Color stripeDarkBlue = Color(0xFF0066B2);

  // Payment status colors
  static const Color statusCompleted = Colors.green;
  static const Color statusPending = Colors.orange;
  static const Color statusProcessing = Colors.blue;
  static const Color statusFailed = Colors.red;
  static const Color statusCancelled = Colors.grey;
  static const Color statusRefunded = Colors.purple;

  // Payment types
  static const String typeRideFare = 'ride_fare';
  static const String typeDeposit = 'deposit';
  static const String typeSubscription = 'subscription';

  // Currency
  static const String currencyBdt = 'BDT';
  static const String currencyUsd = 'USD';

  // Payment methods (Stripe supported)
  static const String methodCard = 'card';
  static const String methodWallet = 'wallet';
  static const String methodBankAccount = 'bank_account';
  static const String methodUpi = 'upi'; // For Indian users

  // Stripe environment
  static const String sandboxUrl = 'https://sandbox.stripe.com';
  static const String liveUrl = 'https://stripe.com';

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

  /// Get payment status display text
  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return status;
    }
  }

  /// Get error message for Stripe errors
  static String getStripeErrorMessage(String errorCode) {
    const Map<String, String> errorMessages = {
      'card_declined': 'Your card was declined. Please use a different payment method.',
      'expired_card': 'Your card has expired. Please use a different card.',
      'processing_error': 'An error occurred while processing your payment. Please try again.',
      'authentication_required': 'Your payment requires authentication. Please try again.',
      'insufficient_funds': 'Your card has insufficient funds. Please use a different payment method.',
      'incorrect_cvc': 'The CVC code is incorrect. Please try again.',
      'lost_card': 'This card is flagged as lost. Please use a different payment method.',
      'stolen_card': 'This card is flagged as stolen. Please use a different payment method.',
    };
    return errorMessages[errorCode] ?? 'Payment failed. Please try again.';
  }
}

