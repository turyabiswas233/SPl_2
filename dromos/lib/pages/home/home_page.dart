import 'package:dromos/utils/_fonts.dart';
import 'package:dromos/utils/noti.dart';
import 'package:flutter/material.dart';
import 'package:dromos/utils/_colors.dart';

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
    return _HomeScreen().build(context);
  }
}

class _HomeScreen extends HomeScreen {
  _HomeScreen({super.key});

  final List<SizedBox> buttons = [
    SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Handle Login
          debugPrint("login page");
          NotiService().showNotification(
            id: DateTime.now().microsecondsSinceEpoch % 1000,
            title: "Visitng Login Page",
            body: "User pressed the login button",
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: ConstColor.primary_purple,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
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
          NotiService().showNotification(
            id: DateTime.now().microsecondsSinceEpoch % 1000,
            title: "Visitng Signup Page",
            body: "User pressed the signup button",
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: ConstColor.primary_purple,
          padding: const EdgeInsets.symmetric(vertical: 16.0),
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
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white),
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
                      style: ConstFonts.bold(
                        color: ConstColor.primary_purple,
                        size: 64,
                      ),
                    ),
                    Text(
                      "Smart Simple Sustainable",
                      textAlign: TextAlign.center,
                      style: ConstFonts.normal(size: 24),
                    ),
                  ],
                ),

                Container(
                  margin: EdgeInsets.only(top: 150),
                  padding: const EdgeInsets.all(24),
                  child: Column(spacing: 24, children: buttons),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TestFontScreen {
  final List<Fonts> fonts = [
    Fonts("thin", FontWeight.w300),
    Fonts("light", FontWeight.w400),
    Fonts("regular", FontWeight.w500),
    Fonts("medium", FontWeight.w600),
    Fonts("semibold", FontWeight.w700),
    Fonts("bold", FontWeight.w700),
  ];

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ConstColor.primary_color,
        title: const Text(
          'Home Page',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
            fontFamily: "Poppins",
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Welcome to the Home Page!',
                style: TextStyle(
                  fontSize: 30,
                  fontFamily: 'ComicRelief',
                  fontWeight: FontWeight.w400,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: fonts.length,
                  itemBuilder: (context, index) {
                    final user = fonts[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        title: Text(
                          user.name,
                          style: TextStyle(
                            fontWeight: user.weight,
                            fontFamily: "Poppins",
                          ),
                        ),
                        subtitle: Text(user.weight.toString()),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
