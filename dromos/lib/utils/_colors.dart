import 'package:flutter/material.dart';

class ConstColor {
  static const Color primaryPurple = Color(0xff6358dc);
  static Color primaryColor = Color(0xff010101);
  static Color primaryBg = Colors.white;

  //dark
  static const Color primaryBgDark = Color(0xff0c0b1a);
  static Color primaryColorDark = Colors.white;

  Map<int, Color> light() {
    return {
      1: primaryColor,
      2: primaryBg,
    };
  }

  Map<int, Color> dark() {
    return {
      1: primaryColorDark,
      2: primaryBgDark,
    };
  }
}
