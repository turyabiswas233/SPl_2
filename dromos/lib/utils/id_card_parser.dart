import 'package:dromos/models/id_card_info.dart';

class IdCardParser {
  /// DU-ID identifier URL
  static const String duIdIdentifierUrl = 'https://academic.eis.du.ac.bd/en/studentship';
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
}
