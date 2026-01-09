import 'package:dromos/models/id_card_info.dart';

class OcrResult {
  final bool success;
  final IdCardInfo? data;
  final String? errorMessage;
  final List<String>? tips;

  OcrResult.success(this.data)
      : success = true,
        errorMessage = null,
        tips = null;

  OcrResult.failure({
    required this.errorMessage,
    this.tips,
  })  : success = false,
        data = null;

  OcrResult.noTextRecognized()
      : success = false,
        data = null,
        errorMessage = 'No text detected in the image',
        tips = [
            '✓ Ensure the ID card is clearly visible',
            '✓ Use good lighting (avoid shadows)',
            '✓ Hold the camera steady',
            '✓ Make sure the ID card fills most of the frame',
            '✓ Avoid glare or reflections on the card',
            '✓ Ensure text is not blurry',
          ];

  OcrResult.poorQuality()
      : success = false,
        data = null,
        errorMessage = 'Unable to extract complete information',
        tips = [
            '✓ Try scanning again with better lighting',
            '✓ Clean the camera lens',
            '✓ Hold the phone parallel to the ID card',
            '✓ Avoid capturing at an angle',
          ];
}
