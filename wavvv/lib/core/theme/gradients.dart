import 'package:flutter/material.dart';
import 'colors.dart';

class WavvvGlowGradients {
  static const LinearGradient redGradient = LinearGradient(
    colors: [
      WavvvColors.red,
      WavvvColors.redDark,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient waveGradient = LinearGradient(
    colors: [
      Color(0xFF8B5CF6), // Purple
      WavvvColors.wave,  // Indigo
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF), // 10% white
      Color(0x05FFFFFF), // 2% white
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient bgMeshGradient = RadialGradient(
    colors: [
      WavvvColors.waveGlow,
      WavvvColors.bg,
    ],
    radius: 1.2,
    center: Alignment.center,
  );
}
