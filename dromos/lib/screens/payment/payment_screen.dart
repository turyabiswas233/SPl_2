import 'package:flutter/material.dart';
import 'package:dromos/screens/payment/payment_webview_screen.dart';
import 'package:dromos/screens/payment/payment_history_screen.dart';
import 'package:dromos/services/payment_service.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/services/ride_service.dart';
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

  bool _isLoading = false;
  bool _isEstimating = false;
  bool _isCheckingRide = false;
  double? _estimatedCost;
  double? _paymentAmount;
  bool _isInitiator = false;
  String? _initiatorName;

  final UserService _userService = UserService();
  final RideService _rideService = RideService();

  @override
  void initState() {
    super.initState();
    if (widget.amount != null) {
      _amountController.text = widget.amount!.toStringAsFixed(2);
    } else if (widget.startLat != null &&
        widget.startLng != null &&
        widget.destLat != null &&
        widget.destLng != null) {
      _estimateCost();
    }
    if (widget.rideId != null) {
      _checkIfInitiator();
    }
    _loadUserData();
  }

  Future<void> _checkIfInitiator() async {
    if (widget.rideId == null) return;

    setState(() => _isCheckingRide = true);
    try {
      final ride = await _rideService.fetchRide(widget.rideId!);
      if (ride != null && mounted) {
        setState(() {
          _isInitiator = ride.initiatorId == _userService.userId;
          _initiatorName = ride.initiatorName;
        });
      }
    } catch (e) {
      debugPrint('Error checking ride: $e');
    } finally {
      if (mounted) setState(() => _isCheckingRide = false);
    }
  }

  Future<void> _estimateCost() async {
    if (widget.startLat == null ||
        widget.startLng == null ||
        widget.destLat == null ||
        widget.destLng == null) {
      return;
    }

    setState(() => _isEstimating = true);
    try {
      final result = await PaymentService.estimateCost(
        startLng: widget.startLng!,
        startLat: widget.startLat!,
        destLng: widget.destLng!,
        destLat: widget.destLat!,
      );

      if (result['success'] == true && mounted) {
        setState(() {
          _estimatedCost = result['estimatedCost'];
          _paymentAmount = result['paymentAmount'];
          _amountController.text = _paymentAmount!.toStringAsFixed(2);
        });
      }
    } catch (e) {
      debugPrint('Error estimating cost: $e');
    } finally {
      if (mounted) setState(() => _isEstimating = false);
    }
  }

  Future<void> _loadUserData() async {
    final user = _userService.currentUser;
    if (mounted) {
      setState(() {
        if (user.fullName.isNotEmpty) _nameController.text = user.fullName;
        if (user.email.isNotEmpty) _emailController.text = user.email;
        if (user.phoneNumber.isNotEmpty) {
          _phoneController.text = user.phoneNumber;
        }
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
        _showErrorDialog(
          'Missing Info',
          'Phone number is required for AamarPay',
        );
        return;
      }

      setState(() => _isLoading = true);

      final result = await PaymentService.initiatePayment(
        amount: amount,
        customerPhone: _phoneController.text,
        rideId: widget.rideId,
        customerName: _nameController.text.isNotEmpty
            ? _nameController.text
            : null,
        customerEmail: _emailController.text.isNotEmpty
            ? _emailController.text
            : null,
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

    // If user is the ride initiator, show different UI
    if (_isCheckingRide) {
      return Scaffold(
        backgroundColor: pbc,
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
        backgroundColor: pbc,
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: ConstColor.primaryPurple.withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payment,
                              size: 48,
                              color: ConstColor.primaryPurple,
                            ),
                          ),
                          if (_initiatorName != null)
                            const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _initiatorName != null
                            ? 'Payment to $_initiatorName'
                            : 'AamarPay',
                        textAlign: TextAlign.center,
                        style: ConstFonts.bold(
                          size: 22,
                          color: ConstColor.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Secure Ride Sharing Payment',
                        style: ConstFonts.normal(size: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_circle,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You are the Ride Initiator',
                  style: ConstFonts.bold(size: 24, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  'As the ride initiator, you will receive payments from other participants. No payment is required from you at this time.',
                  textAlign: TextAlign.center,
                  style: ConstFonts.normal(
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                if (_estimatedCost != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
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
                        const SizedBox(height: 8),
                        Text(
                          '৳ ${_estimatedCost!.toStringAsFixed(2)}',
                          style: ConstFonts.bold(
                            size: 20,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                          color: ConstColor.primaryPurple.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payment,
                          size: 48,
                          color: ConstColor.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AamarPay',
                        style: ConstFonts.bold(
                          size: 24,
                          color: ConstColor.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Secure Payment Gateway',
                        style: ConstFonts.normal(size: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (_isEstimating)
                  const Center(
                    child: CircularProgressIndicator(
                      color: ConstColor.primaryPurple,
                    ),
                  )
                else if (_estimatedCost != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Estimated Cost:',
                              style: ConstFonts.normal(
                                size: 14,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            Text(
                              '৳ ${_estimatedCost!.toStringAsFixed(2)}',
                              style: ConstFonts.bold(
                                size: 16,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Your Share (50%):',
                              style: ConstFonts.normal(
                                size: 14,
                                color: Colors.green.shade800,
                              ),
                            ),
                            Text(
                              '৳ ${_paymentAmount!.toStringAsFixed(2)}',
                              style: ConstFonts.bold(
                                size: 16,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount (BDT)',
                    hintText: '0.00',
                    prefixText: '৳ ',
                    prefixStyle: ConstFonts.normal(size: 16, color: pc),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      backgroundColor: ConstColor.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ConstColor.primaryPurple.withAlpha(100),
                              ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
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
