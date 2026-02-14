import 'dart:convert';

import 'package:dromos/services/user_service.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:dromos/models/id_card_info.dart';
import 'package:dromos/utils/api.dart';

class IdCardParser {
  /// DU-ID identifier URL
  static String uniqueCode = '';

  /// Parse recognized text from ID card and extract relevant information
  static IdCardInfo parse(String recognizedText) {
    List<String> lines = recognizedText.split('\n');
    for (var element in lines) {
      /**
       * 1 - registration number
       * 4 - department
       * 5 - hall
       * 8 - name
       */
      if ({1, 4, 5, 8}.contains(lines.indexOf(element).toInt()) == false) {
        int curIndex = lines.indexOf(element);
        lines[curIndex] = '';
      }
    }

    String regNo = lines[1].trim();
    return IdCardInfo(
      registrationNumber: regNo,
      name: _capitalizeWords(lines[8].trim()),
      hall: _capitalizeWords(lines[5].trim()),
      department: _capitalizeWords(lines[4].trim()),
      session: _extractSession(regNo),
    );
  }

  /// Extract session in format XX-XX (e.g., 22-23)
  static String? _extractSession(String registrationNumberText) {
    if (registrationNumberText.length < 4) return null;

    // Registration format example: 2022xxxxxx -> session: 22-23
    final yearText = registrationNumberText.substring(0, 4);
    final year = int.tryParse(yearText);
    if (year == null) return null;

    final startYY = year % 100;
    final endYY = (startYY + 1) % 100;

    return '${startYY.toString().padLeft(2, '0')}-${endYY.toString().padLeft(2, '0')}';
  }

  /// Helper method to capitalize words
  static String _capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// check if uniquecode is valid of the user using the identifier url
  static Future<bool> isValidUniqueCode(String regNum) async {
    try {
      final response = await http.get(
        Uri.parse('${Api.url}/auth/studentship/$uniqueCode?reg_id=$regNum'),
      );
      // if response status is 200, get new user data
      // so update the user info inside userService
      if (response.statusCode == 200) {
        debugPrint(json.decode(response.body).toString());
        return true;
      } else {
        debugPrint('Invalid unique code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error validating unique code: $e');
      return false;
    }
  }
}
