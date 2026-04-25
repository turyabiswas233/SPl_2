import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/id_card_parser.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/colors.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

  static const Color accentColor = ConstColor.primaryPurple;
  static const Color fColor = ConstColor.primaryColor;
  static const Color bColor = ConstColor.primaryBg;
  static const Color sColor = ConstColor.secondaryColor;

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _deptCtrl;
  late final TextEditingController _hallCtrl;
  late final TextEditingController _genderCtrl;

  @override
  void initState() {
    super.initState();
    final user = _userService.currentUser;
    _fullNameCtrl = TextEditingController(text: user.fullName);
    _phoneCtrl = TextEditingController(text: user.phoneNumber);
    _deptCtrl = TextEditingController(text: user.deptName);
    _hallCtrl = TextEditingController(text: user.hallName);
    _genderCtrl = TextEditingController(text: user.gender);

    if (user.isEmpty && _userService.isLoggedIn) {
      _refreshProfile();
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    _hallCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    await _userService.fetchProfile();
    if (mounted) {
      final user = _userService.currentUser;
      _fullNameCtrl.text = user.fullName;
      _phoneCtrl.text = user.phoneNumber;
      _deptCtrl.text = user.deptName;
      _hallCtrl.text = user.hallName;
      _genderCtrl.text = user.gender;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final success = await _userService.updateProfile(
      fullName: _fullNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim(),
      deptName: _deptCtrl.text.trim(),
      hallName: _hallCtrl.text.trim(),
      gender: _genderCtrl.text.trim().toLowerCase(),
    );
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile updated successfully!'
                : 'Failed to update profile.',
            style: ConstFonts.semibold(
              size: 12,
              color: success ? Colors.green : Colors.red,
            ),
          ),
          backgroundColor: success ? Colors.green.shade50 : Colors.red.shade50,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      if (success) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: accentColor,
        foregroundColor: sColor,
      ),
      backgroundColor: bColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Personal Information'),
                    const SizedBox(height: 12),
                    _buildEditableField(
                      controller: _fullNameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildEditableField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Phone number is required'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionLabel('Academic Information'),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      label: 'Email',
                      value: _userService.currentUser.email,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildReadOnlyField(
                      label: 'Registration Number',
                      value: _userService.currentUser.registrationNumber,
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildEditableField(
                      controller: _deptCtrl,
                      label: 'Department',
                      icon: Icons.school_outlined,
                    ),
                    const SizedBox(height: 14),
                    _buildEditableField(
                      controller: _hallCtrl,
                      label: 'Hall Name',
                      icon: Icons.apartment_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildGenderSelector(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Profile Header ──────────────────────────────────────────────────────
  Widget _buildProfileHeader() {
    Color pc = ConstColor.primaryColor;
    Color accentColor = ConstColor.primaryPurple;

    final user = _userService.currentUser;
    void showErrorDialog(String message, List<String>? tips) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scanning Failed',
                    style: ConstFonts.bold(size: 18, color: Colors.red),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: ConstFonts.normal(size: 14, color: pc)),
                  if (tips != null && tips.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Tips for better scanning:',
                      style: ConstFonts.bold(size: 14, color: accentColor),
                    ),
                    const SizedBox(height: 8),
                    ...tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          tip,
                          style: ConstFonts.normal(size: 13, color: pc),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: ConstColor.error),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: ConstFonts.normal(size: 14, color: ConstColor.error),
                ),
              ),
            ],
          );
        },
      );
    }

    Future<void> showVerificationSuccess(String code) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              'Verification Successful',
              style: ConstFonts.bold(size: 20, color: accentColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your QR code was validated successfully.',
                  style: ConstFonts.normal(size: 14, color: pc),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  code,
                  textAlign: TextAlign.center,
                  style: ConstFonts.normal(size: 12, color: pc),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: ConstFonts.normal(size: 14, color: accentColor),
                ),
              ),
            ],
          );
        },
      );
    }

    Future<void> validateVerificationCode(String code) async {
      setState(() => _isLoading = true);
      IdCardParser.uniqueCode = code.split('/').last;
      final regNum = _userService.currentUser.registrationNumber;
      final isValid = await IdCardParser.isValidUniqueCode(regNum);
      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (!mounted) return;

      if (isValid) {
        await _refreshProfile();
        await showVerificationSuccess(code);
      } else {
        showErrorDialog(
          'Invalid unique QR code.',
          [
            'Make sure the code is from an authorized DU QR card or pass.',
            'Try scanning again with better lighting.',
          ],
        );
      }
    }

    Future<void> scanVerificationQr() async {
      final scannedCode = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? code = barcodes.first.rawValue;
                    debugPrint('Scanned QR code: $code');
                    if (code != null && code.isNotEmpty) {
                      Navigator.pop(context, code);
                    }
                  }
                },
              ),
              Positioned(
                top: 24,
                right: 24,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Text(
                  'Scan verification QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (scannedCode != null && scannedCode.isNotEmpty) {
        await validateVerificationCode(scannedCode);
      }
    }

    return Column(
      children: [
        Stack(alignment: Alignment.bottomRight, children: [user.avatar()]),
        const SizedBox(height: 12),
        Text(
          user.fullName.isNotEmpty ? user.fullName : 'User',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: fColor,
          ),
        ),
        const SizedBox(height: 4),
        if (!user.isVerified)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withAlpha(50),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Click the tag below to verify your account",
              style: TextStyle(fontSize: 12),
            ),
          ),
        if (!user.isVerified)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.all(0),
            ),
            onPressed: () async {
              await scanVerificationQr();
            },
            child: user.verificationTag,
          )
        else
          user.verificationTag,
      ],
    );
  }

  // ── Section Label ───────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: accentColor.withAlpha(180),
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ── Editable Text Field ─────────────────────────────────────────────────

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: ConstFonts.normal(size: 14, color: fColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: fColor.withAlpha(140)),
        prefixIcon: Icon(icon, color: accentColor, size: 22),
        filled: true,
        fillColor: accentColor.withAlpha(10),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  // ── Read-Only Field ─────────────────────────────────────────────────────

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ConstFonts.semibold(
                    size: 12,
                    color: fColor.withAlpha(100),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: ConstFonts.semibold(
                    size: 14,
                    color: fColor.withAlpha(100),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline_rounded,
            color: Colors.grey.shade400,
            size: 18,
          ),
        ],
      ),
    );
  }

  // ── Gender Selector ─────────────────────────────────────────────────────

  Widget _buildGenderSelector() {
    var genders = ['male', 'female', 'other'];

    return DropdownButtonFormField<String>(
      initialValue: _genderCtrl.text.isNotEmpty ? _genderCtrl.text : null,
      items: genders.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value.toUpperCase(),
            style: ConstFonts.normal(size: 14, color: ConstColor.primaryColor),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _genderCtrl.text = newValue!;
        });
      },
      iconEnabledColor: accentColor,
      dropdownColor: ConstColor.primaryBg,
      style: ConstFonts.normal(size: 14, color: ConstColor.primaryColor),
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: ConstFonts.normal(size: 14, color: ConstColor.primaryColor),
        prefixIcon: Icon(Icons.wc_rounded, color: accentColor),
        filled: true,
        fillColor: accentColor.withAlpha(10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── Save Button ─────────────────────────────────────────────────────────

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accentColor.withAlpha(120),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }
}
