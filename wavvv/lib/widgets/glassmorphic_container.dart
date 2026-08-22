import 'dart:ui';
import 'package:flutter/material.dart';

class GlassMorphicContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? color;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;

  const GlassMorphicContainer({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
    this.color,
    this.blurSigma = 12.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Theme.of(context).colorScheme.surface.withValues(alpha: 0.2);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
