import 'package:flutter/material.dart';

class GameImage extends StatelessWidget {
  final String? imagePath;
  final IconData fallbackIcon;
  final double size;

  const GameImage({
    super.key,
    this.imagePath,
    required this.fallbackIcon,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      return Image.asset(
        imagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(fallbackIcon, color: Colors.white70, size: size * 0.6),
    );
  }
}
