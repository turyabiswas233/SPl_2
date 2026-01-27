import 'package:flutter/material.dart';
import '_colors.dart';

class ConstFonts {
  static final double defaultFontSize = 14; // default size

  static TextStyle thin({double? size, Color? color}) {
    return TextStyle(
      color: color ?? ConstColor.primary_color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.w300,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle light({double? size, Color? color}) {
    return TextStyle(
      color: color ?? ConstColor.primary_color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.w400,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle normal({double? size, Color? color}) {
    return TextStyle(
      color: color ?? ConstColor.primary_color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.w500,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle semibold({double? size, Color? color}) {
    return TextStyle(
      color: color ?? ConstColor.primary_color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.w700,
      fontFamily: 'Poppins',
    );
  }

  static TextStyle bold({double? size, Color? color}) {
    // return GoogleFonts.poppins(
    //   color: color ?? ConstColor.primary_color,
    //   fontSize: size ?? ConstFonts.defaultFontSize,
    //   fontWeight: FontWeight.w900,
    // );
    return TextStyle(
      color: color ?? ConstColor.primary_color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.bold,
      fontFamily: 'Poppins',
    );
  }
}
