import 'dart:typed_data';

class ImageUtils {
  static Uint8List cleanImageBytes(List<int> bytes) {
    // Find where actual image data starts (skip leading whitespace)
    int start = 0;
    while (start < bytes.length && bytes[start] == 0x20) {
      start++;
    }
    return Uint8List.fromList(bytes.sublist(start));
  }
}
