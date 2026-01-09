import 'dart:math';

import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';

class CustomInput extends StatefulWidget {
  final String title;
  final String hint;
  final String initialValue;
  final IconData? icon;
  final TextEditingController controller;
  final Color accentColor;
  final bool isPassword;

  const CustomInput({
    super.key,
    required this.title,
    required this.hint,
    this.icon,
    this.accentColor = ConstColor.primaryPurple,
    required this.initialValue,
    required this.controller,
    this.isPassword = false,
  });

  @override
  State<CustomInput> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomInput> {
  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color secondaryColor = ConstColor.primaryPurple;

  @override
  void initState() {
    super.initState();
    // Set initial value to controller if not already set
    if (widget.controller.text.isEmpty && widget.initialValue.isNotEmpty) {
      if (widget.title == "Gender") {
        widget.controller.text = widget.initialValue.toUpperCase();
      } else {
        widget.controller.text = widget.initialValue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword,
      textCapitalization: TextCapitalization.words,
      style: ConstFonts.normal(size: 14, color: pc),
      decoration: InputDecoration(
        labelText: widget.title,
        labelStyle: ConstFonts.normal(size: 14, color: pc),
        hintText: widget.hint,
        hintStyle: ConstFonts.normal(size: 14, color: pc.withAlpha(150)),
        prefixIcon: Icon(
          widget.icon ?? Icons.help_outline,
          color: widget.accentColor,
        ),
        filled: true,
        fillColor: Colors.white.withAlpha(13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: Colors.white.withAlpha(150),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: Colors.white.withAlpha(150),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: widget.accentColor, width: 2.0),
        ),
      ),
    );
  }
}
