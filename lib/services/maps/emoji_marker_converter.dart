import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:first_maps_project/widgets/models/map_marker.dart';

class EmojiMarkerConverter {
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Checks if a string contains an emoji
  static bool isEmoji(String text) {
    return RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])').hasMatch(text);
  }

  /// Validates and formats an emoji string
  static String? validateAndFormatEmoji(String? input) {
    if (input == null) return null;
    
    final emoji = input.startsWith('emoji:') ? input.substring(6) : input;
    return isEmoji(emoji) ? emoji : null;
  }

  /// Converts an emoji to a BitmapDescriptor that can be used as a marker icon
  static Future<BitmapDescriptor> convertEmojiToMarkerIcon(
    String emoji, {
    double size = 100,
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.black,
    double borderWidth = 2,
  }) async {
    // Check cache first
    final cacheKey = '${emoji}_${size}_${backgroundColor.value}_${borderColor.value}_$borderWidth';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Create a PictureRecorder to draw the emoji
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = backgroundColor;
    
    // Draw background circle
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Draw border
    if (borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        (size / 2) - (borderWidth / 2),
        borderPaint,
      );
    }

    // Draw emoji text
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(
          fontSize: size * 0.6, // Emoji takes up 60% of the circle
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Center the emoji in the circle
    final xCenter = (size - textPainter.width) / 2;
    final yCenter = (size - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(xCenter, yCenter));

    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (bytes == null) {
      throw Exception('Failed to convert emoji to image bytes');
    }

    // Create BitmapDescriptor
    final bitmapDescriptor = BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
    
    // Cache the result
    _cache[cacheKey] = bitmapDescriptor;
    
    return bitmapDescriptor;
  }

  /// Preloads a list of emojis into the cache
  /// This is useful when changing maps to preload all group icons
  static Future<void> preloadEmojis(
    List<String> emojis, {
    double size = 100,
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.black,
    double borderWidth = 2,
  }) async {
    await Future.wait(
      emojis.map((emoji) => convertEmojiToMarkerIcon(
        emoji,
        size: size,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderWidth: borderWidth,
      )),
    );
  }

  /// Clears the cache of converted emoji icons
  /// This should be called when changing maps to free up memory
  static void clearCache() {
    print('Clearing emoji marker cache. Freed ${_cache.length} icons.');
    _cache.clear();
  }
} 