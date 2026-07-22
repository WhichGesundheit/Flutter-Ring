import 'package:flutter/material.dart';

/// Utility class for responsive layout decisions across the app.
class Responsive {
  Responsive._();

  /// Returns true if the current orientation is landscape.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Returns the screen width.
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Returns the screen height.
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Returns the aspect ratio (width / height).
  static double aspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width / size.height;
  }

  /// Returns true if the screen is in a "compact" landscape (ratio < 1.5).
  /// This handles small phones in landscape vs tablets/ultrawide.
  static bool isCompactLandscape(BuildContext context) {
    return isLandscape(context) && aspectRatio(context) < 1.5;
  }

  /// Returns true if the screen is wide (ratio >= 1.8).
  /// This handles ultrawide monitors and tablets in landscape.
  static bool isWide(BuildContext context) {
    return aspectRatio(context) >= 1.8;
  }

  /// Responsive font size that scales slightly with screen width.
  static double responsiveFont(BuildContext context, double base) {
    final width = screenWidth(context);
    // Scale factor: at 450px = 1.0, at 800px = 1.15, at 1200px = 1.3
    final scale = (width / 450).clamp(0.85, 1.3);
    return base * scale;
  }

  /// Returns adaptive cross-axis count for grids.
  static int adaptiveGridColumns(
    BuildContext context, {
    int portraitCols = 2,
    int landscapeCols = 3,
  }) {
    if (!isLandscape(context)) return portraitCols;
    final width = screenWidth(context);
    if (width > 1200) return landscapeCols + 2;
    if (width > 900) return landscapeCols + 1;
    return landscapeCols;
  }

  /// Returns adaptive horizontal padding.
  static double horizontalPadding(BuildContext context) {
    if (isLandscape(context)) {
      final width = screenWidth(context);
      return (width * 0.04).clamp(12.0, 40.0);
    }
    return 12.0;
  }

  /// Returns adaptive vertical spacing.
  static double verticalSpacing(BuildContext context, {double base = 12}) {
    if (isLandscape(context)) {
      return base * 0.7;
    }
    return base;
  }
}

/// A widget that builds different layouts for portrait and landscape.
class OrientationLayout extends StatelessWidget {
  final Widget portrait;
  final Widget? landscape;

  const OrientationLayout({super.key, required this.portrait, this.landscape});

  @override
  Widget build(BuildContext context) {
    if (landscape != null && Responsive.isLandscape(context)) {
      return landscape!;
    }
    return portrait;
  }
}

/// A styled card container that adapts to orientation.
class AdaptivePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const AdaptivePanel({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = Responsive.isLandscape(context);
    final defaultPadding = EdgeInsets.all(isLandscape ? 10 : 12);

    return Container(
      padding: padding ?? defaultPadding,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2D3E)),
      ),
      child: child,
    );
  }
}
