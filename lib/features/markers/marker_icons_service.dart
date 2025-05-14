import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart' as painting;

/// Service responsible for managing marker icons and their caching
class MarkerIconsService {
  final Map<String, BitmapDescriptor> _iconCache = {};

  /// Get a cached icon or create a new one if it doesn't exist
  Future<BitmapDescriptor> getOrCreateIcon(String iconKey) async {
    if (_iconCache.containsKey(iconKey)) {
      return _iconCache[iconKey]!;
    }

    // Create icon based on type
    late BitmapDescriptor icon;
    if (iconKey.startsWith('emoji:')) {
      icon = await _createEmojiMarker(iconKey.substring(6));
    } else {
      // Default or other icon types
      icon = BitmapDescriptor.defaultMarker;
    }

    _iconCache[iconKey] = icon;
    return icon;
  }

  /// Creates a custom marker icon with an emoji
  Future<BitmapDescriptor> _createEmojiMarker(String emoji, {int size = 64}) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final borderPaint = ui.Paint()
      ..color = const Color(0xFF41AAF5)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = size * 0.1;
    final fillPaint = ui.Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = ui.PaintingStyle.fill;

    final radius = size / 2 - borderPaint.strokeWidth / 2;
    final center = ui.Offset(size / 2, size / 2);

    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);

    final textPainter = painting.TextPainter(
      text: painting.TextSpan(
        text: emoji,
        style: painting.TextStyle(fontSize: radius * 1.2),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final offset = ui.Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size, size);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Clear the icon cache
  void clearCache() {
    _iconCache.clear();
  }

  /// Gets an icon from cache or returns default if not found
  BitmapDescriptor getIcon(String iconKey) {
    return _iconCache[iconKey] ?? BitmapDescriptor.defaultMarker;
  }

  /// Gets a selected marker icon (either from cache or default azure)
  BitmapDescriptor getSelectedIcon(String? iconKey) {
    return iconKey != null && _iconCache.containsKey(iconKey)
        ? _iconCache[iconKey]!
        : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  }
} 