import 'package:flutter/material.dart';
import 'package:dromos/services/stripe_payment_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String orderId;

  const PaymentSuccessScreen({super.key, required this.orderId});

  @override
  PaymentSuccessScreenState createState() => PaymentSuccessScreenState();
}

class PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _paymentData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPaymentStatus();
  }

  Future<void> _fetchPaymentStatus() async {
    final result = await StripePaymentService.getPaymentStatus(widget.orderId);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] != null) {
          _paymentData = (result['data'] as dynamic).toJson();
        } else {
          _error = result['error'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color pc = ConstColor.primaryColor;
    Color accentColor = ConstColor.primaryPurple;
    Color pbc = ConstColor.primaryBg;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 80,
                            color: Colors.green.shade600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Payment Successful!',
                          style: ConstFonts.bold(
                            size: 28,
                            color: Colors.green.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your payment has been processed successfully with Stripe.',
                          style: ConstFonts.normal(
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: pbc,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow('Order ID', _paymentData?['orderId'] ?? widget.orderId),
                              _buildDetailRow('Amount', StripePaymentService.formatAmount(
                                _paymentData?['amount']?.toDouble() ?? 0.0,
                              )),
                              _buildDetailRow('Status', 'Completed',
                                  valueColor: Colors.green.shade700),
                              if (_paymentData?['transactionId'] != null)
                                _buildDetailRow(
                                    'Transaction ID',
                                    _paymentData?['transactionId'] ?? 'N/A'),
                              if (_paymentData?['paymentMethod'] != null)
                                _buildDetailRow('Payment Method',
                                    _paymentData?['paymentMethod'] ?? 'Card'),
                              _buildDetailRow(
                                  'Payment Gateway',
                                  'Stripe',
                                  valueColor: Colors.blue.shade700),
                              _buildDetailRow(
                                  'Date',
                                  StripePaymentService.formatDate(
                                    _paymentData?['paymentTime'] != null
                                        ? DateTime.tryParse(_paymentData!['paymentTime'])
                                        : null,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Back'),
                                style: OutlinedButton.styleFrom(
                                  overlayColor: accentColor.withAlpha(30),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: pc),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/home',
                                    (route) => false,
                                  );
                                },
                                icon: const Icon(Icons.home, color: ConstColor.secondaryColor),
                                label: const Text('Home', style: TextStyle(color: ConstColor.secondaryColor),),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  overlayColor: pbc.withAlpha(50),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: ConstFonts.normal(
              size: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: ConstFonts.bold(
                size: 10,
                color: valueColor ?? ConstColor.primaryColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
