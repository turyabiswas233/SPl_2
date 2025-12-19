import 'package:dromos/pages/account/login_page.dart';
import 'package:dromos/pages/account/signup_page.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/colors.dart';

class User {
  final String name;
  final int age;

  User(this.name, this.age);

  @override
  String toString() => 'User(name: $name, age: $age)';
}

class Fonts {
  final String name;
  final FontWeight weight;

  Fonts(this.name, this.weight);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _HomeScreen(context);
  }
}

class _HomeScreen extends HomeScreen {
  final BuildContext context;

  _HomeScreen(this.context);

  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color secondaryColor = ConstColor.primaryPurple;


  late final List<SizedBox> buttons = [
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Handle Login
          debugPrint("login page");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const LoginPage();
              },
            ),
          );
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
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Handle Login
          debugPrint("signup page");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const SignupPage();
              },
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: const Text(
          "Sign up",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w600, // poppins-semibold
          ),
        ),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pbc,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              spacing: 0,
              children: [
                const SizedBox(height: 200),
                Column(
                  children: [
                    Text(
                      "Dromos",
                      textAlign: TextAlign.center,
                      style: ConstFonts.bold(color: secondaryColor, size: 64),
                    ),
                    Text(
                      "Smart Simple Sustainable",
                      textAlign: TextAlign.center,
                      style: ConstFonts.normal(size: 24, color: pc),
                    ),
                  ],
                ),

                Container(
                  margin: EdgeInsets.only(top: 150),
                  padding: const EdgeInsets.all(24),
                  child: Column(spacing: 24, children: [...buttons]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
