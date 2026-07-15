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
      final glowPaint = Paint()
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
        ..color = Colors.cyanAccent.withValues(alpha: 0.3);
      canvas.drawLine(a, b, glowPaint);

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
  static const double _worldSize = 1000.0;
  final Map<ZoneType, Offset> _worldPositions = {};

  void _computeWorldPositions() {
    _worldPositions.clear();
    for (final zt in ZoneType.values) {
      final rel = Zone.worldMap[zt]!.mapPosition;
      _worldPositions[zt] = Offset(rel.dx * _worldSize, rel.dy * _worldSize);
    }
  }

  bool get _hasBossAvailable {
    final currentDay = widget.hoursPassed ~/ 24;
    return WeeklyBosses.bossEncounterDays.contains(currentDay) &&
        !(widget.bossTracker?.defeatedBosses.contains(currentDay) ?? false);
  }

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

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION POPUP
  // ═══════════════════════════════════════════════════════════════════════════
  void _showActionPopup() {
    final zoneData = Zone.worldMap[widget.currentZone]!;
    final isSettlement = zoneData.isSettlement;
    final merchantsHere = widget.merchantManager != null
        ? widget.merchantManager!.getMerchantsAt(widget.currentZone)
        : <dynamic>[];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111522),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: zoneData.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: zoneData.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app, color: zoneData.color, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIONS AT ${zoneData.name.toUpperCase()}',
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
              const SizedBox(height: 16),

              // Scout Area button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text(
                    'SCOUT AREA',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleLocalAction('explore');
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Camp button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.campaign, size: 20),
                  label: const Text(
                    'CAMP',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showCampDurationPicker();
                  },
                ),
              ),

              // Shop (settlements with merchant)
              if (isSettlement && merchantsHere.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[900],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.store, size: 20),
                    label: const Text(
                      'SHOP',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _handleLocalAction('shop');
                    },
                  ),
                ),
              ],

              // Settlement extras
              if (isSettlement) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.greenAccent,
                            side: BorderSide(
                              color: Colors.greenAccent.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.bed, size: 16),
                          label: const Text(
                            'REST (10c)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: widget.player.credits >= 10
                              ? () {
                                  Navigator.of(ctx).pop();
                                  _handleLocalAction('rest');
                                }
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.lightBlueAccent,
                            side: BorderSide(
                              color: Colors.lightBlueAccent.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text(
                            'NPC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _handleLocalAction('npc');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMP DURATION PICKER
  // ═══════════════════════════════════════════════════════════════════════════
  void _showCampDurationPicker() {
    final currentHp = widget.player.hp;
    final maxHp = widget.player.effectiveMaxHp;
    final hpMissing = maxHp - currentHp;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111522),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SET CAMP',
                style: TextStyle(
                  color: Colors.tealAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'HP: $currentHp / $maxHp ($hpMissing missing)',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const SizedBox(height: 16),

              // 2 hour camp
              _campDurationOption(
                ctx,
                hours: 2,
                healPercent: 25,
                description: 'Quick rest — recover 25% HP',
                icon: Icons.nightlight_round,
                color: Colors.blue[800]!,
              ),
              const SizedBox(height: 8),

              // 4 hour camp
              _campDurationOption(
                ctx,
                hours: 4,
                healPercent: 50,
                description: 'Extended rest — recover 50% HP',
                icon: Icons.nights_stay,
                color: Colors.indigo[800]!,
              ),
              const SizedBox(height: 8),

              // 8 hour camp
              _campDurationOption(
                ctx,
                hours: 8,
                healPercent: 100,
                description: 'Full rest — recover 100% HP',
                icon: Icons.bedtime,
                color: Colors.purple[800]!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campDurationOption(
    BuildContext ctx, {
    required int hours,
    required int healPercent,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final currentHp = widget.player.hp;
    final maxHp = widget.player.effectiveMaxHp;
    final healAmount = ((maxHp - currentHp) * healPercent / 100).round();
    final newHp = (currentHp + healAmount).clamp(0, maxHp);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, size: 22),
        label: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CAMP $hours HOURS',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '$description ($currentHp→$newHp HP)',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        onPressed: () {
          Navigator.of(ctx).pop();
          _handleCamp(hours);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CAMP HANDLER
  // ═══════════════════════════════════════════════════════════════════════════
  void _handleCamp(int hours) {
    // Heal player based on duration
    final maxHp = widget.player.effectiveMaxHp;
    final healPercent = hours >= 8 ? 100 : (hours >= 4 ? 50 : 25);
    final healAmount = ((maxHp - widget.player.hp) * healPercent / 100).round();
    widget.player.hp = (widget.player.hp + healAmount).clamp(0, maxHp);

    // Trigger camp event
    widget.onAction('Camp', null, hours);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MERCHANT SHOP
  // ═══════════════════════════════════════════════════════════════════════════
  void _openMerchantShop(TravelingMerchant merchant) {
    final stock = merchant.getStock(widget.hoursPassed);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('${merchant.type.icon} ${merchant.type.label}'),
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
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
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
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
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
                                  style: const TextStyle(
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
                              style: const TextStyle(
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
          "The Binary Brush hides secrets among its fractal foliage.",
          "Poison-type enemies lurk in the forest. Bring antidotes if you can.",
          "The Deep Memory Caves lie to the west — ancient data awaits.",
          "Some say a hidden path leads from the forest to the Tech-Graveyard.",
        ];
      case ZoneType.deepCaves:
        return [
          "The caves echo with deleted memories. Void-type enemies patrol here.",
          "Dark-type creatures guard the deepest archives. Holy damage helps.",
          "The Frozen Peak is to the north — bring fire resistance.",
          "Ancient weapons lie buried in the cave walls.",
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
          "The Tech-Graveyard is haunted by ghost subroutines.",
          "Dark-type revenants patrol the rusted circuits.",
          "The Apex Citadel lies to the north.",
          "Ancient armories can be found hidden among the skeletal remains.",
        ];
      case ZoneType.citadel:
        return [
          "The Apex Citadel guards the path to the deep zones.",
          "The Core Meltdown lies to the north — only the strongest survive.",
          "Legendary merchants sometimes pass through the citadel.",
          "The Deep Net Ocean borders the east.",
        ];
      case ZoneType.ruins:
        return [
          "Rusthaven Outpost offers shelter and trade.",
          "The Silicon Dunes lie to the east.",
          "The Static Wasteland borders the north.",
          "Salvage what you can from the ruins.",
        ];
      case ZoneType.volcano:
        return [
          "The Core Meltdown is the gateway to the Abyss.",
          "Fire-type enemies dominate here. Bring ice resistance.",
          "The Apex Citadel lies to the south.",
          "The deepest secrets of the Ring lie within the volcanic fissure.",
        ];
      case ZoneType.abyss:
        return [
          "The Digital Abyss — the deepest layer. Reality unravels here.",
          "Boss-level threats lurk in the darkness.",
          "The only way back is through the Core Meltdown.",
          "Legends say the Architect's final creation sleeps here.",
        ];
      case ZoneType.swamp:
        return [
          "The Data Swamp is a quagmire of corrupted streams.",
          "The Decommissioned Factory lies to the east.",
          "The Static Wasteland borders the north.",
          "Toxic waste pools hide useful components.",
        ];
      case ZoneType.mountain:
        return [
          "The Frozen Peak crystallizes unprotected code.",
          "The Infinite Library lies to the north.",
          "The Deep Memory Caves border the south.",
          "Cold resistance is essential on the peak.",
        ];
      case ZoneType.desert:
        return [
          "The Silicon Dunes are vast and treacherous.",
          "The Decommissioned Factory lies to the east.",
          "Rusthaven Outpost borders the west.",
          "Fire-type enemies roam the dunes.",
        ];
      case ZoneType.library:
        return [
          "The Infinite Library holds forgotten algorithms.",
          "The Signal Tower lies to the north.",
          "The Frozen Peak borders the south.",
          "Research stations here can reveal enemy weaknesses.",
        ];
      case ZoneType.factory:
        return [
          "The Decommissioned Factory runs wild with corrupted automatons.",
          "The Silicon Dunes border the west.",
          "The Data Swamp lies to the south.",
          "Factory automatons drop valuable components.",
        ];
      case ZoneType.ocean:
        return [
          "The Deep Net Ocean is vast. Deleted files drift like jellyfish.",
          "The Signal Tower borders the west.",
          "The Apex Citadel lies to the east.",
          "Void-type creatures lurk in the deepest waters.",
        ];
      case ZoneType.tower:
        return [
          "The Signal Tower still broadcasts control signals.",
          "The Deep Net Ocean borders the east.",
          "The Infinite Library lies to the south.",
          "Electromagnetic pulses can disrupt your systems.",
        ];
      // New zone hints
      case ZoneType.neonBazaar:
        return [
          "Neon signs flash advertisements for illegal augments.",
          "The Bazaar's underground tunnels lead to hidden vendors.",
          "Watch your back — theft is common here.",
          "Rare commodities change hands in the shadow alleys.",
        ];
      case ZoneType.crystalMines:
        return [
          "Glowing data-crystals pulse with stored energy.",
          "Deeper tunnels hide the most valuable — and dangerous — formations.",
          "Mining drones still patrol the upper shafts.",
          "Crystal dust can enhance your gear if handled carefully.",
        ];
      case ZoneType.quantumRift:
        return [
          "Reality bends at the edges of the rift.",
          "Quantum probability makes every step unpredictable.",
          "Powerful enemies guard the rift's deepest secrets.",
          "The void leaks through — stay alert.",
        ];
      case ZoneType.shadowMarket:
        return [
          "No questions asked, no guarantees given.",
          "The Market operates in the gaps between sectors.",
          "Information is the most valuable currency here.",
          "Legendary merchants sometimes pass through.",
        ];
      case ZoneType.voidShrine:
        return [
          "The void energy is overwhelming here.",
          "Pilgrims come to meditate but rarely return unchanged.",
          "Ancient rituals still echo through the shrine.",
          "The void always demands something in return.",
        ];
      case ZoneType.chromeDocks:
        return [
          "Data-ships dock and depart on unpredictable schedules.",
          "The chrome structures gleam under artificial sunlight.",
          "Smugglers use the docks to move rare goods.",
          "The port authority maintains strict order.",
        ];
      case ZoneType.dataNexus:
        return [
          "All data streams converge at the Nexus.",
          "The combined knowledge of the Ring pulses through here.",
          "Hackers compete for access to the central servers.",
          "The Nexus holds secrets from the Ring's creation.",
        ];
      case ZoneType.ghostTerminal:
        return [
          "Residual AI consciousness haunts these terminals.",
          "The old command center still processes ancient data.",
          "Ghost signals flicker across dead screens.",
          "Something watches from the abandoned systems.",
        ];
      case ZoneType.solarForge:
        return [
          "Plasma rivers flow through abandoned assembly lines.",
          "The heat here can corrupt unprotected code.",
          "Valuable solar components lie scattered in the debris.",
          "The Forge's reactors still hum with residual power.",
        ];
      case ZoneType.neuralGarden:
        return [
          "Data grows like plants in this tranquil zone.",
          "Neural networks sprout from the ground.",
          "The fruits of information are sweet — and nutritious.",
          "A rare peaceful area in the Ring.",
        ];
      case ZoneType.circuitMarshes:
        return [
          "Toxic coolant fluid pools between rusted components.",
          "Half-submerged circuit boards make travel treacherous.",
          "The marshes hide valuable salvage beneath the surface.",
          "Chemical fog limits visibility to a few meters.",
        ];
      case ZoneType.echoCaverns:
        return [
          "Whispers from the past echo through crystalline chambers.",
          "Sound behaves strangely — footsteps come from wrong directions.",
          "Fragments of memory drift on invisible currents.",
          "The caverns hold echoes of deleted histories.",
        ];
      case ZoneType.plasmaFields:
        return [
          "Lightning strikes are constant across the open plains.",
          "The air itself glows with charged particles.",
          "Raw plasma energy can be harnessed — or destroy you.",
          "The fields stretch endlessly in every direction.",
        ];
      case ZoneType.obsidianSpire:
        return [
          "Ancient defense systems guard the upper reaches.",
          "The black glass structure pierces the clouds.",
          "Only the strongest survive the Spire's trials.",
          "Legends speak of treasures at the summit.",
        ];
      case ZoneType.voidGate:
        return [
          "The ultimate gateway — reality fractures here.",
          "Only the most powerful runners survive.",
          "The void beyond the Ring beckons.",
          "There is no turning back once you enter.",
        ];
      case ZoneType.ironHarbor:
        return [
          "Retired mercenaries offer their services for a price.",
          "The warship hulls creak in the digital wind.",
          "Rugged traders deal in weapons and armor.",
          "The harbor is defensible — a rare safe haven.",
        ];
      case ZoneType.chromeSpire:
        return [
          "Elite engineers craft the finest augmentations.",
          "Chrome plating reflects the desert sun.",
          "The Spire's workshops are legendary among runners.",
          "Augmentations here are expensive but worth it.",
        ];
      case ZoneType.neonOasis:
        return [
          "Bioluminescent pools heal weary travelers.",
          "The neon glow provides comfort in the darkness.",
          "Healers here are skilled but demand fair payment.",
          "A sanctuary for those who know where to look.",
        ];
      case ZoneType.blackMarketHub:
        return [
          "Illegal augments and forbidden data traded freely.",
          "The encrypted marketplace exists in a pocket of the Ring.",
          "Buyers and sellers use coded language.",
          "Security is minimal — trust no one.",
        ];
      case ZoneType.skyDock:
        return [
          "Airship captains barter for fuel and supplies.",
          "The floating settlement sways in the upper atmosphere.",
          "Sky-runners share tales of the world above.",
          "The view from here is breathtaking — and terrifying.",
        ];
      case ZoneType.scorchedPipeline:
        return [
          "Superheated data streams make traversal perilous.",
          "The ancient pipeline still carries residual plasma.",
          "Scorched walls tell tales of catastrophic failures.",
          "The deeper you go, the hotter it gets.",
        ];
      case ZoneType.rustCanyon:
        return [
          "Rusted remnants of ancient machines line the walls.",
          "The canyon runs deep — watch your footing.",
          "Valuable components can be salvaged from the debris.",
          "The rust here corrodes equipment rapidly.",
        ];
      case ZoneType.dataTorrent:
        return [
          "A rushing river of raw data flows through the canyon.",
          "Swim against the current to find hidden caches.",
          "The torrent carries fragments of deleted files.",
          "The water is electrified — proceed with caution.",
        ];
      case ZoneType.decayedGrid:
        return [
          "Gravity shifts unpredictably between sectors.",
          "The foundational grid has begun to collapse.",
          "Falling debris is a constant hazard.",
          "Old power conduits still spark with residual energy.",
        ];
      case ZoneType.shatteredCore:
        return [
          "Shards of crystallized data float in zero-gravity.",
          "The remnants of an ancient processing core.",
          "The overload that destroyed it left treasures behind.",
          "Zero-gravity pockets make combat unpredictable.",
        ];
      case ZoneType.forgottenServer:
        return [
          "Legacy processes still run in the abandoned servers.",
          "Treasures of the old world guard behind old firewalls.",
          "The server farm stretches endlessly in the dark.",
          "Ancient data logs reveal forgotten histories.",
        ];
      case ZoneType.acidSprawl:
        return [
          "Chemical waste has corroded everything into twisted metal.",
          "Toxic fog limits visibility to a few meters.",
          "The acid eats through unprotected equipment.",
          "Salvageable components hide beneath the corrosion.",
        ];
      case ZoneType.hollowNetwork:
        return [
          "Echoes of deleted transmissions whisper through here.",
          "The hollow conduits amplify every sound.",
          "Something moves in the darkness between channels.",
          "The network connects to forgotten sectors.",
        ];
      case ZoneType.staticRift:
        return [
          "Phantom duplicates appear from the static.",
          "Fight yourself or outsmart your echo.",
          "The rift creates copies of everything nearby.",
          "Static interference disrupts targeting systems.",
        ];
      case ZoneType.deadSignal:
        return [
          "No transmissions escape this zone.",
          "Total digital silence — the void within the void.",
          "Your instruments go dark as you enter.",
          "Only the strongest signals can penetrate.",
        ];
      case ZoneType.entropyWell:
        return [
          "Reality decomposes into base components here.",
          "The gravity well pulls everything toward the center.",
          "Data dissolves — time means nothing.",
          "The closer you get, the more reality unravels.",
        ];
      case ZoneType.chromeLabyrinth:
        return [
          "The corridors rearrange themselves every cycle.",
          "Mirrored walls create infinite reflections.",
          "The labyrinth traps the unwary forever.",
          "Only those who can read the patterns escape.",
        ];
      case ZoneType.voidNexus:
        return [
          "All void energies converge at this point.",
          "The boundary between code and flesh blurs.",
          "Reality is thinnest here — and most dangerous.",
          "The void whispers promises of ultimate power.",
        ];
      case ZoneType.deepSpire:
        return [
          "A spire that descends rather than ascends.",
          "Ancient code pulses like a heartbeat in the walls.",
          "The deeper you go, the older the code becomes.",
          "The Ring's deepest secrets lie at the bottom.",
        ];
      case ZoneType.quantumSea:
        return [
          "Every possible reality exists simultaneously.",
          "Collapse the waveform or be consumed by it.",
          "Quantum probability makes combat unpredictable.",
          "The sea of possibility holds infinite treasures.",
        ];
      default:
        return [
          "Explore this area carefully. There may be hidden dangers.",
          "Keep your weapons ready. Threats lurk everywhere.",
          "The deeper you go, the greater the risk — and the reward.",
          "Trust your instincts. The Ring is full of surprises.",
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
  // PANNABLE MAP
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
                      for (final entry in Zone.worldMap.entries)
                        _buildNodeWidget(entry.value, nodeRadius),
                      if (widget.merchantManager != null)
                        for (final merchant
                            in widget.merchantManager!.merchants)
                          _buildMerchantIndicator(merchant),
                    ],
                  ),
                ),
              ),
            ),
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
    final isAdj = _isAdjacent(widget.currentZone, merchant.currentZone);

    if (!isPlayerHere && !isAdj) return const SizedBox.shrink();

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
            isPlayerHere ? '${merchant.type.icon} ${merchant.type.label}' : '?',
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

          // Panel header
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
                if (widget.merchantManager != null)
                  _buildCurrentZoneMerchantButton(),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),

          Expanded(
            child: selectedZoneData != null
                ? _buildSelectedNodePanel(selectedZoneData)
                : _buildDefaultZonePanel(currentZoneData),
          ),

          // Back button
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
                  'BACK',
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
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.deepOrangeAccent, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                leading: Text(
                  m.type.icon,
                  style: const TextStyle(fontSize: 24),
                ),
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
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                ),
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
                    style: const TextStyle(
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
                    style: const TextStyle(color: Colors.white54, fontSize: 9),
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

          // Show zone-specific label for selected node
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GameColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GameColors.border),
            ),
            child: Text(
              isCurrent
                  ? 'You are currently in ${zone.name}.'
                  : 'Tap "TRAVEL" to move to ${zone.name}.',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),

          if (isCurrent)
            // Show action button for current zone
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
                icon: const Icon(Icons.touch_app, size: 18),
                label: Text(
                  'ACTION — ${zone.name.toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
                onPressed: _showActionPopup,
              ),
            )
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

  /// Default panel when no zone is selected — shows ACTION button for current zone
  Widget _buildDefaultZonePanel(Zone zone) {
    final zoneHints = _getZoneSpecificHints(widget.currentZone);
    final hint = zoneHints[hashCode.abs() % zoneHints.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Zone description
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GameColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: GameColors.border),
            ),
            child: Text(
              hint,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                height: 1.3,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),

          // ACTION BUTTON
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: zone.color,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.touch_app, size: 22),
              label: Text(
                'ACTION — ${zone.name.toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
              onPressed: _showActionPopup,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
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
