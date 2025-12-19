import 'dart:math';

import 'package:dromos/utils/colors.dart';
import 'package:dromos/utils/fonts.dart';
import 'package:flutter/material.dart';

class CustomInput extends StatefulWidget {
  final String title;
  final String hint;
  final IconData? icon;
  final TextEditingController controller;
  final bool isPassword;

  const CustomInput({
    super.key,
    required this.title,
    required this.hint,
    this.icon,
    required this.controller,
    this.isPassword = false,
  });

  @override
  State<CustomInput> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomInput> {
  bool _obscureText = true;

  Color pc = ConstColor.primaryColor;
  Color pbc = ConstColor.primaryBg;
  Color secondaryColor = ConstColor.primaryPurple;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (e.g., "Email", "Password")
        Text(
          widget.title,
          style: ConstFonts.normal(color: pc, size: 12),
        ),
        const SizedBox(height: 8.0),
        // Text field in a card for shadow
        Card(
          elevation: 4.0,
          color: pbc,
          shadowColor: Colors.grey.withAlpha(80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscureText : false,
            style: ConstFonts.semibold(size: 12),
            decoration: InputDecoration(
              // Hint/Placeholder
              hintText: widget.hint,
              hintStyle: ConstFonts.normal(size: 12),
              // Remove the default border
              border: InputBorder.none,
              // Left Icon
              prefixIcon: Transform.rotate(
                angle: widget.isPassword ? 45 / 180 * pi : 0,
                child: Icon(widget.icon, size: 26),
              ),
              // Right "visibility" icon for password
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.black87,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
