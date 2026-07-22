import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/boss.dart';
import '../models/zone.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 3D point on the sphere surface
// ═══════════════════════════════════════════════════════════════════════════════
class SphereNode {
  final ZoneType zoneType;
  final double x;
  final double y;
  final double z;

  SphereNode(this.zoneType, this.x, this.y, this.z);
}

// ═══════════════════════════════════════════════════════════════════════════════
// Node shape categories (mirrors travel_screen logic)
// ═══════════════════════════════════════════════════════════════════════════════
enum NodeShape { circle, roundedSquare, diamond, hexagon, guardian }

NodeShape getNodeShape(ZoneType type, bool isSettlement) {
  if (isSettlement) return NodeShape.roundedSquare;
  if (GuardianBosses.isGuardianZone(type)) return NodeShape.guardian;
  const hexZones = {
    ZoneType.quantumRift,
    ZoneType.voidShrine,
    ZoneType.voidGate,
    ZoneType.voidNexus,
    ZoneType.entropyWell,
    ZoneType.quantumSea,
    ZoneType.dataNexus,
    ZoneType.ghostTerminal,
    ZoneType.neuralGarden,
    ZoneType.echoCaverns,
    ZoneType.staticRift,
    ZoneType.deadSignal,
    ZoneType.chromeLabyrinth,
  };
  if (hexZones.contains(type)) return NodeShape.hexagon;
  return NodeShape.diamond;
}

// ═══════════════════════════════════════════════════════════════════════════════
// Color constants for the new scheme
// ═══════════════════════════════════════════════════════════════════════════════
const Color _unexploredNodeColor = Color(0xFF2A2A2A);
const Color _unexploredLineColor = Color(0xFF333333);
const Color _exploredNodeColor = Color(0xFFE2E2E2);
const Color _exploredLineColor = Color(0xFFEDEDED);
const Color _adjacentColor = Color(0xFF4488FF);
const Color _chosenColor = Color(0xFFFFD700);
const Color _hubGlowColor = Color(0xFF66CCFF);
const Color _guardianGlowColor = Color(0xFFFF1744);

// ═══════════════════════════════════════════════════════════════════════════════
// SphereMapPainter – renders all zones as nodes on a 3D sphere
// ═══════════════════════════════════════════════════════════════════════════════
class SphereMapPainter extends CustomPainter {
  final double angleX;
  final double angleY;
  final double scale;
  final ZoneType currentZone;
  final ZoneType? selectedZone;
  final ZoneType? highlightedDestination;
  final int currentDay;

  /// Pre-computed sphere nodes (built once in init)
  final List<SphereNode> nodes;

  /// Zones the player has visited
  final Set<ZoneType> exploredZones;

  /// Zones directly adjacent to the current zone
  final Set<ZoneType> adjacentZones;

  /// Zones that have a traveling merchant present
  final Set<ZoneType> merchantZones;

  /// Animation value for merchant icon floating bob (0.0 – 1.0)
  final double merchantAnimValue;

  SphereMapPainter({
    required this.nodes,
    required this.currentZone,
    required this.selectedZone,
    required this.currentDay,
    this.highlightedDestination,
    this.angleX = 0.0,
    this.angleY = 0.0,
    this.scale = 1.0,
    this.exploredZones = const {},
    this.adjacentZones = const {},
    this.merchantZones = const {},
    this.merchantAnimValue = 0.0,
  });

  /// Whether a node is explored (visited or current zone)
  bool _isExplored(ZoneType type) =>
      exploredZones.contains(type) || type == currentZone;

  /// Whether a node is adjacent to current zone
  bool _isAdjacent(ZoneType type) => adjacentZones.contains(type);

  /// Whether a node is the chosen/highlighted destination
  bool _isChosen(ZoneType type) =>
      highlightedDestination != null && type == highlightedDestination;

  /// Whether a node is the current zone
  bool _isCurrent(ZoneType type) => type == currentZone;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * 0.35 * scale;

    // ── 1. Rotate & project all nodes ──
    final List<Offset> projected = [];
    final List<double> depths = [];
    final List<SphereNode> sortedNodes = [];

    for (var node in nodes) {
      // Rotate around X axis
      double cosX = math.cos(angleX);
      double sinX = math.sin(angleX);
      double y1 = node.y * cosX - node.z * sinX;
      double z1 = node.y * sinX + node.z * cosX;

      // Rotate around Y axis
      double cosY = math.cos(angleY);
      double sinY = math.sin(angleY);
      double x2 = node.x * cosY + z1 * sinY;
      double z2 = -node.x * sinY + z1 * cosY;

      double screenX = center.dx + x2 * radius;
      double screenY = center.dy + y1 * radius;

      projected.add(Offset(screenX, screenY));
      depths.add(z2);
      sortedNodes.add(node);
    }

    // ── 2. Draw faint sphere outline ──
    final sphereOutlinePaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, sphereOutlinePaint);

    // Subtle fill
    final sphereFillPaint = Paint()
      ..shader = ui.Gradient.radial(center, radius, [
        Colors.cyanAccent.withValues(alpha: 0.03),
        Colors.transparent,
      ]);
    canvas.drawCircle(center, radius, sphereFillPaint);

    // ── 3. Draw connection lines between adjacent zones ──
    final drawn = <String>{};
    for (var node in nodes) {
      final fromZone = Zone.worldMap[node.zoneType]!;
      final fromIdx = sortedNodes.indexOf(node);
      final from = projected[fromIdx];

      for (final target in fromZone.connections) {
        final key = _edgeKey(node.zoneType, target);
        if (drawn.contains(key)) continue;
        drawn.add(key);

        final toIdx = sortedNodes.indexWhere((n) => n.zoneType == target);
        if (toIdx == -1) continue;
        final to = projected[toIdx];

        _drawConnectionLine(canvas, from, to, node.zoneType, target);
      }
    }

    // ── 4. Sort nodes by depth (back-to-front) for proper occlusion ──
    final indices = List.generate(projected.length, (i) => i);
    indices.sort((a, b) => depths[a].compareTo(depths[b]));

    // ── 5. Draw nodes ──
    for (final i in indices) {
      final node = sortedNodes[i];
      final zone = Zone.worldMap[node.zoneType]!;
      final pos = projected[i];
      final depth = depths[i];
      double normalizedDepth = (depth + 1) / 2; // 0=far, 1=near

      final bool isCurrentNode = _isCurrent(node.zoneType);
      final bool isAdjNode = _isAdjacent(node.zoneType);
      final bool isChosenNode = _isChosen(node.zoneType);
      final bool explored = _isExplored(node.zoneType);
      final bool isHub = zone.isSettlement;

      // Node size: larger when closer
      double nodeRadius = (4.0 + normalizedDepth * 5.0) * scale;

      // Node color based on the new scheme
      Color nodeColor;
      if (isChosenNode) {
        nodeColor = _chosenColor;
      } else if (isCurrentNode) {
        nodeColor = _adjacentColor; // Current zone shown in blue
      } else if (isAdjNode) {
        nodeColor = _adjacentColor;
      } else if (explored) {
        nodeColor = Color.lerp(
          _exploredNodeColor,
          _exploredNodeColor.withValues(alpha: 0.8),
          normalizedDepth,
        )!;
      } else {
        nodeColor = Color.lerp(
          _unexploredNodeColor,
          _unexploredNodeColor.withValues(alpha: 0.6),
          normalizedDepth,
        )!;
      }

      // Background circle
      final bgPaint = Paint()
        ..color = _darkenColor(nodeColor, 0.6).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, nodeRadius + 3, bgPaint);

      // Main node circle
      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, nodeRadius, nodePaint);

      // Border for current, chosen, or adjacent nodes
      if (isCurrentNode || isChosenNode || isAdjNode) {
        final borderColor = isChosenNode ? _chosenColor : _adjacentColor;
        final borderPaint = Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pos, nodeRadius + 1, borderPaint);
      }

      // Glow for hub (settlement) nodes – always glowing
      if (isHub) {
        final glowRadius = isCurrentNode ? 16.0 : 10.0;
        final glowAlpha = isCurrentNode ? 0.35 : 0.2;
        final glowPaint = Paint()
          ..color = _hubGlowColor.withValues(alpha: glowAlpha)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
        canvas.drawCircle(pos, nodeRadius + 6, glowPaint);
      }

      // Glow for current zone (brighter when destination is selected)
      if (isCurrentNode) {
        final hasHighlight = highlightedDestination != null;
        final currentGlowAlpha = hasHighlight ? 0.4 : 0.25;
        final currentGlowRadius = hasHighlight ? 14.0 : 12.0;
        final glowPaint = Paint()
          ..color = _adjacentColor.withValues(alpha: currentGlowAlpha)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentGlowRadius);
        canvas.drawCircle(pos, nodeRadius + 8, glowPaint);
      }

      // Extra glow for chosen destination node
      if (isChosenNode) {
        // Outer glow
        final outerGlowPaint = Paint()
          ..color = _chosenColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(pos, nodeRadius + 12, outerGlowPaint);
        // Inner bright border
        final highlightBorderPaint = Paint()
          ..color = _chosenColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(pos, nodeRadius + 2, highlightBorderPaint);
      }

      // Glow for guardian nodes – always pulsing red
      if (GuardianBosses.isGuardianZone(node.zoneType)) {
        // Outer red glow
        final outerGlowPaint = Paint()
          ..color = _guardianGlowColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
        canvas.drawCircle(pos, nodeRadius + 14, outerGlowPaint);
        // Inner red glow
        final innerGlowPaint = Paint()
          ..color = _guardianGlowColor.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawCircle(pos, nodeRadius + 8, innerGlowPaint);
        // Red node color override (always red regardless of explored state)
        final guardianNodePaint = Paint()
          ..color = _guardianGlowColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, nodeRadius, guardianNodePaint);
        // Red border
        final guardianBorderPaint = Paint()
          ..color = _guardianGlowColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pos, nodeRadius + 1, guardianBorderPaint);
      }

      // Zone icon (simplified: draw a small shape based on node shape)
      _drawNodeIcon(canvas, pos, nodeRadius, zone, explored, normalizedDepth);

      // ── Merchant floating "?" icon ──
      if (merchantZones.contains(node.zoneType) && explored) {
        _drawMerchantIcon(canvas, pos, nodeRadius, normalizedDepth);
      }
    }
  }

  void _drawMerchantIcon(
    Canvas canvas,
    Offset nodePos,
    double nodeRadius,
    double depth,
  ) {
    // Floating bob: sine wave based on merchantAnimValue
    final double bobOffset = math.sin(merchantAnimValue * 2 * math.pi) * 3.0;
    final double iconRadius = (4.0 + depth * 3.0) * scale;
    final Offset iconPos = Offset(
      nodePos.dx + nodeRadius * 0.7,
      nodePos.dy - nodeRadius - 8 - bobOffset,
    );

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, iconRadius * 1.5);
    canvas.drawCircle(iconPos, iconRadius + 2, glowPaint);

    // Green circle background
    final bgPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(iconPos, iconRadius, bgPaint);

    // "?" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: iconRadius * 1.4,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        iconPos.dx - textPainter.width / 2,
        iconPos.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawNodeIcon(
    Canvas canvas,
    Offset center,
    double radius,
    Zone zone,
    bool explored,
    double depth,
  ) {
    if (!explored) {
      // Draw lock icon placeholder: small rectangle
      final lockPaint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      final lockRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center,
          width: radius * 0.8,
          height: radius * 0.8,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(lockRect, lockPaint);
      return;
    }

    final iconColor = Colors.white.withValues(alpha: 0.8 + depth * 0.2);
    final shape = getNodeShape(zone.type, zone.isSettlement);

    switch (shape) {
      case NodeShape.roundedSquare:
        // Settlement: draw a small rounded rect
        final paint = Paint()
          ..color = iconColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: radius * 0.8,
            height: radius * 0.8,
          ),
          Radius.circular(radius * 0.2),
        );
        canvas.drawRRect(rect, paint);
        break;
      case NodeShape.diamond:
        // Diamond: draw a rotated square
        final paint = Paint()
          ..color = iconColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        final half = radius * 0.5;
        final path = Path()
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy)
          ..lineTo(center.dx, center.dy + half)
          ..lineTo(center.dx - half, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case NodeShape.hexagon:
        // Hexagon
        final paint = Paint()
          ..color = iconColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        final half = radius * 0.55;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (math.pi / 3) * i - math.pi / 2;
          final dx = center.dx + half * math.cos(angle);
          final dy = center.dy + half * math.sin(angle);
          if (i == 0) {
            path.moveTo(dx, dy);
          } else {
            path.lineTo(dx, dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case NodeShape.circle:
        // Default: small cross or dot
        final dotPaint = Paint()
          ..color = iconColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius * 0.2, dotPaint);
        break;
      case NodeShape.guardian:
        // Guardian: draw a glowing red star/pentagon
        final paint = Paint()
          ..color = _guardianGlowColor.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final half = radius * 0.55;
        final path = Path();
        for (int i = 0; i < 8; i++) {
          final angle = (math.pi / 4) * i - math.pi / 2;
          final r = i.isEven ? half : half * 0.5;
          final dx = center.dx + r * math.cos(angle);
          final dy = center.dy + r * math.sin(angle);
          if (i == 0) {
            path.moveTo(dx, dy);
          } else {
            path.lineTo(dx, dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  void _drawConnectionLine(
    Canvas canvas,
    Offset a,
    Offset b,
    ZoneType fromType,
    ZoneType toType,
  ) {
    final bool fromExplored = _isExplored(fromType);
    final bool toExplored = _isExplored(toType);
    final bool bothExplored = fromExplored && toExplored;
    final bool fromAdjacent = _isAdjacent(fromType);
    final bool toAdjacent = _isAdjacent(toType);
    final bool isAdjacentEdge =
        (fromType == currentZone && toAdjacent) ||
        (toType == currentZone && fromAdjacent);
    final bool isChosenEdge =
        (fromType == currentZone && toType == highlightedDestination) ||
        (toType == currentZone && fromType == highlightedDestination);

    // Red glow for edges connected to guardian zones
    final bool isGuardianEdge =
        GuardianBosses.isGuardianZone(fromType) ||
        GuardianBosses.isGuardianZone(toType);

    if (isChosenEdge) {
      // Yellow glow for chosen path
      final outerGlowPaint = Paint()
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = _chosenColor.withValues(alpha: 0.3);
      canvas.drawLine(a, b, outerGlowPaint);

      final glowPaint = Paint()
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..color = _chosenColor.withValues(alpha: 0.5);
      canvas.drawLine(a, b, glowPaint);

      final corePaint = Paint()
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(a, b, [
          _chosenColor,
          Colors.orangeAccent,
        ]);
      canvas.drawLine(a, b, corePaint);
    } else if (isGuardianEdge) {
      // Red glow for guardian connections
      final outerGlowPaint = Paint()
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = _guardianGlowColor.withValues(alpha: 0.25);
      canvas.drawLine(a, b, outerGlowPaint);

      final corePaint = Paint()
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(a, b, [
          _guardianGlowColor.withValues(alpha: 0.7),
          _guardianGlowColor.withValues(alpha: 0.3),
        ]);
      canvas.drawLine(a, b, corePaint);
    } else if (isAdjacentEdge) {
      // Blue for adjacent connections
      final glowPaint = Paint()
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = _adjacentColor.withValues(alpha: 0.25);
      canvas.drawLine(a, b, glowPaint);

      final corePaint = Paint()
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(a, b, [
          _adjacentColor.withValues(alpha: 0.8),
          _adjacentColor.withValues(alpha: 0.5),
        ]);
      canvas.drawLine(a, b, corePaint);
    } else if (bothExplored) {
      // Light grey for explored connections
      final dimPaint = Paint()
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = _exploredLineColor.withValues(alpha: 0.5);
      canvas.drawLine(a, b, dimPaint);
    } else {
      // Dark grey for unexplored connections
      final dimPaint = Paint()
        ..strokeWidth = 1.0
        ..strokeCap = StrokeCap.round
        ..color = _unexploredLineColor.withValues(alpha: 0.3);
      canvas.drawLine(a, b, dimPaint);
    }
  }

  String _edgeKey(ZoneType a, ZoneType b) {
    final i = a.index <= b.index ? a : b;
    final j = a.index <= b.index ? b : a;
    return '${i.index}-${j.index}';
  }

  Color _darkenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness * (1 - factor)).clamp(0.0, 1.0))
        .toColor();
  }

  /// Returns the [ZoneType] closest to [tapPosition] on screen, or null if
  /// no node is within [hitRadius] pixels.
  ZoneType? hitTestNode(
    Offset tapPosition,
    Size size, {
    double hitRadius = 24.0,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) * 0.35 * scale;

    ZoneType? closest;
    double closestDist = hitRadius;

    for (var node in nodes) {
      // Rotate around X axis
      double cosX = math.cos(angleX);
      double sinX = math.sin(angleX);
      double y1 = node.y * cosX - node.z * sinX;
      double z1 = node.y * sinX + node.z * cosX;

      // Rotate around Y axis
      double cosY = math.cos(angleY);
      double sinY = math.sin(angleY);
      double x2 = node.x * cosY + z1 * sinY;

      double screenX = center.dx + x2 * radius;
      double screenY = center.dy + y1 * radius;

      final dist = (tapPosition - Offset(screenX, screenY)).distance;
      if (dist < closestDist) {
        closestDist = dist;
        closest = node.zoneType;
      }
    }

    return closest;
  }

  @override
  bool shouldRepaint(covariant SphereMapPainter oldDelegate) {
    return oldDelegate.angleX != angleX ||
        oldDelegate.angleY != angleY ||
        oldDelegate.scale != scale ||
        oldDelegate.currentZone != currentZone ||
        oldDelegate.selectedZone != selectedZone ||
        oldDelegate.highlightedDestination != highlightedDestination ||
        oldDelegate.currentDay != currentDay ||
        oldDelegate.exploredZones != exploredZones ||
        oldDelegate.adjacentZones != adjacentZones ||
        oldDelegate.merchantZones != merchantZones ||
        oldDelegate.merchantAnimValue != merchantAnimValue;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tier assignment for each zone type (0 = safe/bottom, 6 = endgame/top)
// ═══════════════════════════════════════════════════════════════════════════════
int _tierOf(ZoneType zt) {
  switch (zt) {
    // Tier 0 – Starting safe zone
    case ZoneType.town:
    case ZoneType.forest:
    case ZoneType.wasteland:
      return 0;
    // Tier 1 – Early game
    case ZoneType.neuralGarden:
    case ZoneType.dataTorrent:
    case ZoneType.deepCaves:
    case ZoneType.crystalMines:
    case ZoneType.swamp:
    case ZoneType.neonBazaar:
    case ZoneType.ironHarbor:
    case ZoneType.neonOasis:
    case ZoneType.circuitMarshes:
      return 1;
    // Tier 2 – Mid game
    case ZoneType.graveyard:
    case ZoneType.ruins:
    case ZoneType.desert:
    case ZoneType.factory:
    case ZoneType.shadowMarket:
    case ZoneType.blackMarketHub:
    case ZoneType.staticRift:
    case ZoneType.decayedGrid:
    case ZoneType.acidSprawl:
      return 2;
    // Tier 3 – Upper mid
    case ZoneType.mountain:
    case ZoneType.library:
    case ZoneType.ocean:
    case ZoneType.citadel:
    case ZoneType.chromeSpire:
    case ZoneType.plasmaFields:
    case ZoneType.solarForge:
    case ZoneType.hollowNetwork:
    case ZoneType.forgottenServer:
    case ZoneType.echoCaverns:
    case ZoneType.dataNexus:
      return 3;
    // Tier 4 – Deep / late game
    case ZoneType.tower:
    case ZoneType.chromeDocks:
    case ZoneType.skyDock:
    case ZoneType.ghostTerminal:
    case ZoneType.rustCanyon:
    case ZoneType.obsidianSpire:
    case ZoneType.scorchedPipeline:
    case ZoneType.deadSignal:
      return 4;
    // Tier 5 – Endgame
    case ZoneType.volcano:
    case ZoneType.abyss:
    case ZoneType.voidShrine:
    case ZoneType.shatteredCore:
    case ZoneType.quantumRift:
    case ZoneType.entropyWell:
    case ZoneType.voidGate:
    case ZoneType.chromeLabyrinth:
    case ZoneType.voidNexus:
    case ZoneType.deepSpire:
    case ZoneType.quantumSea:
      return 5;
    // Tier 6 – Guardian nodes (very top)
    case ZoneType.tachyonFaultline:
    case ZoneType.resonanceFault:
    case ZoneType.sanguineConduit:
    case ZoneType.phasmMirage:
    case ZoneType.zeroGVault:
    case ZoneType.cryoCompileCrypt:
    case ZoneType.highForgeMatrix:
      return 6;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helper: distribute zones on a sphere using golden spiral + equal-area tiers
//
// The sphere projection compresses points near the poles because surface
// area ∝ sin(phi). We compensate by placing each tier's latitude band
// proportional to sqrt(cumulative_fraction), which yields equal visual
// area per tier. Within each band the golden angle spreads nodes evenly.
// ═══════════════════════════════════════════════════════════════════════════════
List<SphereNode> buildSphereNodes() {
  const int numTiers = 7;
  final double goldenAngle = math.pi * (3.0 - math.sqrt(5.0)); // ~2.39996 rad

  // 1. Count zones per tier and build a sorted list
  final int totalZones = ZoneType.values.length;
  final zonesByTier = List.generate(numTiers, (_) => <ZoneType>[]);
  for (final zt in ZoneType.values) {
    zonesByTier[_tierOf(zt)].add(zt);
  }

  // Cumulative zone count up to (but not including) each tier
  final cumCount = List.filled(numTiers + 1, 0);
  for (int t = 0; t < numTiers; t++) {
    cumCount[t + 1] = cumCount[t] + zonesByTier[t].length;
  }

  // 2. Assign position to every zone using golden spiral
  final result = <SphereNode>[];

  for (int tier = 0; tier < numTiers; tier++) {
    final tierZones = zonesByTier[tier];
    if (tierZones.isEmpty) continue;

    // Latitude band boundaries using sqrt-weighting so each tier
    // gets equal visual area on the sphere surface.
    final phiTop = math.acos(
      1.0 - 2.0 * math.sqrt(cumCount[tier] / totalZones),
    );
    final phiBot = math.acos(
      1.0 - 2.0 * math.sqrt(cumCount[tier + 1] / totalZones),
    );

    for (int i = 0; i < tierZones.length; i++) {
      // Fraction within this tier's band (0 = top edge, 1 = bottom edge)
      final frac = (i + 0.5) / tierZones.length;
      final phi = phiTop + frac * (phiBot - phiTop);

      // Global golden-spiral index determines the longitude.
      // Using the global index (not per-tier) ensures nodes across
      // different tiers don't align into vertical columns.
      final globalIdx = cumCount[tier] + i;
      final theta = goldenAngle * globalIdx;

      final x = math.sin(phi) * math.cos(theta);
      final y = math.cos(phi);
      final z = math.sin(phi) * math.sin(theta);

      result.add(SphereNode(tierZones[i], x, y, z));
    }
  }

  return result;
}
