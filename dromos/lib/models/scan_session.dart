enum ScanSide {
  front,
  back,
}

class ScanSession {
  final String frontImagePath;
  final String? backImagePath;
  final DateTime scannedAt;

  ScanSession({
    required this.frontImagePath,
    this.backImagePath,
    required this.scannedAt,
  });

  bool get hasBackSide => backImagePath != null;

  @override
  String toString() {
    return 'ScanSession(front: $frontImagePath, back: $backImagePath, time: $scannedAt)';
  }
}
