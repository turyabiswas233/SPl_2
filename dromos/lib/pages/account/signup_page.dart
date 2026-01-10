import 'package:dromos/components/select_box.dart';
import 'package:dromos/pages/account/signup_page2.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/id_card_parser.dart';
import 'package:flutter/material.dart';
import 'package:dromos/components/custom_input.dart';
import 'package:dromos/services/ocr_service.dart';
import 'package:dromos/models/id_card_info.dart';
import 'package:image_picker/image_picker.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupPage> {
  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple;

  // Controllers for form fields
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _hallController = TextEditingController();
  final TextEditingController _sessionController = TextEditingController();

  bool _hasScannedId = false;
  bool _isScanning = false;

  // OCR Service instance
  late final OcrService _ocrService;

  @override
  void initState() {
    super.initState();
    _ocrService = OcrService();
    // Prompt to scan ID card when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptScanIdCard();
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _registrationController.dispose();
    _nameController.dispose();
    _genderController.dispose();
    _departmentController.dispose();
    _sessionController.dispose();
    _hallController.dispose();
    super.dispose();
  }

  Future<void> _promptScanIdCard() async {
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Scan ID Card',
            style: ConstFonts.bold(size: 20, color: accentColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please scan both side of your DU ID card to auto-fill registration details.',
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
                'Fill Manually',
                style: ConstFonts.normal(size: 14, color: Colors.white),
              ),
              icon: const Icon(Icons.edit, color: Colors.white),
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
        await _scanBothSides(ImageSource.camera);
      } else if (result == 'gallery') {
        await _scanBothSides(ImageSource.gallery);
      }
    }
  }

  Future<void> _scanBothSides(ImageSource source) async {
    setState(() {
      _isScanning = true;
    });

    try {
      // Scan front side
      final frontImagePath = await _ocrService.scanImageOnly(source: source);

      if (frontImagePath == null) {
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
          _showErrorDialog('No image captured for front side', [
            'Please try again and capture the front side of your ID card',
          ]);
        }
        return;
      }

      // Process front side
      final frontResult = await _ocrService.processImage(frontImagePath);

      if (mounted && frontResult.success && frontResult.data != null) {
        _fillFormWithIdCardInfo(frontResult.data!);

        // Prompt for back side
        final scanBackMethod = await _showScanBackSideDialog();

        if (scanBackMethod != null && scanBackMethod != 'skip') {
          // Determine source based on user choice
          final backSource = scanBackMethod == 'camera'
              ? ImageSource.camera
              : ImageSource.gallery;

          // Scan back side
          final backImagePath = await _ocrService.scanImageOnly(
            source: backSource,
          );

          if (backImagePath != null) {
            // Process back side for debug only
            await _ocrService.processImageForUniqueCode(
              backImagePath,
              'ID Card Back Side',
            );

            bool isValid = false;

            IdCardParser.isValidUniqueCode(_registrationController.text).then((
              isValid,
            ) {
              if (isValid) {
                debugPrint('VALID.');
                isValid = true;
              } else {
                debugPrint('INVALID.');
                isValid = false;
              }
            });

            // Validate user (unique code / registration) and show status-specific info
            final bool validUser = await IdCardParser.isValidUniqueCode(
              _registrationController.text.trim(),
            );

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
              content: Text(
                validUser
                  ? 'Both sides scanned successfully! Your ID has been verified.'
                  : 'Both sides scanned successfully, but verification failed. Please re-check your Registration No. or re-scan the back side.',
                style: ConstFonts.normal(size: 14, color: Colors.white),
              ),
              backgroundColor: validUser ? Colors.green : Colors.orange,
              action: validUser
                ? null
                : SnackBarAction(
                  label: 'Re-scan',
                  textColor: Colors.white,
                  onPressed: _promptScanIdCard,
                  ),
              ),
            );
          }
        }

        setState(() {
          _hasScannedId = true;
          _isScanning = false;
        });
      } else if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _showErrorDialog(
          frontResult.errorMessage ?? 'Failed to scan ID card',
          frontResult.tips,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        _showErrorDialog('Unexpected error: ${e.toString()}', [
          'Please try again or fill the form manually',
        ]);
      }
    }
  }

  Future<String?> _showScanBackSideDialog() async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Scan Back Side',
            style: ConstFonts.bold(size: 18, color: accentColor),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scan back side of your ID card?\n\n(Optional - for verification purposes)',
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
              label: Text(
                'Use Camera',
                style: ConstFonts.normal(size: 14, color: accentColor),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                backgroundColor: Colors.white,
                side: BorderSide(color: accentColor),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop('skip'),
              icon: const Icon(Icons.skip_next, color: Colors.white),
              label: Text(
                'Skip',
                style: ConstFonts.normal(size: 14, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message, List<String>? tips) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Fill Manually',
                style: ConstFonts.normal(size: 14, color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _promptScanIdCard(); // Retry with options
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
              child: Text(
                'Try Again',
                style: ConstFonts.normal(size: 14, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _fillFormWithIdCardInfo(IdCardInfo info) {
    if (info.registrationNumber != null) {
      _registrationController.text = info.registrationNumber!;
    }

    if (info.name != null) {
      _nameController.text = info.name!;
    }

    if (info.department != null) {
      setState(() {
        _departmentController.text = info.department!;
      });
    }

    if (info.hall != null) {
      setState(() {
        _hallController.text = info.hall!;
      });
    }

    if (info.session != null) {
      _sessionController.text = info.session!;
    }

    // Show success message
    if (mounted && info.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ID card scanned successfully! Please verify the information.',
            style: ConstFonts.normal(size: 14, color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // The dark background from the image
      backgroundColor: pbc,
      appBar: AppBar(
        title: const Text(
          "Dromos - Signup",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        bottomOpacity: 0,
        elevation: 0,
        leading: BackButton(
          color: accentColor,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (!_isScanning)
            IconButton(
              icon: Icon(Icons.document_scanner, color: accentColor),
              tooltip: 'Scan ID Card',
              onPressed: _promptScanIdCard,
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.only(bottom: 32, left: 10, right: 10),
                decoration: BoxDecoration(color: pbc),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Welcome to",
                            style: ConstFonts.normal(size: 32, color: pc),
                          ),
                          Text(
                            "Dromos",
                            style: ConstFonts.bold(
                              color: accentColor,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Step 1 of 2",
                            style: ConstFonts.bold(
                              color: accentColor,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    CustomInput(
                      title: "Registration Number",
                      hint: "2022******",
                      icon: Icons.numbers,
                      initialValue: _registrationController.text,
                      controller: _registrationController,
                    ),
                    const SizedBox(height: 16.0),
                    CustomInput(
                      title: "Name",
                      hint: "John Doe",
                      icon: Icons.person,
                      initialValue: "",
                      controller: _nameController,
                    ),
                    const SizedBox(height: 16.0),
                    // department input
                    CustomInput(
                      title: "Department",
                      hint: "e.g: Department of Physics",
                      initialValue: _departmentController.text,
                      controller: _departmentController,
                      isPassword: false,
                      icon: Icons.school_rounded,
                    ),
                    const SizedBox(height: 16.0),
                    // hall input
                    CustomInput(
                      title: "Attached Hall",
                      hint: "Enter your hall name",
                      initialValue: _hallController.text,
                      controller: _hallController,
                    ),
                    const SizedBox(height: 16.0),
                    // session key
                    CustomInput(
                      title: "Session (eg. 22-23)",
                      hint: "22-23",
                      icon: Icons.key_rounded,
                      initialValue: "",
                      controller: _sessionController,
                    ),
                    const SizedBox(height: 16.0),
                    // signup Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate required fields
                          if (_registrationController.text.isEmpty ||
                              _nameController.text.isEmpty ||
                              _departmentController.text.isEmpty ||
                              _hallController.text.isEmpty ||
                              _sessionController.text.isEmpty) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: Text(
                                    "Missing Information",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: pc,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    "Please fill in all required fields before proceeding",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        "Got it",
                                        style: ConstFonts.light(
                                          color: Colors.green.shade700,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                            return;
                          }

                          // Navigate to second signup page with data
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignupPage2(
                                userData: {
                                  'registration': _registrationController.text,
                                  'name': _nameController.text,
                                  'gender': _genderController.text,
                                  'department': _departmentController.text,
                                  'hall': _hallController.text,
                                  'session': _sessionController.text,
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Next",
                              style: ConstFonts.normal(
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isScanning)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scanning ID Card...',
                        style: ConstFonts.normal(size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
