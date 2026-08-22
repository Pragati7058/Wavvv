import 'package:flutter/services.dart';

class HapticsUtil {
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> wave() async {
    // Custom pattern for wave reaction
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.mediumImpact();
  }

  static Future<void> rewind() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }
}
