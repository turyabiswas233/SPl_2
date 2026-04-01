import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dromos/utils/colors.dart';

ThemeData appTheme() {
  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple.withAlpha(250);
 
  return ThemeData(
    useSystemColors: false,
    appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(color: accentColor),
      backgroundColor: Colors.transparent,
      foregroundColor: pc,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
        
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: pc),
    fontFamily: GoogleFonts.poppins().fontFamily,
    fontFamilyFallback: GoogleFonts.poppins().fontFamilyFallback,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: pbc,
    ),
  );
}
