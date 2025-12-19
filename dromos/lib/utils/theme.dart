import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dromos/utils/colors.dart';

ThemeData appTheme() {
  ConstColor cc = ConstColor();
  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple;

  return ThemeData(
    useSystemColors: false,
    appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(color: accentColor),
      backgroundColor: Colors.transparent,
      foregroundColor: pc,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontFamilyFallback: GoogleFonts.poppins().fontFamilyFallback,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: pbc,
    ),
  );
}
