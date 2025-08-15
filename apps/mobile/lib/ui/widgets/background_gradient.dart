import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A widget that applies the app's background gradient behind its child content.
///
/// This widget creates a container with the app's background gradient and
/// properly handles safe area and padding.
class BackgroundGradient extends StatelessWidget {
  /// The child widget to display.
  final Widget child;

  /// Optional padding to apply around the child.
  final EdgeInsetsGeometry? padding;

  /// Whether to respect the top safe area (e.g., notches, status bars).
  final bool addTopSafeArea;

  /// Creates a background gradient widget.
  ///
  /// The [child] parameter is required.
  /// The [padding] parameter is optional.
  /// The [addTopSafeArea] defaults to true.
  const BackgroundGradient({
    Key? key,
    required this.child,
    this.padding,
    this.addTopSafeArea = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppPalette.backgroundGradient,
      ),
      child: SafeArea(
        top: addTopSafeArea,
        child: padding != null
            ? Padding(
                padding: padding!,
                child: child,
              )
            : child,
      ),
    );
  }
}
