import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageHelper {
  /// Resize và compress ảnh trước khi upload
  static Future<File> resizeAndCompressImage(File imageFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
        format: CompressFormat.jpeg,
      );

      if (compressedFile == null) {
        print('⚠️ Compress failed, using original file');
        return imageFile;
      }

      final originalSize = await imageFile.length();
      final compressedSize = await File(compressedFile.path).length();

      print('📸 Original: ${(originalSize / 1024).toStringAsFixed(2)} KB');
      print('📦 Compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
      print('📉 Saved: ${((1 - compressedSize / originalSize) * 100).toStringAsFixed(1)}%');

      return File(compressedFile.path);

    } catch (e) {
      print('❌ Error compressing: $e');
      return imageFile;
    }
  }

  static Future<bool> validateFileSize(File file, {int maxSizeMB = 10}) async {
    final bytes = await file.length();
    final sizeMB = bytes / (1024 * 1024);
    return sizeMB <= maxSizeMB;
  }
}