import 'dart:math' as math;
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
import '../models/status_effect.dart';
import '../widgets/game_theme.dart';
import '../widgets/stylish_popup.dart';
import '../widgets/sphere_map_painter.dart';

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
  final List<Item> inventory;
  final int maxInventorySize;

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
    this.inventory = const [],
    this.maxInventorySize = 20,
  });

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen>
    with TickerProviderStateMixin {
  // ── Sphere state ──
  double _angleX = 0.4;
  double _angleY = 0.0;
  double _scale = 1.0;
  double _baseScale = 1.0;
  bool _isDragging = false;
  late final List<SphereNode> _nodes;
  late final AnimationController _autoRotateCtrl;

  // ── Smooth zoom animation (select/deselect adjacent node) ──
  late final AnimationController _zoomAnimCtrl;
  double _zoomAnimStart = 1.0;
  double _zoomAnimEnd = 1.0;
  static const double _zoomSelectScale = 1.6;
  static const double _zoomDefaultScale = 1.0;

  // ── Recenter animation ──
  late final AnimationController _centerAnimCtrl;
  double _centerStartAngleX = 0.0;
  double _centerStartAngleY = 0.0;
  double _centerTargetAngleX = 0.0;
  double _centerTargetAngleY = 0.0;

  // ── Merchant floating icon animation ──
  late final AnimationController _merchantAnimCtrl;

  // ── Selection state ──
  ZoneType? _selectedZone; // tapped node on sphere or adjacent button
  ZoneType?
  _destinationZone; // confirmed destination for travel (two-step flow)

  int get _currentDay => widget.hoursPassed ~/ 24;

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

  List<ZoneType> get _adjacentZones =>
      Zone.worldMap[widget.currentZone]!.connections.toList();

  bool _isAdjacent(ZoneType a, ZoneType b) =>
      Zone.worldMap[a]!.connections.contains(b);

  @override
  void initState() {
    super.initState();
    _nodes = buildSphereNodes();
    _autoRotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _autoRotateCtrl.addListener(() {
      if (!_isDragging && mounted && !_centerAnimCtrl.isAnimating) {
        setState(() {
          _angleY += 0.0003;
        });
      }
    });

    // Smooth zoom animation (300ms)
    _zoomAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _zoomAnimCtrl.addListener(() {
      final t = Curves.easeInOutCubic.transform(_zoomAnimCtrl.value);
      setState(() {
        _scale = _zoomAnimStart + (_zoomAnimEnd - _zoomAnimStart) * t;
      });
    });

    // Recenter animation (400ms)
    _centerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _centerAnimCtrl.addListener(() {
      final t = Curves.easeInOutCubic.transform(_centerAnimCtrl.value);
      setState(() {
        _angleX =
            _centerStartAngleX + (_centerTargetAngleX - _centerStartAngleX) * t;
        _angleY =
            _centerStartAngleY + (_centerTargetAngleY - _centerStartAngleY) * t;
      });
    });

    // Merchant floating icon animation (continuous 2s bob)
    _merchantAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _autoRotateCtrl.dispose();
    _zoomAnimCtrl.dispose();
    _centerAnimCtrl.dispose();
    _merchantAnimCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZONE SELECTION
  // ═══════════════════════════════════════════════════════════════════════════
  void _selectAdjacentZone(ZoneType zone) {
    // Two-step flow: tap adjacent button → sets destination (highlights on sphere) → press confirm to travel
    setState(() {
      _selectedZone = zone;
      _destinationZone = zone;
    });

    // Smooth zoom in and rotate to center the destination node
    _animateZoomTo(_zoomSelectScale);
    _centerNodeOnSphere(zone);
  }

  void _clearDestination() {
    setState(() {
      _destinationZone = null;
    });

    // Smooth zoom out
    _animateZoomTo(_zoomDefaultScale);
  }

  void _animateZoomTo(double target) {
    _zoomAnimStart = _scale;
    _zoomAnimEnd = target;
    _zoomAnimCtrl.forward(from: 0.0);
  }

  void _recenterToCurrentNode() {
    _centerNodeOnSphere(widget.currentZone);
  }

  /// Rotates the sphere so that [zone] appears at the center (facing the viewer).
  void _centerNodeOnSphere(ZoneType zone) {
    final targetNode = _nodes.firstWhere(
      (n) => n.zoneType == zone,
      orElse: () => _nodes.first,
    );

    final nx = targetNode.x;
    final ny = targetNode.y;
    final nz = targetNode.z;

    // angleX to make y1 = 0 (vertically centered)
    final targetAngleX = math.atan2(ny, nz);

    // z1 after X rotation = sqrt(ny² + nz²)
    final z1 = math.sqrt(ny * ny + nz * nz);

    // angleY to place node at center of sphere (x2 = 0, facing viewer)
    final phi = math.atan2(z1, nx);
    const double targetX2 = 0.0;
    final targetAngleY = phi - math.acos(targetX2);

    // Animate from current angles to target
    _centerStartAngleX = _angleX;
    _centerStartAngleY = _angleY;
    _centerTargetAngleX = targetAngleX;
    _centerTargetAngleY = targetAngleY;
    _centerAnimCtrl.forward(from: 0.0);
  }

  void _confirmTravel() {
    if (_destinationZone == null) return;
    if (_destinationZone == widget.currentZone) return;
    if (!_isAdjacent(widget.currentZone, _destinationZone!)) return;

    widget.onZoneTravel(_destinationZone!);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION HANDLERS (preserved from original)
  // ═══════════════════════════════════════════════════════════════════════════
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
      final random = math.Random();
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

  void _handleCamp(int hours) {
    final maxHp = widget.player.effectiveMaxHp;
    final healPercent = hours >= 8 ? 100 : (hours >= 4 ? 50 : 25);
    final healAmount = ((maxHp - widget.player.hp) * healPercent / 100).round();
    widget.player.hp = (widget.player.hp + healAmount).clamp(0, maxHp);
    // Cure resting-curable status effects (bleeding, burn, poison, etc.)
    final curedEffects = widget.player.attemptCure(CureMethod.resting);
    widget.onAction('Camp', null, hours);
    if (curedEffects.isNotEmpty) {
      final names = curedEffects.map((e) => e.name).join(', ');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showStylishPopup(
            context,
            title: 'CONDITIONS CURED',
            message: names,
            icon: Icons.healing,
            iconColor: Colors.greenAccent,
          );
        }
      });
    }
  }

  void _challengeWeeklyBoss() {
    final boss = _getNextBoss();
    if (boss != null) {
      widget.onAction('Enemy', boss, 2);
    }
  }

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
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
              _campDurationOption(
                ctx,
                hours: 2,
                healPercent: 25,
                description: 'Quick rest — recover 25% HP',
                icon: Icons.nightlight_round,
                color: Colors.blue[800]!,
              ),
              const SizedBox(height: 8),
              _campDurationOption(
                ctx,
                hours: 4,
                healPercent: 50,
                description: 'Extended rest — recover 50% HP',
                icon: Icons.nights_stay,
                color: Colors.indigo[800]!,
              ),
              const SizedBox(height: 8),
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
  // GLEED'S DEN (preserved)
  // ═══════════════════════════════════════════════════════════════════════════
  void _showGleedDen() {
    bool showUnboxResult = false;
    Item? lastUnboxedItem;
    MysteryBoxTier? lastTier;

    void attemptCure(StateSetter setModalState) {
      final cost = GleedShop.gamblingCost;
      if (widget.player.credits < cost) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough credits! Need ${cost}c to gamble.',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      setModalState(() {
        widget.player.credits -= cost;
      });
      if (GleedShop.attemptGamblingCure()) {
        final winnings = cost + GleedShop.cureBonusCredits;
        setModalState(() {
          widget.player.credits += winnings;
        });
        widget.onAction('CureGleed', null, 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GLEED\'s luck rubs off — cursed! Won ${winnings}c!',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'GLEED shrugs. "Bad luck, friend. Lost ${cost}c."',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orangeAccent.withValues(alpha: 0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    void buyMysteryBox(StateSetter setModalState, MysteryBoxTier tier) {
      if (widget.player.credits < tier.price) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough credits! Need ${tier.price}c',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          ),
        );
        return;
      }
      if (widget.inventory.length >= widget.maxInventorySize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Inventory full!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orangeAccent.withValues(alpha: 0.8),
          ),
        );
        return;
      }
      setModalState(() {
        widget.player.credits -= tier.price;
        final luckMod = widget.player.getEffectiveLuck([]).toDouble();
        lastUnboxedItem = GleedShop.rollMysteryBox(tier, luckModifier: luckMod);
        lastTier = tier;
        showUnboxResult = true;
      });
    }

    void collectItem(StateSetter setModalState) {
      if (lastUnboxedItem != null) {
        widget.inventory.add(lastUnboxedItem!);
        setModalState(() {
          lastUnboxedItem = null;
          showUnboxResult = false;
          lastTier = null;
        });
      }
    }

    void scrapItem(StateSetter setModalState) {
      if (lastUnboxedItem != null) {
        setModalState(() {
          widget.player.credits += lastUnboxedItem!.sellValue;
          lastUnboxedItem = null;
          showUnboxResult = false;
          lastTier = null;
        });
      }
    }

    bool hasCureableEffects = widget.player.activeStatusEffects.any(
      (e) => e.cureMethod == CureMethod.gambling,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111522),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final currentCredits = widget.player.credits;
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (ctx, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFF111522),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: showUnboxResult && lastUnboxedItem != null
                  ? _buildGleedUnboxResult(
                      lastUnboxedItem!,
                      lastTier,
                      () => setModalState(() {
                        collectItem(setModalState);
                        Navigator.of(ctx).pop();
                      }),
                      () => scrapItem(setModalState),
                    )
                  : _buildGleedShopContent(
                      ctx,
                      scrollController,
                      currentCredits,
                      hasCureableEffects,
                      (tier) => buyMysteryBox(setModalState, tier),
                      () => attemptCure(setModalState),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGleedShopContent(
    BuildContext ctx,
    ScrollController scrollController,
    int currentCredits,
    bool hasCureableEffects,
    Function(MysteryBoxTier) onBuyBox,
    VoidCallback onAttemptCure,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GameColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amberAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text('🃏', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text(
                  '"Welcome, welcome! Step right up to GLEED\'s Den!"',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Credits: ${currentCredits}c',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'MYSTERY BOXES',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...MysteryBoxTier.values.map(
            (tier) => _buildGleedMysteryBoxCard(
              tier,
              currentCredits,
              () => onBuyBox(tier),
            ),
          ),
          const SizedBox(height: 20),
          if (hasCureableEffects) ...[
            const Text(
              'STATUS CURE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GameColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.tealAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '"Feeling cursed? A gamble might shake it off..."',
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '30% chance to cure cursed/weakened status effects',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cost: ${GleedShop.gamblingCost}c  ·  Win: ${GleedShop.gamblingCost + GleedShop.cureBonusCredits}c on success',
                    style: TextStyle(
                      color: Colors.amberAccent.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onAttemptCure,
                    child: Text(
                      'TRY YOUR LUCK (${GleedShop.gamblingCost}c)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.surface,
                foregroundColor: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'LEAVE THE DEN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGleedMysteryBoxCard(
    MysteryBoxTier tier,
    int currentCredits,
    VoidCallback onBuy,
  ) {
    final canAfford = currentCredits >= tier.price;
    final hasSpace = widget.inventory.length < widget.maxInventorySize;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford && hasSpace
              ? Colors.amberAccent.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(tier.icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.label,
                  style: TextStyle(
                    color: canAfford ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tier.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford && hasSpace
                  ? Colors.amber[800]
                  : Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: canAfford && hasSpace ? onBuy : null,
            child: Text(
              '${tier.price}c',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGleedUnboxResult(
    Item item,
    MysteryBoxTier? tier,
    VoidCallback onCollect,
    VoidCallback onScrap,
  ) {
    final color = _rarityColor(item.rarity);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(_getSlotIcon(item.type), color: color, size: 64),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tier?.label ?? 'Mystery Box',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.name,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          _rarityBadge(item.rarity),
          const SizedBox(height: 12),
          Text(
            item.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onCollect,
                  child: const Text(
                    'COLLECT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: onScrap,
                  child: Text(
                    'SCRAP (+${item.sellValue}c)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ZONE HINTS (preserved)
  // ═══════════════════════════════════════════════════════════════════════════
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
      default:
        return [
          "Explore this area carefully. There may be hidden dangers.",
          "Keep your weapons ready. Threats lurk everywhere.",
          "The deeper you go, the greater the risk — and the reward.",
          "Trust your instincts. The Ring is full of surprises.",
        ];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD — SPLIT SCREEN LAYOUT
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final currentZoneData = Zone.worldMap[widget.currentZone]!;
    final int hours = widget.hoursPassed % 24;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            if (isWide) {
              // ── LANDSCAPE: Side-by-side ──
              return Row(
                children: [
                  // Left panel: 3D sphere + adjacent buttons
                  SizedBox(
                    width: constraints.maxWidth * 0.45,
                    child: _buildSpherePanel(currentZoneData, hours),
                  ),
                  // Vertical divider
                  const VerticalDivider(width: 1, color: Colors.white10),
                  // Right panel: zone info + actions
                  Expanded(child: _buildActionPanel(currentZoneData, hours)),
                ],
              );
            } else {
              // ── PORTRAIT: Stacked ──
              return Column(
                children: [
                  // Top: 3D sphere + adjacent buttons
                  Expanded(
                    flex: 4,
                    child: _buildSpherePanel(currentZoneData, hours),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  // Bottom: zone info + actions
                  Expanded(
                    flex: 5,
                    child: _buildActionPanel(currentZoneData, hours),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEFT/TOP PANEL: 3D Sphere + Adjacent Node Buttons
  // ═══════════════════════════════════════════════════════════════════════════
  /// Compute the set of zones where traveling merchants are present
  Set<ZoneType> get _merchantZones {
    if (widget.merchantManager == null) return {};
    return widget.merchantManager!.merchants.map((m) => m.currentZone).toSet();
  }

  Widget _buildSpherePanel(Zone currentZoneData, int hours) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF0A0E1A)),
      child: Column(
        children: [
          // ── Header ──
          _buildSphereHeader(currentZoneData, hours),

          // ── 3D Sphere with overlay controls ──
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // The sphere itself
                Positioned.fill(
                  child: GestureDetector(
                    onScaleStart: (details) {
                      _baseScale = _scale;
                      _isDragging = true;
                    },
                    onScaleUpdate: (details) {
                      setState(() {
                        if (details.scale != 1.0) {
                          _scale = (_baseScale * details.scale).clamp(0.5, 2.5);
                        }
                        _angleY += details.focalPointDelta.dx * 0.008;
                        _angleX -= details.focalPointDelta.dy * 0.008;
                        _angleX = _angleX.clamp(-3.14159 / 2, 3.14159 / 2);
                      });
                    },
                    onScaleEnd: (details) {
                      _isDragging = false;
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          painter: SphereMapPainter(
                            nodes: _nodes,
                            currentZone: widget.currentZone,
                            selectedZone: _selectedZone,
                            highlightedDestination: _destinationZone,
                            currentDay: _currentDay,
                            angleX: _angleX,
                            angleY: _angleY,
                            scale: _scale,
                            merchantZones: _merchantZones,
                            merchantAnimValue: _merchantAnimCtrl.value,
                          ),
                          size: Size(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Center/Recenter button (left side) ──
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: _recenterToCurrentNode,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.cyanAccent,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Zoom slider (bottom) ──
                Positioned(
                  left: 48,
                  right: 48,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.zoom_out,
                          color: Colors.cyanAccent,
                          size: 14,
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: Colors.cyanAccent,
                              inactiveTrackColor: Colors.cyanAccent.withValues(
                                alpha: 0.2,
                              ),
                              thumbColor: Colors.cyanAccent,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                              trackHeight: 2,
                              overlayColor: Colors.cyanAccent.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            child: Slider(
                              value: _scale,
                              min: 0.5,
                              max: 2.5,
                              onChanged: (val) {
                                setState(() {
                                  _scale = val;
                                });
                              },
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.zoom_in,
                          color: Colors.cyanAccent,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Adjacent Node Buttons ──
          Expanded(flex: 2, child: _buildAdjacentNodeList()),

          // ── Confirm / Back buttons ──
          _buildTravelConfirmBar(),
        ],
      ),
    );
  }

  Widget _buildSphereHeader(Zone currentZoneData, int hours) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Icon(Icons.location_on, color: currentZoneData.color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentZoneData.name.toUpperCase(),
                  style: TextStyle(
                    color: currentZoneData.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  'DAY $_currentDay  ·  $hours:00',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app, color: Colors.cyanAccent, size: 10),
                SizedBox(width: 3),
                Text(
                  'DRAG TO ROTATE',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjacentNodeList() {
    final adjacent = _adjacentZones;
    final currentZoneData = Zone.worldMap[widget.currentZone]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.explore, color: currentZoneData.color, size: 12),
              const SizedBox(width: 4),
              Text(
                'ADJACENT SECTORS',
                style: TextStyle(
                  color: currentZoneData.color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${adjacent.length} available',
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),

        // Scrollable adjacent zone buttons
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: adjacent.length,
            separatorBuilder: (_, i) => const SizedBox(height: 3),
            itemBuilder: (context, index) {
              final zoneType = adjacent[index];
              final zone = Zone.worldMap[zoneType]!;
              final isDestination = _destinationZone == zoneType;
              return SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDestination
                        ? Colors.amberAccent.withValues(alpha: 0.2)
                        : zone.color.withValues(alpha: 0.1),
                    foregroundColor: isDestination
                        ? Colors.amberAccent
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isDestination
                            ? Colors.amberAccent
                            : zone.color.withValues(alpha: 0.35),
                        width: isDestination ? 1.5 : 1,
                      ),
                    ),
                    elevation: isDestination ? 2 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: Icon(zone.icon, color: zone.color, size: 14),
                  label: Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.name.toUpperCase(),
                          style: TextStyle(
                            color: isDestination
                                ? Colors.amberAccent
                                : Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          zone.isSettlement ? 'Settlement' : 'Dungeon',
                          style: TextStyle(
                            color: zone.color.withValues(alpha: 0.7),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onPressed: () => _selectAdjacentZone(zoneType),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTravelConfirmBar() {
    final hasDestination = _destinationZone != null;
    final destZone = hasDestination ? Zone.worldMap[_destinationZone!] : null;
    final canTravel = hasDestination && destZone != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
      decoration: const BoxDecoration(
        color: Color(0xFF111522),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Destination info
          if (hasDestination && destZone != null)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.amberAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(destZone.icon, color: Colors.amberAccent, size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Heading to ${destZone.name}',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearDestination,
                    child: Icon(
                      Icons.close,
                      color: Colors.amberAccent.withValues(alpha: 0.6),
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),

          // Buttons row
          Row(
            children: [
              // Back button
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 12),
                    label: const Text(
                      'BACK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    onPressed: widget.onCancel,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Confirm travel button
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 34,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canTravel
                          ? Colors.amberAccent
                          : Colors.grey[800]!,
                      foregroundColor: canTravel
                          ? Colors.black
                          : Colors.grey[600]!,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: canTravel ? 2 : 0,
                    ),
                    icon: Icon(
                      Icons.flight_takeoff,
                      size: 14,
                      color: canTravel ? Colors.black : Colors.grey[600],
                    ),
                    label: Text(
                      canTravel
                          ? 'TRAVEL TO ${destZone.name.toUpperCase()}'
                          : 'SELECT DESTINATION',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.6,
                        color: canTravel ? Colors.black : Colors.grey[600],
                      ),
                    ),
                    onPressed: canTravel ? _confirmTravel : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIGHT/BOTTOM PANEL: Zone Info + Action Buttons
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActionPanel(Zone currentZoneData, int hours) {
    final isSettlement = currentZoneData.isSettlement;
    final merchantsHere = widget.merchantManager != null
        ? widget.merchantManager!.getMerchantsAt(widget.currentZone)
        : <TravelingMerchant>[];
    final npcsHere = widget.npcManager != null
        ? widget.npcManager!.getNPCsAt(widget.currentZone)
        : <TravelingNPC>[];
    final hasGleedAccess = isSettlement || npcsHere.isNotEmpty;
    final zoneHints = _getZoneSpecificHints(widget.currentZone);
    final hint = zoneHints[hashCode.abs() % zoneHints.length];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111522),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          // ── Boss / Hyper Boss Warnings ──
          if (_hyperBossTomorrow) _buildHyperBossWarning(),
          if (_hasBossAvailable) _buildBossAlert(),

          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Node image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 400,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: currentZoneData.color.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        currentZoneData.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: currentZoneData.color.withValues(alpha: 0.1),
                          child: Icon(
                            currentZoneData.icon,
                            color: currentZoneData.color,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Zone name + description
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: currentZoneData.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: currentZoneData.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              currentZoneData.icon,
                              color: currentZoneData.color,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                currentZoneData.name.toUpperCase(),
                                style: TextStyle(
                                  color: currentZoneData.color,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            if (currentZoneData.isSettlement)
                              _badge('SETTLEMENT', Colors.tealAccent),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentZoneData.description,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"$hint"',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── ACTIONS header ──
                  Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: currentZoneData.color,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ACTIONS',
                        style: TextStyle(
                          color: currentZoneData.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Scout / Explore button ──
                  _buildActionButton(
                    label: 'SCOUT AREA',
                    icon: Icons.search,
                    color: Colors.red[900]!,
                    onPressed: () => _handleLocalAction('explore'),
                  ),
                  const SizedBox(height: 6),

                  // ── Camp button ──
                  _buildActionButton(
                    label: 'CAMP',
                    icon: Icons.campaign,
                    color: Colors.teal[800]!,
                    onPressed: _showCampDurationPicker,
                  ),

                  // ── Gleed's Den ──
                  if (hasGleedAccess) ...[
                    const SizedBox(height: 6),
                    _buildActionButton(
                      label: "GLEED'S DEN",
                      icon: Icons.casino,
                      color: Colors.amber[900]!,
                      onPressed: _showGleedDen,
                    ),
                  ],

                  // ── Shop ──
                  if (isSettlement || merchantsHere.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildActionButton(
                      label: merchantsHere.isNotEmpty
                          ? 'SHOP (${merchantsHere.length} merchant${merchantsHere.length > 1 ? "s" : ""})'
                          : 'SHOP',
                      icon: Icons.store,
                      color: Colors.orange[900]!,
                      onPressed: () {
                        if (merchantsHere.isNotEmpty) {
                          if (merchantsHere.length == 1) {
                            _openMerchantShop(merchantsHere.first);
                          } else {
                            _showMerchantSelection(merchantsHere);
                          }
                        } else {
                          _handleLocalAction('shop');
                        }
                      },
                    ),
                  ],

                  // ── Rest + NPC (settlement only) ──
                  if (isSettlement) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.greenAccent,
                                side: BorderSide(
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.bed, size: 14),
                              label: const Text(
                                'REST (10c)',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: widget.player.credits >= 10
                                  ? () => _handleLocalAction('rest')
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 38,
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
                              icon: const Icon(Icons.chat, size: 14),
                              label: const Text(
                                'NPC',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () => _handleLocalAction('npc'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOSS WARNINGS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHyperBossWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange.withValues(alpha: 0.25),
            Colors.red.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepOrangeAccent),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.deepOrangeAccent, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⚠️ HYPER BOSS — TOMORROW',
                  style: TextStyle(
                    color: Colors.deepOrangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Prepare your loadout.',
                  style: TextStyle(color: Colors.white60, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossAlert() {
    final boss = _getNextBoss();
    if (boss == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _challengeWeeklyBoss,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              GameColors.gold.withValues(alpha: 0.2),
              Colors.deepOrange.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameColors.gold.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: GameColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.psychology,
                color: GameColors.gold,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '⚠️ WEEKLY BOSS: ${boss.name}',
                    style: const TextStyle(
                      color: GameColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${boss.attackType.icon} ${boss.attackType.label}',
                    style: const TextStyle(color: Colors.white54, fontSize: 8),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: GameColors.gold,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'FIGHT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 8,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
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
