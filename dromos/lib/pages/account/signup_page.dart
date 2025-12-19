import 'package:dromos/components/select_box.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';
import 'package:dromos/components/custom_input.dart';
import 'package:flutter/services.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupPage> {
  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // The dark background from the image
      backgroundColor: pbc,
      appBar: AppBar(
        title: const Text(
          "Dromos - Signup",
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
                  icon: Icons.key_rounded,
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
                // dept and hall select box
                SelectBox(
                  id: 'department',
                  label: 'Department',
                  options: List<String>.from([
                    'Computer Science Engineering',
                    'Electrical and Electronics Engineering',
                    'Physics',
                    'Chemistry',
                    'Applied Mathematics',
                    'Applied Statistics',
                    'Software Engineering',
                    'Economics',
                    'Psychology',
                    'Biology',
                  ]),
                  selectedOption: 'Software Engineering',
                  onChange: (String value) {
                    debugPrint('Selected Department: $value');
                  },
                ),
                SelectBox(
                  id: 'hall',
                  label: 'Attached Hall',
                  options: List<String>.from([
                    'Amar Ekushey Hall',
                    'Fazlul Huq Hall',
                    'Shahidullah Hall',
                    'Sufia kamal Hall',
                    'Jagannath Hall',
                    'Begum Rokeya Hall',
                    'Bangabandhu Sheikh Mujibur Rahman Hall',
                  ]),
                  selectedOption: 'Amar Ekushey Hall',
                  onChange: (String value) {
                    debugPrint('Selected Department: $value');
                  },
                ),
                // session key
                CustomInput(
                  title: "Session (eg. 22-23)",
                  hint: "22-23",
                  icon: Icons.key_rounded,
                  controller: TextEditingController(),
                ),
                const SizedBox(height: 16.0),
                // signup Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle Login
                      debugPrint("new account created");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
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
