import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Extracts the true dominant theme color from a banner image
class ColorExtractorService {
  static final Map<String, Color> _cache = {};

  static Future<Color?> extractDominantColor(String imageUrl) async {
    if (imageUrl.isEmpty) return null;
    if (_cache.containsKey(imageUrl)) {
      return _cache[imageUrl];
    }

    try {
      final ImageProvider imageProvider = NetworkImage(imageUrl);
      final Completer<ui.Image> completer = Completer();
      final ImageStream stream = imageProvider.resolve(const ImageConfiguration(size: Size(30, 30)));

      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool _) {
          if (!completer.isCompleted) {
            completer.complete(info.image);
          }
          stream.removeListener(listener);
        },
        onError: (dynamic exception, StackTrace? stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(exception);
          }
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);

      final ui.Image image = await completer.future.timeout(const Duration(seconds: 4));
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final buffer = byteData.buffer.asUint8List();

      int rTotal = 0, gTotal = 0, bTotal = 0, count = 0;

      // Sample pixels, ignoring pure black, pure white, or transparent
      for (int i = 0; i < buffer.length; i += 4) {
        final a = buffer[i + 3];
        if (a < 150) continue;

        final r = buffer[i];
        final g = buffer[i + 1];
        final b = buffer[i + 2];

        final brightness = (r * 299 + g * 587 + b * 114) / 1000;
        if (brightness < 25 || brightness > 240) continue;

        rTotal += r;
        gTotal += g;
        bTotal += b;
        count++;
      }

      if (count > 0) {
        final rawDominant = Color.fromARGB(
          255,
          (rTotal / count).round().clamp(0, 255),
          (gTotal / count).round().clamp(0, 255),
          (bTotal / count).round().clamp(0, 255),
        );

        // Adjust saturation and lightness for a rich, high-contrast AppBar background
        final hsl = HSLColor.fromColor(rawDominant);
        final adjusted = hsl
            .withLightness(hsl.lightness.clamp(0.25, 0.45))
            .withSaturation(hsl.saturation.clamp(0.40, 0.95))
            .toColor();

        _cache[imageUrl] = adjusted;
        return adjusted;
      }
    } catch (_) {}

    return null;
  }
}
