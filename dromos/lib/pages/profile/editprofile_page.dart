import 'package:dromos/services/ocr_service.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/id_card_parser.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/colors.dart';
import 'package:image_picker/image_picker.dart';

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

  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _deptCtrl;
  late final TextEditingController _hallCtrl;
  late final OcrService _ocrService;
  String _selectedGender = '';

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
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
    _ocrService.dispose();
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
                  'Fill Manually',
                  style: ConstFonts.normal(size: 14, color: ConstColor.error),
                ),
              ),
            ],
          );
        },
      );
    }

    Future<void> scanBothSides(ImageSource source) async {
      try {
        // Scan back side
        final backImagePath = await _ocrService.scanImageOnly(source: source);

        if (backImagePath == null) {
          if (mounted) {
            showErrorDialog('No image captured for back side', [
              'Please try again and capture the back side of your ID card',
            ]);
          }
          return;
        }
        setState(() {
          _isLoading = true;
        });
        // Process back side
        await _ocrService.processImageForUniqueCode(
          backImagePath,
          "unique id check",
        );

        IdCardParser.isValidUniqueCode(
          UserService().currentUser.registrationNumber,
        ).then((isValid) {
          if (isValid) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ID card verified successfully!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            );
            _refreshProfile();
          } else {
            if (mounted) {
              showErrorDialog('Invalid Unique ID extracted from the card', [
                'Please ensure you are scanning the back side of a valid DU ID card',
                'Try adjusting the distance and lighting for better results',
              ]);
            }
          }
        });
      } catch (e) {
        if (mounted) {
          showErrorDialog('Unexpected error: ${e.toString()}', [
            'Please try again or fill the form manually',
          ]);
        }
        setState(() {
          _isLoading = false;
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    Future<void> promptScanIdCard() async {
      final result = await showDialog<String?>(
        context: context,
        barrierDismissible: true,
        animationStyle: AnimationStyle(
          curve: Curves.easeInOut,
          duration: const Duration(milliseconds: 300),
        ),
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,

            title: Text(
              'Scan ID Card',
              style: ConstFonts.bold(size: 20, color: accentColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please scan back side of your DU ID card to get student Unique Id.',
                  style: ConstFonts.normal(size: 14, color: pc),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose scanning method:',
                  style: ConstFonts.bold(size: 13, color: accentColor),
                ),
              ],
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop('gallery'),
                icon: const Icon(Icons.photo_library),
                label: Text(
                  'Upload Image',
                  style: ConstFonts.normal(size: 14, color: accentColor),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: accentColor),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop('camera'),
                icon: const Icon(Icons.camera_alt),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: accentColor),
                ),
                label: Text(
                  'Use Camera',
                  style: ConstFonts.normal(size: 14, color: accentColor),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // exit ocr card
                  Navigator.of(context).pop();
                },
                label: Text(
                  'Cancel',
                  style: ConstFonts.normal(size: 14, color: Colors.white),
                ),
                icon: const Icon(Icons.close, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor.withAlpha(230),
                ),
              ),
            ],
          );
        },
      );

      if (result != null && mounted) {
        if (result == 'camera') {
          await scanBothSides(ImageSource.camera);
        } else if (result == 'gallery') {
          await scanBothSides(ImageSource.gallery);
        }
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
              debugPrint("hi");
              // from service/ocr_service.dart get student unique id and send to verification page
              await promptScanIdCard();
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
