import 'package:dromos/screens/payment/payment_history_screen.dart';
import 'package:dromos/screens/payment/payment_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:dromos/services/ride_service.dart';
import 'package:dromos/services/stripe_payment_service.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';

class PaymentScreen extends StatefulWidget {
  final double? amount;
  final String? rideId;
  final String? description;
  final double? startLat;
  final double? startLng;
  final double? destLat;
  final double? destLng;

  const PaymentScreen({
    super.key,
    this.amount,
    this.rideId,
    this.description,
    this.startLat,
    this.startLng,
    this.destLat,
    this.destLng,
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

  final UserService _userService = UserService();
  final RideService _rideService = RideService();

  bool _isLoading = false;
  bool _isEstimating = false;
  bool _isCheckingRide = false;
  bool _isInitiator = false;
  double? _estimatedCost;
  double? _paymentAmount;
  String? _initiatorName;

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      _amountController.text = widget.amount!.toStringAsFixed(2);
    }
    StripePaymentService.initializeStripe();
    _loadUserData();

    if (widget.startLat != null &&
        widget.startLng != null &&
        widget.destLat != null &&
        widget.destLng != null) {
      _estimateCost();
    }

    if (widget.rideId != null) {
      _checkIfInitiator();
    }
  }

  Future<void> _loadUserData() async {
    final user = _userService.currentUser;
    if (!mounted) return;

    setState(() {
      if (user.fullName.isNotEmpty) {
        _nameController.text = user.fullName;
      }
      if (user.email.isNotEmpty) {
        _emailController.text = user.email;
      }
      if (user.phoneNumber.isNotEmpty) {
        _phoneController.text = user.phoneNumber;
      }
    });
  }

  Future<void> _checkIfInitiator() async {
    final rideId = widget.rideId;
    if (rideId == null) return;

    setState(() => _isCheckingRide = true);
    try {
      final ride = await _rideService.fetchRide(rideId);
      if (!mounted) return;

      setState(() {
        _isInitiator = ride != null && ride.initiatorId == _userService.userId;
        _initiatorName = ride?.initiatorName;
      });
    } catch (e) {
      debugPrint('Error checking ride: $e');
    } finally {
      if (mounted) setState(() => _isCheckingRide = false);
    }
  }

  Future<void> _estimateCost() async {
    final startLat = widget.startLat;
    final startLng = widget.startLng;
    final destLat = widget.destLat;
    final destLng = widget.destLng;

    if (startLat == null ||
        startLng == null ||
        destLat == null ||
        destLng == null) {
      return;
    }

    setState(() => _isEstimating = true);
    try {
      final result = await StripePaymentService.estimateCost(
        startLat: startLat,
        startLng: startLng,
        destLat: destLat,
        destLng: destLng,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          _estimatedCost = (result['estimatedCost'] as num?)?.toDouble();
          _paymentAmount = (result['paymentAmount'] as num?)?.toDouble();
          final targetAmount = _paymentAmount ?? _estimatedCost;
          if (targetAmount != null) {
            _amountController.text = targetAmount.toStringAsFixed(2);
          }
        });
      }
    } catch (e) {
      debugPrint('Error estimating cost: $e');
    } finally {
      if (mounted) setState(() => _isEstimating = false);
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
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showErrorDialog('Invalid Amount', 'Please enter a valid amount');
      return;
    }

    setState(() => _isLoading = true);

    final initiateResult = await StripePaymentService.initiatePayment(
      amount: amount,
      customerPhone: _phoneController.text.trim(),
      rideId: widget.rideId,
      customerName: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      customerEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      description: widget.description ?? 'Payment via Dromos',
    );

    if (!mounted) return;

    if (initiateResult['success'] != true ||
        initiateResult['clientSecret'] == null) {
      setState(() => _isLoading = false);
      _showErrorDialog(
        'Payment Error',
        initiateResult['error'] ?? 'Could not initiate payment',
      );
      return;
    }

    final paymentResult = await StripePaymentService.processPayment(
      clientSecret: initiateResult['clientSecret'] as String,
      publishableKey: initiateResult['publishableKey'] as String?,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (paymentResult['success'] == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PaymentSuccessScreen(orderId: initiateResult['orderId']),
        ),
        (Route<dynamic> route) => route.isFirst,
      );
      return;
    }

    _showErrorDialog(
      'Payment Failed',
      paymentResult['error'] ?? 'Payment could not be completed',
    );
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

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pc = ConstColor.primaryColor;
    final accentColor = ConstColor.primaryPurple;
    final backgroundColor = ConstColor.primaryBg;

    if (_isCheckingRide) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Payment'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: pc),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: ConstColor.primaryPurple),
        ),
      );
    }

    if (_isInitiator) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Ride Payment'),
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
            child: Column(
              children: [
                _buildSectionCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 64,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You are the ride initiator',
                        style: ConstFonts.bold(size: 22, color: pc),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Payment will be handled by participants. No payment is required from you right now.',
                        style: ConstFonts.normal(
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_estimatedCost != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Estimated Total Ride Cost',
                                style: ConstFonts.normal(
                                  size: 14,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '৳ ${_estimatedCost!.toStringAsFixed(2)}',
                                style: ConstFonts.bold(
                                  size: 22,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
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
                _buildSectionCard(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentColor.withAlpha(30),
                              Colors.blue.shade50,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 44,
                          color: ConstColor.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _initiatorName != null
                            ? 'Payment to $_initiatorName'
                            : 'Stripe Payment',
                        textAlign: TextAlign.center,
                        style: ConstFonts.bold(size: 24, color: pc),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure ride-sharing payment via Stripe',
                        style: ConstFonts.normal(
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isEstimating)
                  const Center(
                    child: CircularProgressIndicator(
                      color: ConstColor.primaryPurple,
                    ),
                  )
                else if (_estimatedCost != null)
                  _buildSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride Estimate',
                          style: ConstFonts.bold(size: 16, color: pc),
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Total estimated cost',
                          '৳ ${_estimatedCost!.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          'Your share',
                          '৳ ${(_paymentAmount ?? _estimatedCost ?? 0).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),
                if (_estimatedCost != null) const SizedBox(height: 20),
                _buildTextField(
                  controller: _amountController,
                  labelText: 'Amount (BDT)',
                  hintText: '0.00',
                  onChange: (val) {
                    _amountController.text = val.replaceAll(
                      RegExp(r'[^\d.]'),
                      '',
                    );
                  },
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixText: '৳ ',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter amount';
                    }
                    final amount = double.tryParse(value.trim());
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid amount';
                    }
                    if (amount > _estimatedCost!.toDouble()) {
                      return 'Amount cannot exceed estimated cost';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  hintText: 'Your name',
                  prefixIcon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  hintText: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: '+8801XXXXXXXX',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.trim().length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handlePayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.payment_outlined),
                              SizedBox(width: 10),
                              Text(
                                'Proceed to Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentHistoryScreen(),
                      ),
                      (Route<dynamic> route) => route.isFirst,
                    ),
                    icon: const Icon(Icons.history),
                    label: const Text('View Payment History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: pc,
                      side: BorderSide(color: pc),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Secured by Stripe',
                    style: ConstFonts.normal(
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChange,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChange,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixText: prefixText,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: ConstColor.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: ConstColor.primaryPurple,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: ConstFonts.normal(size: 14, color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: ConstFonts.bold(size: 16, color: ConstColor.primaryColor),
        ),
      ],
    );
  }
}
