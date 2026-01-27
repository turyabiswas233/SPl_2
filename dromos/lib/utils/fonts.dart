import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConstFonts {
  static final double defaultFontSize = 12; // default size

  static TextStyle thin({double? size, Color? color}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.w300,
    );
  }

  static TextStyle light({double? size, Color? color}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle normal({double? size, Color? color}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle semibold({double? size, Color? color}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.w700,
    );
  }

  static TextStyle bold({double? size, Color? color}) {
    return GoogleFonts.poppins(
      color: color,
      fontSize: size ?? ConstFonts.defaultFontSize,
      fontWeight: FontWeight.w900,
    );
  }
}
