import 'dart:convert';
import 'package:dromos/components/custom_input.dart';
import 'package:dromos/screens/main_screen.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/api.dart';
import 'package:http/http.dart' as http;

class SignupPage2 extends StatefulWidget {
  final Map<String, String> userData;

  const SignupPage2({super.key, required this.userData});

  @override
  State<SignupPage2> createState() => _SignupPage2State();
}

class _SignupPage2State extends State<SignupPage2> {
  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple;

  // Controllers for form fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: pc, fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Got it",
                style: ConstFonts.light(color: Colors.green.shade700, size: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    // Validate fields
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showErrorDialog(
        "Missing Information",
        "Please fill in all required fields (Email, Password, Confirm Password, and Phone)",
      );
      return;
    }

    // Validate password match
    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog(
        "Password Mismatch",
        "Password and Confirm Password do not match",
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _showErrorDialog("Invalid Email", "Please enter a valid email address");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Build the registration payload from both steps
      final body = {
        'fullName': widget.userData['name'] ?? '',
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'phoneNumber': _phoneController.text.trim(),
        'registrationNumber': widget.userData['registration'] ?? '',
        'deptName': widget.userData['department'] ?? '',
        'hallName': widget.userData['hall'] ?? '',
        'gender': widget.userData['gender'] ?? '',
      };

      final response = await http.post(
        Uri.parse('${Api.url}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      final responseData = jsonDecode(response.body);
      debugPrint(responseData.toString());

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          // Save session & fetch full profile
          final token = responseData['data']?['token'] ?? '';
          final userId = responseData['data']?['user']?['user_id'] ?? '';

          final userService = UserService();
          await userService.saveSession(token: token, userId: userId);
          await userService.fetchProfile();

          if (!mounted) return;

          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext ctx) {
              return AlertDialog(
                title: Text(
                  "Account Created Successfully!",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: pc, fontWeight: FontWeight.bold),
                ),
                content: Text("Welcome to Dromos, ${widget.userData['name']}!"),
                backgroundColor: Colors.white,
                icon: const Icon(Icons.check_circle),
                iconColor: Colors.green,
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const MainScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: Text(
                      "Continue",
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
        } else {
          _showErrorDialog(
            "Registration Failed",
            responseData['message'] ??
                "Something went wrong. Please try again.",
          );
        }
      } else {
        debugPrint("Registration failed: ${response.statusCode}");
        _showErrorDialog(
          "Registration Failed",
          responseData['message'] ??
              "Server error (${response.statusCode}). Please try again.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        "Connection Error",
        "Could not connect to server. Please check your internet connection and try again.",
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pbc,
      appBar: AppBar(
        title: const Text(
          "Complete Registration",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
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
                        "Almost Done!",
                        style: ConstFonts.light(size: 32, color: pc),
                      ),
                      Text(
                        "Step 2 of 2",
                        style: ConstFonts.semibold(
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32.0),

                // Email Field
                CustomInput(
                  title: "Email",
                  hint: "example@gmail.com",
                  icon: Icons.email_rounded,
                  controller: _emailController,
                  initialValue: "",
                ),
                const SizedBox(height: 16.0),

                // Phone Field
                CustomInput(
                  title: "Phone Number",
                  hint: "017********",
                  icon: Icons.phone,
                  initialValue: "",
                  controller: _phoneController,
                ),
                const SizedBox(height: 16.0),

                // Password Field
                CustomInput(
                  title: "Password",
                  hint: "**********",
                  icon: Icons.key_rounded,
                  controller: _passwordController,
                  initialValue: "",
                  isPassword: true,
                ),
                const SizedBox(height: 16.0),
                // Confirm Password Field
                CustomInput(
                  title: "Confirm Password",
                  hint: "**********",
                  icon: Icons.key_rounded,
                  controller: _confirmPasswordController,
                  initialValue: "",
                  isPassword: true,
                ),
                const SizedBox(height: 32.0),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99.0),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Complete Registration",
                                style: ConstFonts.normal(
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check_circle,
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
      ),
    );
  }
}
