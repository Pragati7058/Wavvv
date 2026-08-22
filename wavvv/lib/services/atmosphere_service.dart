import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class AtmosphereService {
  /// Extracts the dominant color from a video thumbnail URL.
  /// Returns null if the image cannot be loaded.
  Future<Color?> extractDominantColor(String thumbnailUrl) async {
    if (thumbnailUrl.isEmpty) return null;
    try {
      final generator = await PaletteGenerator.fromImageProvider(
        NetworkImage(thumbnailUrl),
        size: const Size(100, 56), // Small size for perf
        maximumColorCount: 8,
      );
      return generator.dominantColor?.color ??
          generator.vibrantColor?.color ??
          generator.mutedColor?.color;
    } catch (e) {
      return null;
    }
  }

  /// Converts a dominant color into an atmosphere overlay color (low opacity).
  Color atmosphereColor(Color dominant, {double opacity = 0.08}) {
    return dominant.withValues(alpha: opacity);
  }
}
