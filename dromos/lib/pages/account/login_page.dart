import 'dart:convert';
import 'package:dromos/utils/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:dromos/components/custom_input.dart';
import 'package:dromos/pages/account/signup_page.dart';
import 'package:dromos/screens/main_screen.dart';
import 'package:dromos/services/user_service.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/api.dart';

// --- SVG Icon Data ---
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
  // Add controllers to get the text from the input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool rememberMe = false;
  bool _isLoading = false;

  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple;

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
              style: ButtonStyle(
                overlayColor: WidgetStateProperty.all(Colors.redAccent.withAlpha(50)),
              ),
              child: Text(
                "Got it",
                style: ConstFonts.light(color: Colors.red.shade700, size: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToMainScreen() async {
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // --- LOGIN LOGIC FUNCTION ---
  Future<void> _handleLogin(BuildContext context) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog(
        "Missing Information",
        "Fill up both email and password to login the system",
      );
      return;
    }

    setState(() => _isLoading = true);
 
    try {
      final body = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      };

      final response = await http
          .post(
            Uri.parse('${Api.url}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          // Save session & fetch full profile
          final token = responseData['data']?['token'] ?? '';
          final userId = responseData['data']?['user']?['user_id'] ?? '';

          final userService = UserService();
          await userService.saveSession(token: token, userId: userId);
          await userService.fetchProfile();

          // Navigate to main screen
          _navigateToMainScreen();
        } else {
          NotificationController.createNewNotification(
            id: -1,
            body:
                "Invalid Credentials. Please check your internet connection and try again.",
            title: "Login Failed",
            payload: "login_failed",
          );
          _showErrorDialog(
            "Login Failed",
            responseData['message'] ??
                "Invalid credentials. Please check your internet connection and try again.",
          );
        }
      } else {
        NotificationController.createNewNotification(
          id: -1,
          body:
              "Invalid Credentials. Please check your internet connection and try again.",
          title: "Login Failed",
          payload: "login_failed",
        );
        _showErrorDialog(
          "Login Failed",
          responseData['message'] ??
              "Invalid Credentials. Please check your internet connection and try again.",
        );
      }
    } catch (e) {
      debugPrint('Login error: $e');
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
  void dispose() {
    // Dispose controllers to free up resources
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBodyBehindAppBar: true,
      // The dark background from the image
      backgroundColor: pbc,
      appBar: AppBar(
        title: const Text(
          "Dromos - Login",
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                        style: ConstFonts.bold(color: accentColor, size: 48),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32.0),

                CustomInput(
                  title: "Email",
                  hint: "example@gmail.com",
                  icon: Icons.email_rounded,
                  initialValue: "",
                  controller: _emailController, // Assign controller
                ),
                const SizedBox(height: 16.0),
                CustomInput(
                  title: "Password",
                  hint: "**********",
                  initialValue: "",
                  icon: Icons.key_sharp,
                  controller: _passwordController,
                  // Assign controller
                  isPassword: true,
                ),
                const SizedBox(height: 26.0),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      overlayColor: pbc.withAlpha(20),
                      disabledBackgroundColor: accentColor.withAlpha(100),
                      disabledIconColor: accentColor.withAlpha(200),
                      iconSize: 20,
                      iconColor: pbc,
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
                            spacing: 10,
                            children: [
                              const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Icon(Icons.login),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Forgot Password?
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: accentColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Don't have an account? Register
                Row(
                  // Use mainAxisAlignment to center the content
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: pc),
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
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
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
