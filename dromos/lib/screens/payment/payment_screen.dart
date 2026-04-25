import 'package:flutter/material.dart';
import 'package:dromos/screens/payment/payment_webview_screen.dart';
import 'package:dromos/screens/payment/payment_history_screen.dart';
import 'package:dromos/services/payment_service.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';

class PaymentScreen extends StatefulWidget {
  final double? amount;
  final String? rideId;
  final String? description;

  const PaymentScreen({
    super.key,
    this.amount,
    this.rideId,
    this.description,
  });

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
   final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      _amountController.text = widget.amount!.toStringAsFixed(2);
    }
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _userService.currentUser;
    if (mounted) {
      setState(() {
        if (user.fullName.isNotEmpty) _nameController.text = user.fullName;
        if (user.email.isNotEmpty) _emailController.text = user.email;
        if (user.phoneNumber.isNotEmpty) _phoneController.text = user.phoneNumber;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        _showErrorDialog('Invalid Amount', 'Please enter a valid amount');
        return;
      }

      if (_phoneController.text.isEmpty) {
        _showErrorDialog('Missing Info', 'Phone number is required for AamarPay');
        return;
      }

      setState(() => _isLoading = true);

      final result = await PaymentService.initiatePayment(
        amount: amount,
        customerPhone: _phoneController.text,
        rideId: widget.rideId,
        customerName: _nameController.text.isNotEmpty ? _nameController.text : null,
        customerEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
        description: widget.description ?? 'Payment via Dromos',
      );

      setState(() => _isLoading = false);

      if (result['success'] == true && result['paymentUrl'] != null) {
        final paymentUrl = result['paymentUrl'] as String;
        final orderId = result['orderId'] as String;

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebviewScreen(
                paymentUrl: paymentUrl,
                orderId: orderId,
              ),
            ),
          );
        }
      } else {
        _showErrorDialog(
          'Payment Failed',
          result['error'] ?? 'Could not initiate payment. Please try again.',
        );
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          title,
          style: TextStyle(
            color: ConstColor.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TextStyle(color: ConstColor.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color pc = ConstColor.primaryColor;
    Color pbc = ConstColor.primaryBg;
    Color accentColor = ConstColor.primaryPurple;

    return Scaffold(
      backgroundColor: pbc,
      appBar: AppBar(
        title: const Text('Make Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: pc),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00796B).withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payment,
                          size: 48,
                          color: Color(0xFF00796B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AamarPay',
                        style: ConstFonts.bold(
                          size: 24,
                          color: const Color(0xFF00796B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure Payment Gateway',
                        style: ConstFonts.normal(
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (BDT)',
                    hintText: '0.00',
                    prefixText: '৳ ',
                    prefixStyle: ConstFonts.normal(size: 16, color: pc),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Enter valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+8801XXXXXXXX',
                    prefixIcon: Icon(Icons.phone, color: pc),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number required';
                    }
                    if (value.length < 10) {
                      return 'Enter valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name (Optional)',
                    hintText: 'Your Name',
                    prefixIcon: Icon(Icons.person, color: pc),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email (Optional)',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email, color: pc),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Enter valid email';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00796B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.lock, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Pay Securely via AamarPay',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentHistoryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View Payment History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.security, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Secured by AamarPay',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
