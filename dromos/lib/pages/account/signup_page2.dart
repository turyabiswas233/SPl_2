import 'package:dromos/components/custom_input.dart';
import 'package:dromos/screens/main_screen.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';

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
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // Validate fields
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              "Missing Information",
              textAlign: TextAlign.center,
              style: TextStyle(color: pc, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Please fill in all required fields (Email, Password, and Phone)",
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

    // Show success dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                Navigator.of(context).pop();
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

    // Navigate to MainScreen after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
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
                        style: ConstFonts.normal(size: 32, color: pc),
                      ),
                      Text(
                        "Step 2 of 2",
                        style: ConstFonts.bold(
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
                const SizedBox(height: 32.0),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
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
                          "Complete Registration",
                          style: ConstFonts.normal(
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
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
