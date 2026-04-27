/*
 * SPDX-FileCopyrightText: 2024 RecipeJournal Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Processes images for recipe storage
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

    // Compress and resize to 512x512 WebP
    // FlutterImageCompress handles resize internally
    final result = await FlutterImageCompress.compressWithFile(
      sourcePath,
      minWidth: targetSize,
      minHeight: targetSize,
      quality: quality,
      format: CompressFormat.webp,
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    // Write compressed bytes to output file
    await File(outputPath).writeAsBytes(result);

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
