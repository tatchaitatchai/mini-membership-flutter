import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
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
      final targetPath = path.join(
        dir.path,
        '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg',
      );

      final result = await compute(_compressIsolate, {
        'sourcePath': file.absolute.path,
        'targetPath': targetPath,
        'maxWidth': maxWidth,
        'maxHeight': maxHeight,
        'quality': quality,
      });

      if (result == null) return file;
      return File(result);
    } catch (_) {
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
      final compressed = await compressAndResizeImage(
        file,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      );
      if (compressed != null) compressedFiles.add(compressed);
    }
    return compressedFiles;
  }
}

String? _compressIsolate(Map<String, dynamic> params) {
  try {
    final bytes = File(params['sourcePath'] as String).readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final maxWidth = params['maxWidth'] as int;
    final maxHeight = params['maxHeight'] as int;
    final quality = params['quality'] as int;

    img.Image output = decoded;
    if (decoded.width > maxWidth || decoded.height > maxHeight) {
      final scaleX = maxWidth / decoded.width;
      final scaleY = maxHeight / decoded.height;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      output = img.copyResize(
        decoded,
        width: (decoded.width * scale).round(),
        height: (decoded.height * scale).round(),
      );
    }

    final compressed = img.encodeJpg(output, quality: quality);
    final targetPath = params['targetPath'] as String;
    File(targetPath).writeAsBytesSync(compressed);
    return targetPath;
  } catch (_) {
    return null;
  }
}
