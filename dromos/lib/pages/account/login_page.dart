import 'package:dromos/components/_customInput.dart';
import 'package:dromos/pages/account/signup_page.dart';
import 'package:dromos/pages/home/home_page.dart';
import 'package:dromos/utils/_colors.dart';
import 'package:dromos/utils/_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// --- SVG Icon Data ---
// Extracted from your React component
const String googleSvgData = '''
<svg width="36" height="32" viewBox="0 0 36 32" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M7.78827 19.2871L6.56502 23.4344L2.09406 23.5203C0.757893 21.2696 0 18.6944 0 15.9579C0 13.3117 0.708612 10.8163 1.96467 8.61902H1.96564L5.94605 9.28177L7.68971 12.875C7.32477 13.8413 7.12586 14.8786 7.12586 15.9579C7.12599 17.1293 7.35963 18.2517 7.78827 19.2871Z" fill="#FBBB00"/>
  <path d="M34.8354 12.9767C35.0372 13.942 35.1424 14.9389 35.1424 15.9578C35.1424 17.1003 35.0101 18.2147 34.7582 19.2897C33.9028 22.9478 31.6678 26.142 28.5716 28.4024L28.5707 28.4015L23.5571 28.1692L22.8475 24.1463C24.902 23.0521 26.5076 21.3397 27.3533 19.2897H17.9576V12.9767H27.4904H34.8354Z" fill="#518EF8"/>
  <path d="M28.5706 28.4015L28.5716 28.4024C25.5604 30.6005 21.7353 31.9157 17.5713 31.9157C10.8798 31.9157 5.06203 28.519 2.09422 23.5203L7.78844 19.2871C9.27231 22.8837 13.0926 25.4441 17.5713 25.4441C19.4964 25.4441 21.2999 24.9714 22.8475 24.1464L28.5706 28.4015Z" fill="#28B446"/>
  <path d="M28.7869 3.67381L23.0946 7.90615C21.493 6.99692 19.5997 6.47168 17.5713 6.47168C12.9912 6.47168 9.09948 9.14943 7.68995 12.875L1.9658 8.61902H1.96484C4.8892 3.49846 10.7803 0 17.5713 0C21.8347 0 25.7438 1.37924 28.7869 3.67381Z" fill="#F14336"/>
</svg>
''';

const String facebookSvgData = '''
<svg width="16" height="32" viewBox="0 0 16 32" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M13.0789 5.31333H16V0.225333C15.496 0.156 13.7629 0 11.7444 0C2.50246 0 5.01692 10.4667 4.64895 12H0V17.688H4.64761V32H10.3458V17.6893H14.8054L15.5134 12.0013H10.3445C10.5951 8.236 9.32989 5.31333 13.0789 5.31333Z" fill="#3B5999"/>
</svg>
''';
// --- End SVG Icon Data ---

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginPage> {
  bool _rememberMe = false;
  ConstColor cc = ConstColor();
  late Map<int, Color> light = cc.light();
  late Map<int, Color> dark = cc.dark();

  @override
  Widget build(BuildContext context) {
    late final Color? primaryColor =
        MediaQuery.of(context).platformBrightness == Brightness.light
        ? light[1]
        : dark[1];
    late final Color? bgCol =
        MediaQuery.of(context).platformBrightness == Brightness.light
        ? light[2]
        : dark[2];
    late final Color secondaryColor = ConstColor.primaryPurple;

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
                const SizedBox(height: 32.0),

                // Google and Facebook Buttons
                _SocialLoginButton(
                  text: "Login with Google",
                  svgData: googleSvgData,
                  onTap: () {
                    // Handle Google login
                    // show alwrt to login with google
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            "Login-BTN - Google",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: bgCol,
                          icon: Icon(Icons.info_outline),
                          iconColor: secondaryColor,
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                "Close",
                                style: ConstFonts.light(
                                  color: Colors.red,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16.0),
                _SocialLoginButton(
                  text: "Login with Facebook",
                  svgData: facebookSvgData,
                  onTap: () {
                    // Handle Facebook login
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text(
                            "Login-BTN - FB",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          icon: Icon(Icons.info_outline),
                          iconColor: secondaryColor,
                          backgroundColor: bgCol,
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                "Close",
                                style: ConstFonts.light(
                                  color: Colors.red,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 24.0),

                // "OR" Divider
                const _OrDivider(),
                const SizedBox(height: 24.0),

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
                  icon: Icons.key_sharp,
                  controller: TextEditingController(),
                  isPassword: true,
                ),
                const SizedBox(height: 16.0),

                // Remember Me Checkbox
                Row(
                  children: [
                    Checkbox(
                      activeColor: secondaryColor,
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    Text(
                      "Remember me",
                      style: ConstFonts.normal(color: primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

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
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600, // poppins-semibold
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    // Forgot Password?
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: secondaryColor),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),

                // Don't have an account? Register
                Row(
                  spacing: 5,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(color: primaryColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              return const SignupPage();
                            },
                          ),
                        );
                      },
                      child: Text(
                        "Register",
                        style: TextStyle(color: secondaryColor),
                      ),
                    ),
                  ],
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
                  fontSize: 14,
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

// Helper Widget for the "OR" Divider
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.grey)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text("OR", style: TextStyle(color: Colors.grey[600])),
        ),
        const Expanded(child: Divider(color: Colors.grey)),
      ],
    );
  }
}
