import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';

ThemeData appTheme() {
  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color accentColor = ConstColor.primaryPurple.withAlpha(250);

  return ThemeData(
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      actionsIconTheme: IconThemeData(color: accentColor),
      backgroundColor: Colors.transparent,
      foregroundColor: pc,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: accentColor, secondary: pc),
    fontFamily: GoogleFonts.lexend(fontSize: 14, fontWeight: .w500).fontFamily,
    fontFamilyFallback: GoogleFonts.lexend(fontSize: 14, fontWeight: .w500).fontFamilyFallback,
    textTheme: TextTheme(
      bodyLarge: ConstFonts.normal(size: 16),
      bodyMedium: ConstFonts.normal(size: 14),
      bodySmall: ConstFonts.normal(size: 12),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: pbc,
      foregroundColor: accentColor,
    ),
  );
}
