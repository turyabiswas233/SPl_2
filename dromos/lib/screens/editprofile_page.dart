import 'package:dromos/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/colors.dart';

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
  static const Color maleColor = Colors.lightBlue;
  static const Color femaleColor = Colors.purpleAccent;

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _deptCtrl;
  late final TextEditingController _hallCtrl;
  String _selectedGender = '';

  @override
  void initState() {
    super.initState();
    final user = _userService.currentUser;
    _fullNameCtrl = TextEditingController(text: user.fullName);
    _phoneCtrl = TextEditingController(text: user.phoneNumber);
    _deptCtrl = TextEditingController(text: user.deptName);
    _hallCtrl = TextEditingController(text: user.hallName);
    _selectedGender = user.gender;

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
      _selectedGender = user.gender;
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
      gender: _selectedGender.toLowerCase(),
    );
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile updated successfully!'
                : 'Failed to update profile.',
          ),
          backgroundColor: success ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
        backgroundColor: Colors.transparent,
        foregroundColor: fColor,
        elevation: 0,
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
    final user = _userService.currentUser;
    final isVerified = user.verificationStatus.toLowerCase() == 'verified';
    Color genderColor = user.gender.toLowerCase() == 'male'
        ? maleColor
        : femaleColor;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: genderColor.withAlpha(30),
              child: Icon(
                user.gender == 'male'
                    ? Icons.person_rounded
                    : Icons.person_2_rounded,
                size: 50,
                color: genderColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: bColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isVerified ? Icons.verified_rounded : Icons.pending_outlined,
                size: 22,
                color: isVerified ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isVerified
                ? Colors.green.withAlpha(25)
                : Colors.orange.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isVerified ? 'Verified' : 'Unverified',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isVerified
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ),
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
      style: const TextStyle(fontSize: 15, color: fColor),
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '—',
                  style: TextStyle(
                    fontSize: 15,
                    color: fColor.withAlpha(180),
                    fontWeight: FontWeight.w500,
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
    final genders = ['male', 'female', 'other'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.wc_rounded, color: accentColor, size: 22),
          const SizedBox(width: 8),
          Text(
            'Gender',
            style: TextStyle(fontSize: 15, color: fColor.withAlpha(140)),
          ),
          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: RadioGroup<int>(
              groupValue: genders.indexOf(_selectedGender),
              onChanged: (int? value) {
                setState(() {
                  _selectedGender = genders[value!];
                });
              },
              child: Row(
                children: List.generate(genders.length, (index) {
                  return Row(
                    children: [
                      Radio<int>(value: index),
                      Text(
                        genders[index].replaceFirst(
                          genders[index][0],
                          genders[index][0].toUpperCase(),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
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
