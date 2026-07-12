import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/enemy_pool.dart';
import '../models/zone.dart';
import '../models/character.dart';
import '../widgets/stylish_popup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Connection‑line painter – draws smooth glowing neon lines between nodes.
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectionPainter extends CustomPainter {
  final Map<ZoneType, Offset> nodePositions;
  final Set<String> _drawn;
  final int currentDay;

  _ConnectionPainter({required this.nodePositions, required this.currentDay})
    : _drawn = {};

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in Zone.worldMap.entries) {
      final fromZone = entry.value;
      final from = nodePositions[entry.key];
      if (from == null) continue;

      for (final target in fromZone.connections) {
        // Deduplicate edges (A→B and B→A).
        final key = _edgeKey(entry.key, target);
        if (_drawn.contains(key)) continue;
        _drawn.add(key);

        final to = nodePositions[target];
        if (to == null) continue;

        final bothUnlocked =
            fromZone.isUnlocked(currentDay) &&
            Zone.worldMap[target]!.isUnlocked(currentDay);

        _drawGlowLine(canvas, from, to, bothUnlocked);
      }
    }
  }

  String _edgeKey(ZoneType a, ZoneType b) {
    final i = a.index <= b.index ? a : b;
    final j = a.index <= b.index ? b : a;
    return '${i.index}-${j.index}';
  }

  void _drawGlowLine(Canvas canvas, Offset a, Offset b, bool active) {
    final paint = Paint()
      ..strokeWidth = active ? 2.4 : 1.2
      ..strokeCap = StrokeCap.round;

    if (active) {
      // Glow layer
      final glowPaint = Paint()
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
        ..color = Colors.cyanAccent.withValues(alpha: 0.25);
      canvas.drawLine(a, b, glowPaint);
      // Core line
      paint.shader = ui.Gradient.linear(a, b, [
        Colors.cyanAccent.withValues(alpha: 0.85),
        Colors.tealAccent.withValues(alpha: 0.85),
      ]);
    } else {
      paint.color = Colors.grey.withValues(alpha: 0.2);
    }

    canvas.drawLine(a, b, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter old) =>
      currentDay != old.currentDay;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulse animation for the active node.
// ─────────────────────────────────────────────────────────────────────────────
class _PulseAnimation extends StatefulWidget {
  final Widget child;
  const _PulseAnimation({required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final v = 0.85 + 0.15 * _ctrl.value;
        return Transform.scale(scale: v, child: child);
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main travel screen with the Region Exploration Matrix.
// ─────────────────────────────────────────────────────────────────────────────
class TravelScreen extends StatefulWidget {
  final int hoursPassed;
  final ZoneType currentZone;
  final Character player;
  final Function(ZoneType target) onZoneTravel;
  final Function(String type, dynamic data, int cost) onAction;
  final VoidCallback onCancel;

  const TravelScreen({
    super.key,
    required this.hoursPassed,
    required this.currentZone,
    required this.player,
    required this.onZoneTravel,
    required this.onAction,
    required this.onCancel,
  });

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  ZoneType? _selectedZone;

  int get _currentDay => widget.hoursPassed ~/ 24;
  bool _isAdjacent(ZoneType a, ZoneType b) =>
      Zone.worldMap[a]!.connections.contains(b);

  // ── Node coordinates in logical pixels (populated during layout) ──
  final Map<ZoneType, Offset> _nodeOffsets = {};

  // ── Compute pixel offset for a zone given the map area size. ──
  Offset _offsetFor(ZoneType zone, Size mapSize) {
    final rel = Zone.worldMap[zone]!.mapPosition;
    return Offset(rel.dx * mapSize.width, rel.dy * mapSize.height);
  }

  void _selectZone(ZoneType zone) {
    final zoneData = Zone.worldMap[zone]!;
    final unlocked = zoneData.isUnlocked(_currentDay);
    final isCurrent = zone == widget.currentZone;

    if (!unlocked) {
      showStylishPopup(
        context,
        title: 'SECTOR LOCKED',
        message: 'This sector is locked until Day ${zoneData.unlockDay}.',
        icon: Icons.lock_outline,
        iconColor: Colors.orangeAccent,
      );
      return;
    }

    setState(() => _selectedZone = zone);

    if (!isCurrent && !_isAdjacent(widget.currentZone, zone)) {
      showStylishPopup(
        context,
        title: 'NO DIRECT ROUTE',
        message: 'Travel through adjacent sectors first.',
        icon: Icons.route,
        iconColor: Colors.orangeAccent,
      );
    }
  }

  // ── Local actions for the current zone ──
  void _handleLocalAction(String action) {
    if (action == 'shop') {
      final random = Random();
      final pool = List<Item>.from(Item.shopLootPool)..shuffle(random);
      final count = 4 + random.nextInt(3);
      widget.onAction('Shop', pool.take(count).toList(), 0);
    } else if (action == 'rest') {
      if (widget.player.credits >= 10) {
        widget.player.credits -= 10;
        widget.onAction('Heal', null, 0);
        showStylishPopup(
          context,
          title: 'SYSTEM RESTORED',
          message: 'HP fully restored.',
          icon: Icons.favorite,
          iconColor: Colors.greenAccent,
        );
      }
    } else if (action == 'npc') {
      showStylishPopup(
        context,
        title: 'NPC',
        message: "'The binary brush is thicker than usual today...'",
        icon: Icons.chat_bubble_outline,
        iconColor: Colors.lightBlueAccent,
      );
    } else if (action == 'explore') {
      final random = Random();
      final roll = random.nextDouble();
      if (roll < 0.6) {
        final enemy = EnemyPool.getRandomStandardEnemy();
        widget.onAction('Enemy', enemy, 4);
      } else if (roll < 0.9) {
        final loot =
            Item.chestLootPool[random.nextInt(Item.chestLootPool.length)];
        widget.onAction('Loot', loot, 4);
      } else {
        showStylishPopup(
          context,
          title: 'AREA CLEAR',
          message: 'Perimeter clear. No anomalies found.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.tealAccent,
        );
        widget.onAction('Empty', null, 2);
      }
    } else if (action == 'boss') {
      final enemy = EnemyPool.getRandomBossEnemy();
      widget.onAction('Enemy', enemy, 6);
    }
  }

  // ── Travel to selected adjacent zone ──
  void _travelToZone() {
    if (_selectedZone == null) return;
    if (_selectedZone == widget.currentZone) return;
    if (!_isAdjacent(widget.currentZone, _selectedZone!)) return;

    final zoneData = Zone.worldMap[_selectedZone!]!;
    if (!zoneData.isUnlocked(_currentDay)) return;

    widget.onZoneTravel(_selectedZone!);
    setState(() => _selectedZone = null);
  }

  @override
  Widget build(BuildContext context) {
    final currentZoneData = Zone.worldMap[widget.currentZone]!;
    final int hours = widget.hoursPassed % 24;
    final selectedZoneData = _selectedZone != null
        ? Zone.worldMap[_selectedZone]!
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            _buildHeader(currentZoneData, hours),
            // ── Node Map ──
            Expanded(flex: 5, child: _buildNodeMap()),
            // ── Bottom Action Panel ──
            Expanded(
              flex: 4,
              child: _buildActionPanel(currentZoneData, selectedZoneData),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(Zone currentZoneData, int hours) {
    final int hoursLeft = 168 - widget.hoursPassed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111522),
        border: Border(
          bottom: BorderSide(
            color: currentZoneData.color.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: currentZoneData.color, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentZoneData.name.toUpperCase(),
                  style: TextStyle(
                    color: currentZoneData.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'DAY $_currentDay  ·  $hours:00  ·  COLLAPSE IN ${hoursLeft}h',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          // Back button
          GestureDetector(
            onTap: widget.onCancel,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white54,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // NODE MAP
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildNodeMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapSize = Size(constraints.maxWidth, constraints.maxHeight);
        const nodeRadius = 26.0;

        // Pre-compute pixel offsets.
        _nodeOffsets.clear();
        for (final zt in ZoneType.values) {
          _nodeOffsets[zt] = _offsetFor(zt, mapSize);
        }

        return Stack(
          children: [
            // ── Connection lines ──
            Positioned.fill(
              child: CustomPaint(
                painter: _ConnectionPainter(
                  nodePositions: _nodeOffsets,
                  currentDay: _currentDay,
                ),
              ),
            ),

            // ── Nodes ──
            for (final entry in Zone.worldMap.entries)
              _buildNodeWidget(entry.value, nodeRadius),
          ],
        );
      },
    );
  }

  Widget _buildNodeWidget(Zone zone, double radius) {
    final pos = _nodeOffsets[zone.type]!;
    final isCurrent = zone.type == widget.currentZone;
    final isSelected = zone.type == _selectedZone;
    final unlocked = zone.isUnlocked(_currentDay);
    final adjacent = _isAdjacent(widget.currentZone, zone.type);
    final canInteract = unlocked && (isCurrent || adjacent);

    // Determine visual state.
    final Color borderColor;
    final double borderWidth;
    final Color bgColor;
    final double scale;

    if (isCurrent) {
      borderColor = zone.color;
      borderWidth = 2.5;
      bgColor = zone.color.withValues(alpha: 0.18);
      scale = 1.1;
    } else if (isSelected && canInteract) {
      borderColor = Colors.cyanAccent;
      borderWidth = 2.5;
      bgColor = Colors.cyanAccent.withValues(alpha: 0.12);
      scale = 1.05;
    } else if (!unlocked) {
      borderColor = Colors.grey.withValues(alpha: 0.25);
      borderWidth = 1.5;
      bgColor = const Color(0xFF1A1D2A);
      scale = 0.9;
    } else if (adjacent) {
      borderColor = zone.color.withValues(alpha: 0.55);
      borderWidth = 1.5;
      bgColor = zone.color.withValues(alpha: 0.08);
      scale = 1.0;
    } else {
      borderColor = Colors.grey.withValues(alpha: 0.15);
      borderWidth = 1.0;
      bgColor = const Color(0xFF151828);
      scale = 0.85;
    }

    final node = GestureDetector(
      onTap: canInteract
          ? () => _selectZone(zone.type)
          : () => _selectZone(zone.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: radius * 2 * scale,
        height: radius * 2 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: (isCurrent || isSelected)
              ? [
                  BoxShadow(
                    color: (isCurrent ? zone.color : Colors.cyanAccent)
                        .withValues(alpha: 0.3),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              unlocked ? zone.icon : Icons.lock_outline,
              color: unlocked
                  ? (isCurrent ? zone.color : zone.color.withValues(alpha: 0.8))
                  : Colors.grey.withValues(alpha: 0.4),
              size: radius * 0.75,
            ),
            // Current location pulse indicator
            if (isCurrent)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: zone.color,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                ),
              ),
            // Lock badge
            if (!unlocked)
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D2A),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'D${zone.unlockDay}',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Wrap current node in pulse animation.
    Widget finalNode = isCurrent ? _PulseAnimation(child: node) : node;

    // Position on the stack.
    return Positioned(
      left: pos.dx - radius * scale,
      top: pos.dy - radius * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          finalNode,
          const SizedBox(height: 4),
          // Node label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              zone.name,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isCurrent
                    ? zone.color
                    : unlocked
                    ? Colors.white70
                    : Colors.grey.withValues(alpha: 0.5),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // "YOU ARE HERE" tag
          if (isCurrent)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: zone.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: zone.color.withValues(alpha: 0.5)),
              ),
              child: Text(
                'YOU ARE HERE',
                style: TextStyle(
                  fontSize: 6.5,
                  fontWeight: FontWeight.w800,
                  color: zone.color,
                  letterSpacing: 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ACTION PANEL
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildActionPanel(Zone currentZoneData, Zone? selectedZoneData) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111522),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          // ── Panel header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  selectedZoneData != null
                      ? Icons.info_outline
                      : Icons.touch_app,
                  color: Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  selectedZoneData != null
                      ? selectedZoneData.name.toUpperCase()
                      : 'SELECT A NODE',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          // ── Panel content ──
          Expanded(
            child: selectedZoneData != null
                ? _buildSelectedNodePanel(selectedZoneData)
                : _buildCurrentZoneActions(currentZoneData),
          ),
        ],
      ),
    );
  }

  // ── When a node is selected ──
  Widget _buildSelectedNodePanel(Zone zone) {
    final isCurrent = zone.type == widget.currentZone;
    final adjacent = _isAdjacent(widget.currentZone, zone.type);
    final unlocked = zone.isUnlocked(_currentDay);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Description
          Text(
            zone.description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),

          // Status badges
          Row(
            children: [
              if (isCurrent) _badge('CURRENT', zone.color),
              if (adjacent && !isCurrent) _badge('ADJACENT', Colors.cyanAccent),
              if (!adjacent && !isCurrent)
                _badge('NOT ADJACENT', Colors.orangeAccent),
              const Spacer(),
              Text(
                '12h travel',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Travel button or current-zone actions
          if (isCurrent)
            // Show local actions for current zone
            _buildCurrentZoneActions(zone)
          else if (adjacent && unlocked)
            // Travel button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: zone.color.withValues(alpha: 0.85),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.flight_takeoff, size: 20),
                label: Text(
                  'TRAVEL TO ${zone.name.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: _travelToZone,
              ),
            )
          else if (!unlocked)
            // Locked
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.lock, size: 18),
                label: Text(
                  'UNLOCKS ON DAY ${zone.unlockDay}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: null,
              ),
            )
          else
            // Not adjacent
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: BorderSide(
                    color: Colors.orangeAccent.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.route, size: 18),
                label: const Text(
                  'NO DIRECT ROUTE',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: null,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── When the current zone is shown (either selected or no selection) ──
  Widget _buildCurrentZoneActions(Zone zone) {
    final List<_ActionItem> actions;

    switch (zone.type) {
      case ZoneType.town:
        actions = [
          _ActionItem(
            Icons.store,
            'Supply Terminal',
            Colors.orange[900]!,
            () => _handleLocalAction('shop'),
          ),
          _ActionItem(
            Icons.bed,
            'Rest at Inn (10c)',
            Colors.green[900]!,
            () => _handleLocalAction('rest'),
            enabled: widget.player.credits >= 10,
          ),
          _ActionItem(
            Icons.chat,
            'Talk to NPC',
            Colors.blue[900]!,
            () => _handleLocalAction('npc'),
          ),
        ];
        break;
      case ZoneType.forest:
      case ZoneType.deepCaves:
        actions = [
          _ActionItem(
            Icons.search,
            'Scout Area',
            Colors.red[900]!,
            () => _handleLocalAction('explore'),
          ),
        ];
        break;
      case ZoneType.wasteland:
        actions = [
          _ActionItem(
            Icons.search,
            'Scavenge Ruins',
            Colors.deepOrange[800]!,
            () => _handleLocalAction('explore'),
          ),
        ];
        break;
      case ZoneType.graveyard:
        actions = [
          _ActionItem(
            Icons.search,
            'Salvage Components',
            Colors.red[900]!,
            () => _handleLocalAction('explore'),
          ),
        ];
        break;
      case ZoneType.citadel:
        actions = [
          _ActionItem(
            Icons.gpp_bad,
            'Challenge the Sentinel',
            Colors.amber[800]!,
            () => _handleLocalAction('boss'),
          ),
        ];
        break;
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: actions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = actions[i];
        return SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: a.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: Icon(a.icon, size: 18),
            label: Text(
              a.label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            onPressed: a.enabled ? a.onPressed : null,
          ),
        );
      },
    );
  }

  // ── Badge helper ──
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Helper data class for local actions ──
class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;

  const _ActionItem(
    this.icon,
    this.label,
    this.color,
    this.onPressed, {
    this.enabled = true,
  });
}
