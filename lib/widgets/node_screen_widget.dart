import 'package:flutter/material.dart';
import '../models/zone.dart';
import 'game_theme.dart';
import 'responsive_layout.dart';

/// The embeddable node visual widget.
/// Shows a zone-themed image container with scout/inventory buttons.
/// Used both as a standalone widget (portrait via NodeScreen) and
/// embedded inline (landscape in MainScreen).
class NodeScreenWidget extends StatelessWidget {
  final ZoneType currentZone;
  final VoidCallback onScout;
  final VoidCallback? onInventory;
  final VoidCallback? onBank;
  final VoidCallback? onWarehouse;
  final VoidCallback? onShop;

  const NodeScreenWidget({
    super.key,
    required this.currentZone,
    required this.onScout,
    this.onInventory,
    this.onBank,
    this.onWarehouse,
    this.onShop,
  });

  @override
  Widget build(BuildContext context) {
    final zoneData = Zone.worldMap[currentZone]!;
    final isLandscape = Responsive.isLandscape(context);

    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0A0E1A)),
      child: Column(
        children: [
          // ── IMAGE CONTAINER (expandable) ──
          Expanded(child: _buildImageContainer(context, zoneData, isLandscape)),

          // ── BUTTONS PANEL ──
          _buildButtonsPanel(context, isLandscape),
        ],
      ),
    );
  }

  Widget _buildImageContainer(
    BuildContext context,
    Zone zoneData,
    bool isLandscape,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            zoneData.color.withValues(alpha: 0.08),
            const Color(0xFF0A0E1A),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: zoneData.color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Layer 0: Subtle grid pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                color: zoneData.color.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Layer 1: Node image (full container, faded background)
          Positioned.fill(
            child: Opacity(
              opacity: 0.65,
              child: Image.asset(
                zoneData.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to the icon if the image fails to load
                  return Center(
                    child: Icon(
                      zoneData.icon,
                      size: isLandscape ? 120 : 160,
                      color: zoneData.color.withValues(alpha: 0.12),
                    ),
                  );
                },
              ),
            ),
          ),

          // Layer 1b: Settlement indicator (top-right)
          if (zoneData.isSettlement)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0E1A).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: zoneData.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '🏪 SETTLEMENT',
                  style: TextStyle(
                    color: zoneData.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

          // Layer 2: Zone name overlay at top
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0E1A).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: zoneData.color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(zoneData.icon, color: zoneData.color, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        zoneData.name.toUpperCase(),
                        style: TextStyle(
                          color: zoneData.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Layer 3: Zone description at bottom (above buttons)
          Positioned(
            bottom: 0,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Text(
                zoneData.description,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  height: 1.3,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsPanel(BuildContext context, bool isLandscape) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, isLandscape ? 8 : 12),
      decoration: const BoxDecoration(
        color: Color(0xFF111522),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shop button (traveling merchant)
          if (onShop != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: GameColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: GameColors.gold.withValues(alpha: 0.4),
                ),
                onPressed: onShop,
                icon: const Icon(Icons.store, size: 18),
                label: const Text(
                  "MERCHANT SHOP",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
          // Scout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: GameColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: GameColors.primary.withValues(alpha: 0.4),
              ),
              onPressed: onScout,
              child: const Text(
                "SCOUT ADJACENT NODE",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          if (onInventory != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  foregroundColor: GameColors.accent,
                  side: BorderSide(
                    color: GameColors.accent.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onInventory,
                child: const Text(
                  "MATRIX CONFIGURATION",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
          // Bank & Warehouse buttons for settlements
          if (onBank != null || onWarehouse != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (onBank != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: GameColors.gold,
                        side: BorderSide(
                          color: GameColors.gold.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onBank,
                      icon: const Icon(Icons.account_balance, size: 16),
                      label: const Text(
                        "BANK",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                if (onBank != null && onWarehouse != null)
                  const SizedBox(width: 8),
                if (onWarehouse != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        foregroundColor: Colors.cyanAccent,
                        side: BorderSide(
                          color: Colors.cyanAccent.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onWarehouse,
                      icon: const Icon(Icons.warehouse, size: 16),
                      label: const Text(
                        "WAREHOUSE",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple grid pattern painter for the node background.
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => color != old.color;
}
