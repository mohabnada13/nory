import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A customizable gradient button widget that follows the app's design system.
///
/// This button uses the app's primary gradient and supports leading/trailing widgets.
class GradientButton extends StatelessWidget {
  /// The text to display on the button
  final String label;

  /// Callback when button is pressed. If null, button appears disabled.
  final VoidCallback? onPressed;

  /// Optional height of the button
  final double height;

  /// Optional border radius of the button corners
  final double borderRadius;

  /// Optional padding around the button content
  final EdgeInsetsGeometry padding;

  /// Optional widget to display before the label
  final Widget? leading;

  /// Optional widget to display after the label
  final Widget? trailing;

  /// Creates a gradient button with the app's primary gradient.
  ///
  /// The [label] and [onPressed] parameters are required.
  const GradientButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.leading,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: Colors.white.withOpacity(0.1),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Opacity(
          opacity: onPressed == null ? 0.5 : 1.0,
          child: Container(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              gradient: AppPalette.primaryGradient,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: AppPalette.primaryStart.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
