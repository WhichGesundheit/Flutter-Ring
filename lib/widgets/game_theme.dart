import 'package:flutter/material.dart';
import '../models/item.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GAME COLORS – consistent colour palette across the app
// ═══════════════════════════════════════════════════════════════════════════════
class GameColors {
  GameColors._();

  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1A1D2E);
  static const surfaceLight = Color(0xFF111522);
  static const border = Color(0xFF2A2D3E);
  static const primary = Color(0xFFE53935);
  static const accent = Color(0xFF00E5FF);
  static const gold = Color(0xFFFFD600);
  static const success = Color(0xFF00E676);
  static const warning = Color(0xFFFF9100);
  static const danger = Color(0xFFFF1744);

  static Color rarityColor(Rarity r) {
    switch (r) {
      case Rarity.common:
        return Colors.grey;
      case Rarity.premium:
        return Colors.tealAccent;
      case Rarity.unique:
        return Colors.deepPurpleAccent;
      case Rarity.legendary:
        return Colors.amberAccent;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HP BAR – animated health bar with color coding
// ═══════════════════════════════════════════════════════════════════════════════
class HpBar extends StatefulWidget {
  final int current;
  final int max;
  final double height;
  final bool showLabel;
  final bool showNumbers;

  const HpBar({
    super.key,
    required this.current,
    required this.max,
    this.height = 12,
    this.showLabel = false,
    this.showNumbers = true,
  });

  @override
  State<HpBar> createState() => _HpBarState();
}

class _HpBarState extends State<HpBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    final initialFraction = widget.max > 0
        ? (widget.current / widget.max).clamp(0.0, 1.0)
        : 0.0;
    _animation = AlwaysStoppedAnimation(initialFraction);
    _previousFraction = initialFraction;
  }

  @override
  void didUpdateWidget(covariant HpBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current || oldWidget.max != widget.max) {
      final newFraction = widget.max > 0
          ? (widget.current / widget.max).clamp(0.0, 1.0)
          : 0.0;
      _animation = Tween<double>(
        begin: _previousFraction,
        end: newFraction,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _previousFraction = newFraction;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _hpColor(double fraction) {
    if (fraction > 0.6) return GameColors.success;
    if (fraction > 0.3) return GameColors.warning;
    return GameColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final fraction = _animation.value;
        final color = _hpColor(fraction);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showLabel)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'HP',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      border: Border.all(color: Colors.grey[800]!, width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.height / 2),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fraction,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.7)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showNumbers) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${widget.current}/${widget.max}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PROGRESS BAR – generic animated progress bar
// ═══════════════════════════════════════════════════════════════════════════════
class GameProgressBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final double height;
  final String? label;

  const GameProgressBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 8,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              label!,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: Colors.grey[800]!, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAT CHIP – small stat display with icon
// ═══════════════════════════════════════════════════════════════════════════════
class StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double iconSize;
  final double fontSize;

  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.iconSize = 14,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: iconSize),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION HEADER – consistent section divider with icon and label
// ═══════════════════════════════════════════════════════════════════════════════
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
