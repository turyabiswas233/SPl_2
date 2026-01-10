import 'package:dromos/models/ocr_result.dart';
import 'package:dromos/utils/id_card_parser.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class OcrService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Scan ID card using camera and return parsed information
  Future<OcrResult> scanIdCard() async {
    try {
      // Pick image from camera
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image == null) {
        debugPrint('No image selected');
        return OcrResult.failure(
          errorMessage: 'No image captured',
          tips: ['Please try again and capture the ID card'],
        );
      }

      // Process the image
      return await processImage(image.path);
    } catch (e) {
      debugPrint('Error scanning ID card: $e');
      return OcrResult.failure(
        errorMessage: 'Camera error: ${e.toString()}',
        tips: ['✓ Check camera permissions', '✓ Restart the app and try again'],
      );
    }
  }

  /// Process image from gallery and return parsed information
  Future<OcrResult> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) {
        debugPrint('No image selected');
        return OcrResult.failure(
          errorMessage: 'No image selected',
          tips: ['Please select an image of your ID card'],
        );
      }

      return await processImage(image.path);
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return OcrResult.failure(
        errorMessage: 'Gallery error: ${e.toString()}',
        tips: [
          '✓ Check storage permissions',
          '✓ Try selecting a different image',
        ],
      );
    }
  }

  /// Process image and extract text using OCR
  Future<OcrResult> processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      if (recognizedText.text.isEmpty) {
        debugPrint('No text recognized from image');
        return OcrResult.noTextRecognized();
      }

      // Parse the recognized text
      final idCardInfo = IdCardParser.parse(recognizedText.text);
      debugPrint('Parsed ID card info: $idCardInfo');

      // Check if any meaningful data was extracted
      if (!idCardInfo.hasData) {
        debugPrint('No meaningful data extracted from text');
        return OcrResult.poorQuality();
      }

      return OcrResult.success(idCardInfo);
    } catch (e) {
      debugPrint('Error processing image: $e');
      return OcrResult.failure(
        errorMessage: 'OCR processing failed: ${e.toString()}',
        tips: [
          '✓ Ensure the image is clear and readable',
          '✓ Try taking another photo',
          '✓ Check if the ID card is in focus',
        ],
      );
    }
  }

  /// Scan just the image path and return the path for second side scanning
  Future<String?> scanImageOnly({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image == null) {
        debugPrint('No image selected');
        return null;
      }

      return image.path;
    } catch (e) {
      debugPrint('Error capturing image: $e');
      rethrow;
    }
  }

  /// Process image for debugging (back side of ID card)
  Future<void> processImageForUniqueCode(String imagePath, String label) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      List<String> lines = recognizedText.text.split('\n');
      String uniqueCode = lines.length > 2 ? lines[2] : 'N/A';
      if (uniqueCode == 'N/A' || uniqueCode.isEmpty) {
        debugPrint('Unique code not found in $label side');
        return;
      }

      IdCardParser.uniqueCode = uniqueCode;

      debugPrint('================');
      debugPrint("Unique Code: $uniqueCode");
      debugPrint('================');
    } catch (e) {
      debugPrint('Error processing $label: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }
}
