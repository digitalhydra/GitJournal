/*
 * SPDX-FileCopyrightText: 2024 GitJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Processes images for storage
/// Resizes to 512x512 and converts to WebP format
class ImageProcessor {
  static const int targetSize = 512;
  static const int quality = 85;

  /// Processes image: resize to 512x512, convert to WebP
  /// Returns path to processed temp file
  static Future<String> process(String sourcePath) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.webp';
    final outputPath = p.join(tempDir.path, fileName);

    // Get original image dimensions
    final file = File(sourcePath);
    final bytes = await file.readAsBytes();
    final decoded = await decodeImageFromList(bytes);
    final width = decoded.width;
    final height = decoded.height;

    // Calculate crop dimensions (center crop to square)
    int cropX = 0;
    int cropY = 0;
    int cropWidth = width;
    int cropHeight = height;

    if (width > height) {
      // Landscape: crop sides
      cropWidth = height;
      cropX = ((width - height) ~/ 2);
    } else if (height > width) {
      // Portrait: crop top/bottom
      cropHeight = width;
      cropY = ((height - width) ~/ 2);
    }

    // Compress and resize to 512x512 WebP
    final result = await FlutterImageCompress.compressWithFile(
      sourcePath,
      minWidth: targetSize,
      minHeight: targetSize,
      quality: quality,
      format: CompressFormat.webp,
      targetPath: outputPath,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return outputPath;
  }

  /// Get WebP extension
  static String get extension => '.webp';

  /// Check if file is already a processed WebP
  static bool isProcessedWebP(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return ext == '.webp';
  }
}
