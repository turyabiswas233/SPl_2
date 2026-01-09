import 'package:dromos/components/custom_input.dart';
import 'package:dromos/pages/account/signup_page.dart';

// Import the new MainScreen
import 'package:dromos/screens/main_screen.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:dromos/utils/info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple;

  // --- LOGIN LOGIC FUNCTION ---
  void _handleLogin(BuildContext context) {
    // For now, this is a "demo" login. We are not validating credentials.
    // In a real app, you would validate _emailController.text and _passwordController.text
    // against a database or authentication service here.

    debugPrint("Attempting login...");
    debugPrint("Email: ${_emailController.text}");
    debugPrint("Email: ${_passwordController.text}");
    debugPrint("Remember me: $rememberMe");
    const String email = ConstInfo.email;
    const String password = ConstInfo.password;

    if (email == _emailController.text &&
        password == _passwordController.text) {
      debugPrint("Login Successful");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Login Successful",
              textAlign: TextAlign.center,
              style: TextStyle(color: pc, fontWeight: FontWeight.bold),
            ),
            content: Text("Welcome, ${ConstInfo.userName}"),
            backgroundColor: Colors.white,
            icon: Icon(Icons.error),
            iconColor: accentColor,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Ok",
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
      // settimeout
      Future.delayed(const Duration(seconds: 2), () {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (Route<dynamic> route) =>
                false, // This predicate removes all previous routes
          );
        }
      });
    } else if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: Text(
              "Login Attempt Failed",
              textAlign: TextAlign.center,
              style: TextStyle(color: pc, fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Fill up both email and password to login the system",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  debugPrint("Missing fields");
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
    } else {
      debugPrint("Login Failed");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Login Attempt Failed",
              textAlign: TextAlign.center,
              style: TextStyle(color: pc, fontWeight: FontWeight.bold),
            ),
            content: Text("Invalid Credentials. Please try again."),
            backgroundColor: pbc,
            icon: Icon(Icons.error),
            iconColor: accentColor,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Close",
                  style: ConstFonts.light(color: Colors.red, size: 14),
                ),
              ),
            ],
          );
        },
      );
    }
    return;
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

                // Google and Facebook Buttons
                // _SocialLoginButton(
                //   text: "Login with Google",
                //   svgData: googleSvgData,
                //   onTap: () {
                //     showDialog(
                //       context: context,
                //       builder: (BuildContext context) {
                //         return AlertDialog(
                //           title: Text(
                //             "Login-BTN - Google",
                //             textAlign: TextAlign.center,
                //             style: TextStyle(
                //               color: pc,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //           backgroundColor: pbc,
                //           icon: Icon(Icons.info_outline),
                //           iconColor: accentColor,
                //           actions: [
                //             TextButton(
                //               onPressed: () {
                //                 Navigator.of(context).pop();
                //               },
                //               child: Text(
                //                 "Close",
                //                 style: ConstFonts.light(
                //                   color: Colors.red,
                //                   size: 14,
                //                 ),
                //               ),
                //             ),
                //           ],
                //         );
                //       },
                //     );
                //   },
                // ),
                // const SizedBox(height: 16.0),
                // _SocialLoginButton(
                //   text: "Login with Facebook",
                //   svgData: facebookSvgData,
                //   onTap: () {
                //     showDialog(
                //       context: context,
                //       builder: (BuildContext context) {
                //         return AlertDialog(
                //           title: Text(
                //             "Login-BTN - FB",
                //             style: TextStyle(
                //               color: pc,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //           icon: Icon(Icons.info_outline),
                //           iconColor: accentColor,
                //           backgroundColor: pbc,
                //           actions: [
                //             TextButton(
                //               onPressed: () {
                //                 Navigator.of(context).pop();
                //               },
                //               child: Text(
                //                 "Close",
                //                 style: ConstFonts.light(
                //                   color: Colors.red,
                //                   size: 14,
                //                 ),
                //               ),
                //             ),
                //           ],
                //         );
                //       },
                //     );
                //   },
                // ),
                // const SizedBox(height: 24.0),
                //
                // // "OR" Divider
                // const _OrDivider(),
                // const SizedBox(height: 24.0),

                // Email and Password Fields
                // Assign the controllers to the CustomInput widgets
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
                const SizedBox(height: 16.0),
                // ... (Your existing code for Remember me, etc.)

                // Remember Me Checkbox
                Row(
                  children: [
                    Checkbox(
                      activeColor: accentColor,
                      value: rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          rememberMe = value ?? false;
                        });
                      },
                    ),
                    Text("Remember me", style: ConstFonts.normal(color: pc)),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    // Call the _handleLogin function when pressed
                    onPressed: () => _handleLogin(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600, // poppins-semibold
                          ),
                        ),
                        Icon(Icons.login, color: pbc),
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

// ... (Your helper widgets _SocialLoginButton and _OrDivider remain the same)
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
