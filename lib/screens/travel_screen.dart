import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/boss.dart';
import '../models/damage_type.dart';
import '../models/enemy.dart';
import '../models/item.dart';
import '../models/merchant.dart';
import '../models/enemy_pool.dart';
import '../models/zone.dart';
import '../models/character.dart';
import '../models/npc.dart';
import '../widgets/game_theme.dart';
import '../widgets/stylish_popup.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Connection-line painter – draws between nodes in world space
// ─────────────────────────────────────────────────────────────────────────────
class _ConnectionPainter extends CustomPainter {
  final Map<ZoneType, Offset> nodePositions;
  final int currentDay;

  _ConnectionPainter({required this.nodePositions, required this.currentDay});

  @override
  void paint(Canvas canvas, Size size) {
    final drawn = <String>{};

    for (final entry in Zone.worldMap.entries) {
      final fromZone = entry.value;
      final from = nodePositions[entry.key];
      if (from == null) continue;

      for (final target in fromZone.connections) {
        final key = _edgeKey(entry.key, target);
        if (drawn.contains(key)) continue;
        drawn.add(key);

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
    if (active) {
      // Glow layer
      final glowPaint = Paint()
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = Colors.cyanAccent.withValues(alpha: 0.3);
      canvas.drawLine(a, b, glowPaint);

      // Core line
      final corePaint = Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(a, b, [
          Colors.cyanAccent.withValues(alpha: 0.9),
          Colors.tealAccent.withValues(alpha: 0.9),
        ]);
      canvas.drawLine(a, b, corePaint);
    } else {
      final dimPaint = Paint()
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.grey.withValues(alpha: 0.25);
      canvas.drawLine(a, b, dimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionPainter old) =>
      currentDay != old.currentDay;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulse animation
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
// Travel screen
// ─────────────────────────────────────────────────────────────────────────────
class TravelScreen extends StatefulWidget {
  final int hoursPassed;
  final ZoneType currentZone;
  final Character player;
  final Function(ZoneType target) onZoneTravel;
  final Function(String type, dynamic data, int cost) onAction;
  final VoidCallback onCancel;
  final BossEncounterTracker? bossTracker;
  final MerchantManager? merchantManager;
  final NPCManager? npcManager;

  const TravelScreen({
    super.key,
    required this.hoursPassed,
    required this.currentZone,
    required this.player,
    required this.onZoneTravel,
    required this.onAction,
    required this.onCancel,
    this.bossTracker,
    this.merchantManager,
    this.npcManager,
  });

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  ZoneType? _selectedZone;
  final TransformationController _mapTransformController =
      TransformationController();
  final GlobalKey _mapAreaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _computeWorldPositions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnPlayer();
    });
  }

  void _centerOnPlayer() {
    final pos = _worldPositions[widget.currentZone];
    if (pos == null) return;
    final renderBox =
        _mapAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final size = renderBox.size;
    final dx = size.width / 2 - pos.dx;
    final dy = size.height / 2 - pos.dy;
    _mapTransformController.value = Matrix4.identity()
      ..setTranslationRaw(dx, dy, 0);
  }

  int get _currentDay => widget.hoursPassed ~/ 24;
  bool _isAdjacent(ZoneType a, ZoneType b) =>
      Zone.worldMap[a]!.connections.contains(b);

  // ── World-space node positions (large canvas) ──
  // We place nodes on a 1000×1000 logical canvas so there's room to pan
  static const double _worldSize = 1000.0;
  final Map<ZoneType, Offset> _worldPositions = {};

  void _computeWorldPositions() {
    _worldPositions.clear();
    for (final zt in ZoneType.values) {
      final rel = Zone.worldMap[zt]!.mapPosition;
      // Spread positions across the full world canvas
      _worldPositions[zt] = Offset(rel.dx * _worldSize, rel.dy * _worldSize);
    }
  }

  bool get _hasBossAvailable {
    final currentDay = widget.hoursPassed ~/ 24;
    return WeeklyBosses.bossEncounterDays.contains(currentDay) &&
        !(widget.bossTracker?.defeatedBosses.contains(currentDay) ?? false);
  }

  /// True on the day BEFORE a hyper boss (day 6, 13, 20, …) so the
  /// player can see a warning in advance.
  bool get _hyperBossTomorrow {
    final tomorrow = _currentDay + 1;
    return tomorrow > 0 && tomorrow % 7 == 0;
  }

  Enemy? _getNextBoss() {
    final currentDay = widget.hoursPassed ~/ 24;
    if (!_hasBossAvailable) return null;
    final week = currentDay ~/ 7 + 1;
    return WeeklyBosses.getBossForWeek(week);
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

  void _handleLocalAction(String action) {
    if (action == 'shop') {
      // The controller owns the cached stock and refreshes it every 24h.
      // We just notify it that the player wants to open the shop.
      widget.onAction('Shop', null, 0);
    } else if (action == 'gleed') {
      widget.onAction('Gleed', null, 0);
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
      final zoneData = Zone.worldMap[widget.currentZone]!;
      final zoneHints = _getZoneSpecificHints(widget.currentZone);
      final hint = zoneHints[hashCode.abs() % zoneHints.length];
      showStylishPopup(
        context,
        title: '${zoneData.name} NPC',
        message: hint,
        icon: Icons.chat_bubble_outline,
        iconColor: Colors.lightBlueAccent,
      );
    } else if (action == 'explore') {
      final random = Random();
      final roll = random.nextDouble();
      if (roll < 0.6) {
        final enemy = EnemyPool.getEnemyForZone(widget.currentZone);
        widget.onAction('Enemy', enemy, 2);
      } else if (roll < 0.9) {
        final loot =
            Item.chestLootPool[random.nextInt(Item.chestLootPool.length)];
        widget.onAction('Loot', loot, 2);
      } else {
        showStylishPopup(
          context,
          title: 'AREA CLEAR',
          message: 'Perimeter clear. No anomalies found.',
          icon: Icons.check_circle_outline,
          iconColor: Colors.tealAccent,
        );
        widget.onAction('Empty', null, 1);
      }
    }
  }

  void _challengeWeeklyBoss() {
    final boss = _getNextBoss();
    if (boss != null) {
      widget.onAction('Enemy', boss, 2);
    }
  }

  void _openMerchantShop(TravelingMerchant merchant) {
    // Use the merchant's per-24h cached stock rather than rolling fresh.
    final stock = merchant.getStock(widget.hoursPassed);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text("${merchant.type.icon} ${merchant.type.label}"),
            backgroundColor: GameColors.surface,
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: GameColors.surface,
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.type.description,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    if (merchant.type == MerchantType.legendary)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '⚠️ Prices are 2× normal cost',
                          style: TextStyle(
                            color: GameColors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Stock refreshes every 24h · Merchant moves every 48h',
                        style: TextStyle(color: Colors.white24, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: stock.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final item = stock[i];
                    final price = merchant.adjustedPrice(item);
                    final canBuy = widget.player.credits >= price;
                    final color = _rarityColor(item.rarity);
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1D2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(_getSlotIcon(item.type), color: color, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _rarityBadge(item.rarity),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canBuy
                                  ? color
                                  : Colors.grey[800],
                              foregroundColor: canBuy
                                  ? Colors.black
                                  : Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              minimumSize: const Size(0, 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            onPressed: canBuy
                                ? () {
                                    setState(() {
                                      widget.player.credits -= price;
                                      widget.onAction('BuyItem', item, 0);
                                    });
                                    showStylishPopup(
                                      context,
                                      title: 'ACQUIRED',
                                      message:
                                          '${item.name} purchased from ${merchant.type.label}.',
                                      icon: Icons.inventory_2,
                                      iconColor: color,
                                    );
                                    Navigator.of(context).pop();
                                  }
                                : null,
                            child: Text(
                              '${price}c',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GameColors.surface,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Go Back"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getZoneSpecificHints(ZoneType zone) {
    switch (zone) {
      case ZoneType.town:
        return [
          "The hub is safe, but the grid beyond is not. Stock up before you leave.",
          "Rumors say the Abyss holds the core of the Ring itself...",
          "A hyper anomaly pulses through the grid every 7 cycles. Brace yourself.",
          "Merchants at the outpost have the best gear, if you can afford it.",
        ];
      case ZoneType.forest:
        return [
          "The Binary Brush hides secrets among its fractal foliage. Watch for thorn vines.",
          "Poison-type enemies lurk in the forest. Bring antidotes if you can.",
          "The Deep Memory Caves lie to the west — ancient data awaits.",
          "Some say a hidden path leads from the forest to the Tech-Graveyard.",
        ];
      case ZoneType.deepCaves:
        return [
          "The caves echo with deleted memories. Void-type enemies patrol here.",
          "Dark-type creatures guard the deepest archives. Holy damage helps.",
          "The Frozen Peak is to the north — bring fire resistance.",
          "Ancient weapons lie buried in the cave walls. Keep your eyes open.",
        ];
      case ZoneType.wasteland:
        return [
          "The Static Wasteland is merciless. Lightning storms can strike without warning.",
          "Rusthaven Outpost lies to the west — a settlement with supplies.",
          "Electrical enemies thrive here. Ground yourself if you can.",
          "The Data Swamp borders the south. Toxic waste pools everywhere.",
        ];
      case ZoneType.graveyard:
        return [
          "The Tech-Graveyard is haunted by ghost subroutines. Holy damage is effective.",
          "Dark-type revenants patrol the rusted circuits. Be cautious.",
          "The Apex Citadel lies to the north — the last great settlement.",
          "Ancient armories can be found hidden among the skeletal remains.",
        ];
      case ZoneType.citadel:
        return [
          "The Apex Citadel guards the path to the deep zones. Prepare well.",
          "The Core Meltdown lies to the north — only the strongest survive there.",
          "Legendary merchants sometimes pass through the citadel.",
          "The Deep Net Ocean borders the east. Strange creatures lurk below.",
        ];
      case ZoneType.ruins:
        return [
          "Rusthaven Outpost offers shelter and trade. Don't rush past.",
          "The Silicon Dunes lie to the east. Sandstorms of microchips await.",
          "The Static Wasteland borders the north. Lightning strikes are common.",
          "Salvage what you can from the ruins. Every credit counts.",
        ];
      case ZoneType.volcano:
        return [
          "The Core Meltdown is the gateway to the Abyss. Only the prepared descend.",
          "Fire-type enemies dominate here. Bring ice resistance.",
          "The Apex Citadel lies to the south. Retreat is always an option.",
          "The deepest secrets of the Ring lie within the volcanic fissure.",
        ];
      case ZoneType.abyss:
        return [
          "The Digital Abyss — the deepest layer. Reality itself unravels here.",
          "Boss-level threats lurk in the darkness. Maximum preparation is essential.",
          "The only way back is through the Core Meltdown. Plan accordingly.",
          "Legends say the Architect's final creation sleeps in the deepest void.",
        ];
      case ZoneType.swamp:
        return [
          "The Data Swamp is a quagmire of corrupted streams. Poison is everywhere.",
          "The Decommissioned Factory lies to the east. Automatons guard it.",
          "The Static Wasteland borders the north. Escape is possible if needed.",
          "Toxic waste pools hide useful components. Risk vs. reward.",
        ];
      case ZoneType.mountain:
        return [
          "The Frozen Peak crystallizes unprotected code. Ice damage is common.",
          "The Infinite Library lies to the north. Knowledge is power.",
          "The Deep Memory Caves border the south. Ancient data awaits.",
          "Cold resistance is essential on the peak. Don't underestimate the frost.",
        ];
      case ZoneType.desert:
        return [
          "The Silicon Dunes are vast and treacherous. Sandstorms strip armor.",
          "The Decommissioned Factory lies to the east. Hostile automatons within.",
          "Rusthaven Outpost borders the west. Resupply if needed.",
          "Fire-type enemies roam the dunes. Heat resistance is wise.",
        ];
      case ZoneType.library:
        return [
          "The Infinite Library holds forgotten algorithms. Knowledge seekers prosper.",
          "The Signal Tower lies to the north. Ancient broadcast signals still pulse.",
          "The Frozen Peak borders the south. Ice creatures patrol the approach.",
          "Research stations here can reveal enemy weaknesses. Ask the NPCs.",
        ];
      case ZoneType.factory:
        return [
          "The Decommissioned Factory runs wild with corrupted automatons.",
          "The Silicon Dunes border the west. Lightning enemies roam there.",
          "The Data Swamp lies to the south. Toxic waste pools surround the perimeter.",
          "Factory automatons drop valuable components. Farm them if you dare.",
        ];
      case ZoneType.ocean:
        return [
          "The Deep Net Ocean is vast. Deleted files drift like bioluminescent jellyfish.",
          "The Signal Tower borders the west. Ancient broadcasts echo from its antennae.",
          "The Apex Citadel lies to the east. Resupply before venturing deeper.",
          "Void-type creatures lurk in the deepest waters. Bring holy protection.",
        ];
      case ZoneType.tower:
        return [
          "The Signal Tower still broadcasts control signals across the Ring.",
          "The Deep Net Ocean borders the east. Strange aquatic entities await.",
          "The Infinite Library lies to the south. Ancient knowledge within.",
          "Electromagnetic pulses can disrupt your systems. Shield up.",
        ];
      case ZoneType.neonBazaar:
      case ZoneType.shadowMarket:
        return [
          "The bazaars trade in rare commodities. Prices are steep, but the gear is worth it.",
          "Black market dealers know things the settlements don't. Ask around.",
          "Watch your back in the markets. Not everyone plays fair.",
          "Rare items pass through the bazaars. Check back often.",
        ];
      case ZoneType.crystalMines:
      case ZoneType.echoCaverns:
        return [
          "The mines hold valuable crystals. Deeper veins are more dangerous.",
          "Echo caverns carry whispers of the past. Listen carefully.",
          "Crystal formations can boost your gear. Mine carefully.",
          "The deeper you go, the richer the veins — and the deadlier the guardians.",
        ];
      case ZoneType.quantumRift:
      case ZoneType.voidShrine:
      case ZoneType.voidGate:
        return [
          "The void zones are the most dangerous. Maximum preparation required.",
          "Reality fractures in the void. Keep your systems shielded.",
          "The void gate is the final challenge. Only the strongest survive.",
          "Pilgrims seek the shrine for power, but the void demands sacrifice.",
        ];
      case ZoneType.chromeDocks:
        return [
          "The chrome docks are a hub for smugglers and traders.",
          "Data-ships bring rare cargo from distant sectors.",
          "The docks are well-guarded, but the surrounding areas are dangerous.",
          "Rare salvage washes up on the docks. Keep your eyes open.",
        ];
      case ZoneType.dataNexus:
        return [
          "The data nexus holds the Ring's collective knowledge.",
          "Ancient algorithms power the nexus. Study them well.",
          "The nexus connects all sectors. It's a strategic hub.",
          "Data streams flow through here constantly. Information is power.",
        ];
      case ZoneType.ghostTerminal:
        return [
          "The ghost terminal still processes data from a forgotten age.",
          "Residual AI consciousness haunts the terminals. Be cautious.",
          "Ancient commands still echo through the terminal. Listen carefully.",
          "The ghost terminal holds secrets of the Ring's early days.",
        ];
      case ZoneType.solarForge:
      case ZoneType.plasmaFields:
        return [
          "The solar forge harnesses raw stellar energy. It's volatile.",
          "Plasma fields crackle with charged particles. Fire resistance helps.",
          "The forge once built the Ring's outer shell. Its secrets remain.",
          "Energy-based enemies thrive in the plasma fields.",
        ];
      case ZoneType.neuralGarden:
        return [
          "The neural garden grows data like plants. Some fruits are poisonous.",
          "Neural networks sprout from the ground here. Harvest carefully.",
          "The garden is peaceful, but its guardians are fierce.",
          "Rare information fruits grow in the garden's deepest reaches.",
        ];
      case ZoneType.circuitMarshes:
        return [
          "The circuit marshes are toxic. Bring protection.",
          "Half-submerged circuits hide useful components.",
          "Toxic coolant pools surround the marshes. Don't fall in.",
          "Salvage what you can, but don't linger too long.",
        ];
      case ZoneType.obsidianSpire:
        return [
          "The obsidian spire pierces the clouds. Ancient defenses still guard it.",
          "The spire's upper reaches hold the most valuable loot.",
          "Defense systems in the spire are lethal. Proceed with extreme caution.",
          "The spire is a gateway to the deepest zones. Prepare well.",
        ];
    }
  }

  void _travelToZone() {
    if (_selectedZone == null) return;
    if (_selectedZone == widget.currentZone) return;
    if (!_isAdjacent(widget.currentZone, _selectedZone!)) return;

    final zoneData = Zone.worldMap[_selectedZone!]!;
    if (!zoneData.isUnlocked(_currentDay)) return;

    widget.onZoneTravel(_selectedZone!);
    if (mounted) {
      setState(() => _selectedZone = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    _computeWorldPositions();

    final currentZoneData = Zone.worldMap[widget.currentZone]!;
    final int hours = widget.hoursPassed % 24;
    final selectedZoneData = _selectedZone != null
        ? Zone.worldMap[_selectedZone!]
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(currentZoneData, hours),
            Expanded(flex: 5, child: _buildPannableMap()),
            Expanded(
              flex: 4,
              child: _buildActionPanel(currentZoneData, selectedZoneData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Zone currentZoneData, int hours) {
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
                  'DAY $_currentDay  ·  $hours:00',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // PANNABLE MAP – unlimited pan, large world canvas
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildPannableMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const nodeRadius = 20.0;

        return Stack(
          children: [
            ClipRRect(
              key: _mapAreaKey,
              borderRadius: BorderRadius.circular(8),
              child: InteractiveViewer(
                transformationController: _mapTransformController,
                constrained: false,
                minScale: 0.2,
                maxScale: 3.0,
                boundaryMargin: const EdgeInsets.all(2000),
                child: SizedBox(
                  width: _worldSize,
                  height: _worldSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ── Connection lines ──
                      Positioned(
                        left: 0,
                        top: 0,
                        width: _worldSize,
                        height: _worldSize,
                        child: CustomPaint(
                          painter: _ConnectionPainter(
                            nodePositions: _worldPositions,
                            currentDay: _currentDay,
                          ),
                        ),
                      ),

                      // ── Nodes ──
                      for (final entry in Zone.worldMap.entries)
                        _buildNodeWidget(entry.value, nodeRadius),

                      // ── Merchant indicators ──
                      if (widget.merchantManager != null)
                        for (final merchant
                            in widget.merchantManager!.merchants)
                          _buildMerchantIndicator(merchant),
                    ],
                  ),
                ),
              ),
            ),

            // ── Floating center-map button (top left) ──
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: _centerOnPlayer,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111522).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.center_focus_strong,
                    color: Colors.white54,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMerchantIndicator(TravelingMerchant merchant) {
    final nodePos = _worldPositions[merchant.currentZone];
    if (nodePos == null) return const SizedBox.shrink();

    final isPlayerHere = widget.currentZone == merchant.currentZone;
    final isAdjacent = _isAdjacent(widget.currentZone, merchant.currentZone);

    // Hide merchant indicator if not at same zone or adjacent
    if (!isPlayerHere && !isAdjacent) return const SizedBox.shrink();

    return Positioned(
      left: nodePos.dx - 8,
      top: nodePos.dy - 32,
      child: GestureDetector(
        onTap: isPlayerHere
            ? () => _openMerchantShop(merchant)
            : () {
                showStylishPopup(
                  context,
                  title: '???',
                  message: 'Unknown',
                  icon: Icons.help_outline,
                  iconColor: Colors.grey,
                );
              },
        child: Container(
          padding: isPlayerHere
              ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
              : const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isPlayerHere
                ? (merchant.type == MerchantType.legendary
                      ? GameColors.gold.withValues(alpha: 0.9)
                      : Colors.tealAccent.withValues(alpha: 0.8))
                : Colors.grey.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(isPlayerHere ? 5 : 12),
            boxShadow: isPlayerHere
                ? [
                    BoxShadow(
                      color:
                          (merchant.type == MerchantType.legendary
                                  ? GameColors.gold
                                  : Colors.tealAccent)
                              .withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Text(
            isPlayerHere ? "${merchant.type.icon} ${merchant.type.label}" : '?',
            style: TextStyle(
              fontSize: isPlayerHere ? 7 : 16,
              fontWeight: FontWeight.w900,
              color: isPlayerHere
                  ? (merchant.type == MerchantType.legendary
                        ? Colors.black
                        : Colors.black87)
                  : Colors.grey[300],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeWidget(Zone zone, double radius) {
    final pos = _worldPositions[zone.type]!;
    final isCurrent = zone.type == widget.currentZone;
    final isSelected = zone.type == _selectedZone;
    final unlocked = zone.isUnlocked(_currentDay);
    final adjacent = _isAdjacent(widget.currentZone, zone.type);
    final canInteract = unlocked && (isCurrent || adjacent);

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
      onTap: () => _selectZone(zone.type),
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
            if (isCurrent)
              Positioned(
                top: -8,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: pi / 4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: zone.color,
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: zone.color.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
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

    Widget finalNode = isCurrent ? _PulseAnimation(child: node) : node;

    return Positioned(
      left: pos.dx - radius * scale,
      top: pos.dy - radius * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          finalNode,
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A).withValues(alpha: 0.9),
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
                letterSpacing: 0.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
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
          if (_hyperBossTomorrow) _buildHyperBossWarning(),
          if (_hasBossAvailable) _buildBossAlert(),

          // Panel header with merchant indicator
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
                Expanded(
                  child: Text(
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
                ),
                // Show merchant access button only when player is at merchant's zone
                if (widget.merchantManager != null)
                  _buildCurrentZoneMerchantButton(),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          Expanded(
            child: selectedZoneData != null
                ? _buildSelectedNodePanel(selectedZoneData)
                : _buildCurrentZoneActions(currentZoneData),
          ),

          // ── Back button (floating at bottom) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white54,
                  side: BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                label: const Text(
                  'BACK TO BASE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: widget.onCancel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHyperBossWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange.withValues(alpha: 0.25),
            Colors.red.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepOrangeAccent),
        boxShadow: [
          BoxShadow(
            color: Colors.deepOrange.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.deepOrangeAccent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber,
              color: Colors.deepOrangeAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '⚠️ HYPER BOSS INCOMING — TOMORROW',
                  style: TextStyle(
                    color: Colors.deepOrangeAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Prepare your loadout. Retreat will not be an option.',
                  style: TextStyle(color: Colors.white60, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentZoneMerchantButton() {
    final merchantsHere = widget.merchantManager!.getMerchantsAt(
      widget.currentZone,
    );
    if (merchantsHere.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        // Show merchant selection if multiple
        if (merchantsHere.length == 1) {
          _openMerchantShop(merchantsHere.first);
        } else {
          _showMerchantSelection(merchantsHere);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.tealAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🛒 ', style: TextStyle(fontSize: 10)),
            Text(
              'SHOP (${merchantsHere.length})',
              style: const TextStyle(
                color: Colors.tealAccent,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMerchantSelection(List<TravelingMerchant> merchants) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111522),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'MERCHANTS IN AREA',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ...merchants.map(
              (m) => ListTile(
                leading: Text(m.type.icon, style: TextStyle(fontSize: 24)),
                title: Text(
                  m.type.label,
                  style: TextStyle(
                    color: m.type == MerchantType.legendary
                        ? GameColors.gold
                        : Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  m.type.description,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.white38),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openMerchantShop(m);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildBossAlert() {
    final boss = _getNextBoss();
    if (boss == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _challengeWeeklyBoss,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GameColors.gold.withValues(alpha: 0.2),
              Colors.deepOrange.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GameColors.gold.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: GameColors.gold.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GameColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                color: GameColors.gold,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⚠️ WEEKLY BOSS: ${boss.name}',
                    style: TextStyle(
                      color: GameColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${boss.attackType.icon} ${boss.attackType.label} · '
                    'Immune: ${boss.immunities.map((d) => d.icon).join(" ")}',
                    style: TextStyle(color: Colors.white54, fontSize: 9),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: GameColors.gold,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'FIGHT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedNodePanel(Zone zone) {
    final isCurrent = zone.type == widget.currentZone;
    final adjacent = _isAdjacent(widget.currentZone, zone.type);
    final unlocked = zone.isUnlocked(_currentDay);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            zone.description,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              if (isCurrent) _badge('CURRENT', zone.color),
              if (adjacent && !isCurrent) _badge('ADJACENT', Colors.cyanAccent),
              if (!adjacent && !isCurrent)
                _badge('NOT ADJACENT', Colors.orangeAccent),
              const Spacer(),
              const Text(
                '2h travel',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (isCurrent)
            _buildCurrentZoneActions(zone)
          else if (adjacent && unlocked)
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: zone.color.withValues(alpha: 0.85),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.flight_takeoff, size: 18),
                label: Text(
                  'TRAVEL TO ${zone.name.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: _travelToZone,
              ),
            )
          else if (!unlocked)
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.lock, size: 16),
                label: Text(
                  'UNLOCKS ON DAY ${zone.unlockDay}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: null,
              ),
            )
          else
            SizedBox(
              height: 44,
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
                icon: const Icon(Icons.route, size: 16),
                label: const Text(
                  'NO DIRECT ROUTE',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: null,
              ),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildCurrentZoneActions(Zone zone) {
    final List<_ActionItem> actions;

    if (zone.isSettlement) {
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
        _ActionItem(
          Icons.casino,
          "GLEED's Den",
          Colors.amber[800]!,
          () => _handleLocalAction('gleed'),
        ),
      ];
    } else {
      switch (zone.type) {
        case ZoneType.forest:
        case ZoneType.deepCaves:
        case ZoneType.mountain:
        case ZoneType.library:
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
        case ZoneType.desert:
        case ZoneType.volcano:
        case ZoneType.factory:
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
        case ZoneType.ocean:
          actions = [
            _ActionItem(
              Icons.search,
              'Salvage Components',
              Colors.red[900]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.swamp:
          actions = [
            _ActionItem(
              Icons.search,
              'Forage Data',
              Colors.teal[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.tower:
          actions = [
            _ActionItem(
              Icons.search,
              'Salvage Components',
              Colors.red[900]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.abyss:
          actions = [
            _ActionItem(
              Icons.search,
              'Descend Deeper',
              Colors.deepPurple[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        // New zones
        case ZoneType.neonBazaar:
        case ZoneType.shadowMarket:
          actions = [
            _ActionItem(
              Icons.store,
              'Visit Market',
              Colors.pink[900]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.crystalMines:
        case ZoneType.echoCaverns:
          actions = [
            _ActionItem(
              Icons.diamond,
              'Mine Crystals',
              Colors.cyan[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.quantumRift:
        case ZoneType.voidShrine:
        case ZoneType.voidGate:
          actions = [
            _ActionItem(
              Icons.blur_on,
              'Explore the Void',
              Colors.purple[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.chromeDocks:
          actions = [
            _ActionItem(
              Icons.sailing,
              'Scavenge Docks',
              Colors.blueGrey[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.dataNexus:
          actions = [
            _ActionItem(
              Icons.device_hub,
              'Scan Data Streams',
              Colors.blue[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.ghostTerminal:
          actions = [
            _ActionItem(
              Icons.computer,
              'Investigate Terminal',
              Colors.green[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.solarForge:
        case ZoneType.plasmaFields:
          actions = [
            _ActionItem(
              Icons.electric_bolt,
              'Scavenge Energy',
              Colors.orange[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.neuralGarden:
          actions = [
            _ActionItem(
              Icons.eco,
              'Forage Data',
              Colors.lightGreen[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.circuitMarshes:
          actions = [
            _ActionItem(
              Icons.water,
              'Salvage Components',
              Colors.brown[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        case ZoneType.obsidianSpire:
          actions = [
            _ActionItem(
              Icons.apartment,
              'Ascend Spire',
              Colors.grey[800]!,
              () => _handleLocalAction('explore'),
            ),
          ];
          break;
        // Settlements (town, ruins, citadel) are handled above by isSettlement check.
        case ZoneType.town:
        case ZoneType.ruins:
        case ZoneType.citadel:
          actions = [];
          break;
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: actions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = actions[i];
        return SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: a.color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: Icon(a.icon, size: 16),
            label: Text(
              a.label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            onPressed: a.enabled ? a.onPressed : null,
          ),
        );
      },
    );
  }

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

  Color _rarityColor(Rarity r) {
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

  Widget _rarityBadge(Rarity r) {
    final color = _rarityColor(r);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        r.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  IconData _getSlotIcon(SlotType type) {
    switch (type) {
      case SlotType.head:
        return Icons.military_tech;
      case SlotType.armor:
        return Icons.shield;
      case SlotType.weapon:
        return Icons.gavel;
      case SlotType.item:
        return Icons.hardware;
    }
  }
}

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
