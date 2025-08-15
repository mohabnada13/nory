import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// A widget that provides a frosted-glass styled container.
///
/// This widget creates a container with a glass-like appearance using
/// backdrop filter blur and semi-transparent background.
class GlassCard extends StatelessWidget {
  /// The child widget to display inside the glass card.
  final Widget child;

  /// Optional padding to apply around the child.
  final EdgeInsetsGeometry? padding;

  /// Border radius of the glass card corners.
  final double borderRadius;

  /// Optional color overlay to apply on top of the glass effect.
  final Color? overlayColor;

  /// Optional callback when the card is tapped.
  final VoidCallback? onTap;

  /// Optional constraints to apply to the container.
  final BoxConstraints? constraints;

  /// Creates a glass card widget.
  ///
  /// The [child] parameter is required.
  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.overlayColor,
    this.onTap,
    this.constraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          constraints: constraints,
          decoration: overlayColor != null
              ? AppTheme.glassDecoration(borderRadius).copyWith(
                  color: overlayColor!.withOpacity(overlayColor!.opacity),
                )
              : AppTheme.glassDecoration(borderRadius),
          child: child,
        ),
      ),
    );

    return onTap != null
        ? GestureDetector(
            onTap: onTap,
            child: content,
          )
        : content;
  }
}
