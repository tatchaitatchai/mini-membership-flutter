import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageHelper {
  static Future<File?> compressAndResizeImage(
    File file, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 60,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed.webp');

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        format: CompressFormat.webp,
      );

      if (result == null) {
        return file;
      }

      return File(result.path);
    } catch (e) {
      return file;
    }
  }

  static Future<List<File>> compressMultipleImages(
    List<File> files, {
    int maxWidth = 1024,
    int maxHeight = 1024,
    int quality = 60,
  }) async {
    final List<File> compressedFiles = [];

    for (final file in files) {
      final compressed = await compressAndResizeImage(file, maxWidth: maxWidth, maxHeight: maxHeight, quality: quality);
      if (compressed != null) {
        compressedFiles.add(compressed);
      }
    }

    return compressedFiles;
  }
}
