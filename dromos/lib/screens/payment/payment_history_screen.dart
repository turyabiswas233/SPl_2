import 'package:flutter/material.dart';
import 'package:dromos/models/payment_model.dart';
import 'package:dromos/services/stripe_payment_service.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  PaymentHistoryScreenState createState() => PaymentHistoryScreenState();
}

class PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<PaymentModel> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    final userService = UserService();
    final userId = userService.userId;

    if (userId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Please login to view payment history';
      });
      return;
    }

    final result = await StripePaymentService.getPaymentHistory(userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _payments = List<PaymentModel>.from(result['data']);
        } else {
          _error = result['error'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color pc = ConstColor.primaryColor;
    Color pbc = ConstColor.primaryBg;
    Color accentColor = ConstColor.primaryPurple;

    return Scaffold(
      backgroundColor: pbc,
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: pc),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: ConstFonts.normal(size: 16, color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchPayments,
                        style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _payments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payments_outlined, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No Payments Yet',
                            style: ConstFonts.bold(size: 20, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your payment history will appear here',
                            style: ConstFonts.normal(size: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPayments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              StripePaymentService.formatAmount(payment.amount),
                                              style: ConstFonts.bold(
                                                size: 22,
                                                color: accentColor,
                                              ),
                                            ),
                                            Text(
                                              payment.currency,
                                              style: ConstFonts.normal(
                                                size: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: StripePaymentService.getStatusColor(payment.status)
                                              .withAlpha(30),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          payment.status.toUpperCase(),
                                          style: ConstFonts.semibold(
                                            size: 11,
                                            color: StripePaymentService.getStatusColor(payment.status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  _buildInfoRow(Icons.receipt_long, 'Order ID', payment.orderId, pc),
                                  if (payment.transactionId != null && payment.transactionId!.isNotEmpty)
                                    _buildInfoRow(
                                        Icons.swap_horiz, 'Transaction', payment.transactionId!, pc),
                                  _buildInfoRow(Icons.phone, 'Phone', payment.customerPhone, pc),
                                  _buildInfoRow(
                                      Icons.calendar_today,
                                      'Date',
                                      StripePaymentService.formatDate(payment.createdAt),
                                      Colors.grey.shade600),
                                  _buildInfoRow(
                                      Icons.credit_card,
                                      'Gateway',
                                      'Stripe',
                                      Colors.blue.shade700),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ConstFonts.light(
                    size: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                Text(
                  value,
                  style: ConstFonts.normal(
                    size: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
