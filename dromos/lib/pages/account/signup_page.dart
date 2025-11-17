import 'package:dromos/pages/account/login_page.dart';
import 'package:dromos/utils/_colors.dart';
import 'package:dromos/utils/_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dromos/components/_customInput.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupPage> {
  bool _rememberMe = false;
  ConstColor cc = ConstColor();
  late Map<int, Color> light = cc.light();
  late Map<int, Color> dark = cc.dark();

  late final Color? primaryColor =
      MediaQuery.of(context).platformBrightness == Brightness.light
      ? light[1]
      : dark[1];
  late final Color? bgCol =
      MediaQuery.of(context).platformBrightness == Brightness.light
      ? light[2]
      : dark[2];
  late final Color secondaryColor = ConstColor.primaryPurple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The dark background from the image
      backgroundColor: bgCol,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(
              top: 32,
              bottom: 32,
              left: 10,
              right: 10,
            ),
            decoration: BoxDecoration(color: bgCol),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                // Header
                Text(
                  "Welcome to",
                  style: ConstFonts.normal(size: 32, color: primaryColor),
                ),
                Text(
                  "Dromos",
                  style: ConstFonts.bold(color: secondaryColor, size: 48),
                ),
                const SizedBox(height: 16.0),

                // Email and Password Fields
                CustomInput(
                  title: "Email",
                  hint: "example@gmail.com",
                  icon: Icons.email_rounded,
                  controller: TextEditingController(),
                ),
                const SizedBox(height: 16.0),
                CustomInput(
                  title: "Password",
                  hint: "**********",
                  icon: Icons.lock_outline,
                  controller: TextEditingController(),
                  isPassword: true,
                ),
                const SizedBox(height: 16.0),
                CustomInput(
                  title: "Registration Number",
                  hint: "2022******",
                  icon: Icons.numbers,
                  controller: TextEditingController(),
                ),
                const SizedBox(height: 16.0),
                CustomInput(
                  title: "Name",
                  hint: "John Doe",
                  icon: Icons.person,
                  controller: TextEditingController(),
                ),
                const SizedBox(height: 16.0),
                const SizedBox(height: 16.0),
                CustomInput(
                  title: "Phone Number",
                  hint: "015********",
                  icon: Icons.phone,
                  controller: TextEditingController(),
                ),
                const SizedBox(height: 16.0),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle Login
                      debugPrint("Remember me: $_rememberMe");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      "Sign up",
                      style: ConstFonts.normal(size: 14, color: Colors.white),
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

// Helper Widget for Social Login Buttons (like your GoogleLoginBtn)
class _SocialLoginButton extends StatelessWidget {
  final String text;
  final String svgData;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.text,
    required this.svgData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      color: Colors.white,
      shadowColor: Colors.grey.withAlpha(100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.string(svgData, height: 32.0),
              const SizedBox(width: 16.0),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
