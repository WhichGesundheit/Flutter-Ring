import 'package:flutter/material.dart';
import 'dart:math';
import '../models/character.dart';
import '../models/item.dart';
import '../models/enemy.dart';
import '../widgets/game_image.dart';
import '../widgets/game_theme.dart';

class BattleScreen extends StatefulWidget {
  final Character player;
  final List<Item?> equippedSlots;
  final Enemy enemy;
  final Function(bool won, Item? drop) onEnd;

  const BattleScreen({
    super.key,
    required this.player,
    required this.equippedSlots,
    required this.enemy,
    required this.onEnd,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  bool isFighting = false;
  bool isPaused = false;
  bool _battleFinished = false;
  bool _battleWon = false;
  Item? _droppedGear;
  List<String> logs = [];

  int netAttack = 0;
  int netBlock = 0;
  int netLifeSteal = 0;
  int netThorns = 0;
  double netCritChance = 0.0;

  int _combatDelay = 700;
  int _speedLevel = 0;

  int _totalDamageDealt = 0;
  int _totalDamageTaken = 0;
  int _criticalHits = 0;
  int _turns = 0;

  @override
  void initState() {
    super.initState();
    _compileEquipmentStats();
    logs.add("🚨 Grid Confrontation initiated against ${widget.enemy.name}!");
  }

  void _compileEquipmentStats() {
    netAttack = widget.player.baseAttack;
    for (var item in widget.equippedSlots) {
      if (item == null) continue;
      netAttack += item.attackBonus;
      netBlock += item.damageReduction;
      netLifeSteal += item.lifeSteal;
      netThorns += item.thorns;
      netCritChance += item.critChance;
    }
  }

  void _toggleSpeed() {
    setState(() {
      _speedLevel = (_speedLevel + 1) % 3;
      _combatDelay = [700, 350, 150][_speedLevel];
    });
  }

  void _togglePause() {
    setState(() => isPaused = !isPaused);
  }

  Future<void> triggerAsyncAutoBattleTicker() async {
    if (isFighting) return;
    setState(() => isFighting = true);
    final random = Random();

    while (widget.enemy.hp > 0 && widget.player.hp > 0) {
      while (isPaused && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;
      await Future.delayed(Duration(milliseconds: _combatDelay));
      if (!mounted) return;

      setState(() {
        _turns++;

        bool isCritical = random.nextDouble() < netCritChance;
        int activeStrikePower = isCritical ? netAttack * 2 : netAttack;
        widget.enemy.hp -= activeStrikePower;
        _totalDamageDealt += activeStrikePower;
        if (isCritical) _criticalHits++;

        logs.add(
          isCritical
              ? "💥 CRITICAL STRIKE! Dealt $activeStrikePower damage!"
              : "⚔️ You strike for $activeStrikePower damage.",
        );

        if (netLifeSteal > 0 && widget.enemy.hp > 0) {
          widget.player.hp = (widget.player.hp + netLifeSteal).clamp(
            0,
            widget.player.maxHp,
          );
          logs.add("🩸 Life-Steal Sync: Restored +$netLifeSteal HP.");
        }

        if (widget.enemy.hp <= 0) {
          widget.enemy.hp = 0;
          logs.add("✅ Combat targets neutralized.");
          isFighting = false;
          _onBattleEnd(true);
          return;
        }

        int computedDamageToPlayer = (widget.enemy.attack - netBlock).clamp(
          1,
          widget.enemy.attack,
        );
        widget.player.hp -= computedDamageToPlayer;
        _totalDamageTaken += computedDamageToPlayer;
        logs.add(
          "🛡️ Enemy attacks for $computedDamageToPlayer (Blocked $netBlock).",
        );

        if (netThorns > 0) {
          widget.enemy.hp -= netThorns;
          _totalDamageDealt += netThorns;
          logs.add("🌵 Thorns Matrix: Reflected $netThorns damage.");
        }

        for (int i = 0; i < widget.equippedSlots.length; i++) {
          final item = widget.equippedSlots[i];
          if (item != null && item.isConsumable) {
            double currentHpPercent = widget.player.hp / widget.player.maxHp;
            double threshold = item.hpThreshold > 0 ? item.hpThreshold : 0.99;
            if (currentHpPercent < threshold) {
              int actualHeal = item.healAmount;
              widget.player.hp = (widget.player.hp + actualHeal).clamp(
                0,
                widget.player.maxHp,
              );
              logs.add("🧪 AUTO-USE: ${item.name} used! +$actualHeal HP.");
              widget.equippedSlots[i] = null;
              _compileEquipmentStats();
              break;
            }
          }
        }

        if (widget.player.hp <= 0) {
          widget.player.hp = 0;
          logs.add("❌ System failure. Shutting down.");
          isFighting = false;
          _onBattleEnd(false);
        }
      });
    }
  }

  void _onBattleEnd(bool won) {
    Item? drop;
    if (won && widget.enemy.potentialLoot.isNotEmpty) {
      drop = Item.rollDrop(widget.enemy.potentialLoot);
    }

    setState(() {
      _battleFinished = true;
      _battleWon = won;
      _droppedGear = drop;
      if (won) {
        widget.player.credits += widget.enemy.goldReward;
      }
    });

    _showSummaryPopup(won, drop);
  }

  void _showSummaryPopup(bool won, Item? drop) {
    final StringBuffer summary = StringBuffer();
    summary.write(won ? 'Victory!' : 'Defeated.');
    if (won) {
      summary.write('\n+${widget.enemy.goldReward} Credits');
    }
    if (drop != null) {
      summary.write('\n🎁 ${drop.name}');
    }
    summary.write('\n\n📊 Turns: $_turns  |  Dealt: $_totalDamageDealt');
    summary.write('\n   Taken: $_totalDamageTaken  |  Crits: $_criticalHits');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: won
                ? GameColors.success.withValues(alpha: 0.5)
                : GameColors.danger.withValues(alpha: 0.5),
          ),
        ),
        title: Row(
          children: [
            Icon(
              won ? Icons.emoji_events : Icons.error_outline,
              color: won ? GameColors.success : GameColors.danger,
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                won ? 'THREAT RESOLVED' : 'SYSTEM FAILURE',
                style: TextStyle(
                  color: won ? GameColors.success : GameColors.danger,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          summary.toString(),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: won ? GameColors.success : GameColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                "CONTINUE",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exitBattle() {
    if (_battleWon) {
      widget.onEnd(true, _droppedGear);
    } else {
      widget.onEnd(false, null);
    }
  }

  String get _speedLabel => ['1×', '2×', '4×'][_speedLevel];
  IconData get _speedIcon =>
      [Icons.play_arrow, Icons.fast_forward, Icons.bolt][_speedLevel];

  Widget _buildBottomButton() {
    if (_battleFinished) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _battleWon
                ? GameColors.success
                : GameColors.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          onPressed: _exitBattle,
          icon: Icon(_battleWon ? Icons.check_circle : Icons.arrow_back),
          label: Text(
            _battleWon ? "EXTRACT LOOT" : "RETREAT",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }
    if (!isFighting) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: GameColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          onPressed: triggerAsyncAutoBattleTicker,
          child: const Text(
            "INITIALIZE COMBAT",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: GameColors.primary,
            strokeWidth: 2.5,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isPaused ? "PAUSED" : "COMBAT IN PROGRESS...",
          style: TextStyle(
            color: isPaused ? GameColors.warning : GameColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 3),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        title: Text(
          _battleFinished
              ? (_battleWon ? "Victory" : "Defeated")
              : "vs ${widget.enemy.name}",
        ),
        backgroundColor: GameColors.surface,
        leading: _battleFinished
            ? IconButton(
                onPressed: _exitBattle,
                icon: const Icon(Icons.arrow_back_ios_new),
                tooltip: 'Back to Base',
              )
            : null,
        actions: [
          if (!_battleFinished)
            IconButton(
              onPressed: isFighting ? _toggleSpeed : null,
              icon: Icon(_speedIcon, color: GameColors.accent),
              tooltip: 'Speed: $_speedLabel',
            ),
          if (isFighting && !_battleFinished)
            IconButton(
              onPressed: _togglePause,
              icon: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: isPaused ? GameColors.success : GameColors.warning,
              ),
              tooltip: isPaused ? 'Resume' : 'Pause',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── COMBATANT DISPLAY ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GameImage(
                          imagePath: widget.player.imagePath,
                          fallbackIcon: Icons.person,
                          size: 48,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.player.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        HpBar(
                          current: widget.player.hp,
                          max: widget.player.maxHp,
                          height: 8,
                          showNumbers: true,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: GameColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GameColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      "VS",
                      style: TextStyle(
                        fontSize: 18,
                        color: GameColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GameImage(
                          imagePath: widget.enemy.imagePath,
                          fallbackIcon: Icons.adb,
                          size: 48,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.enemy.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        HpBar(
                          current: widget.enemy.hp,
                          max: widget.enemy.maxHp,
                          height: 8,
                          showNumbers: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── STAT SUMMARY ──
            if (isFighting || _battleFinished)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: GameColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniStat(
                        Icons.flash_on,
                        '$netAttack',
                        'ATK',
                        GameColors.primary,
                      ),
                      _miniStat(
                        Icons.shield,
                        '$netBlock',
                        'DEF',
                        GameColors.accent,
                      ),
                      _miniStat(
                        Icons.bolt,
                        '${(netCritChance * 100).toInt()}%',
                        'CRIT',
                        GameColors.gold,
                      ),
                      if (_battleFinished)
                        _miniStat(
                          Icons.compare_arrows,
                          '$_turns',
                          'TURNS',
                          Colors.white70,
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),

            // ── BATTLE LOG ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: GameColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: GameColors.border),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(4),
                    itemCount: logs.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        logs[i],
                        style: TextStyle(
                          color: logs[i].contains('💥')
                              ? GameColors.gold
                              : logs[i].contains('✅')
                              ? GameColors.success
                              : logs[i].contains('🧪')
                              ? GameColors.accent
                              : logs[i].contains('❌')
                              ? GameColors.danger
                              : Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── BOTTOM BUTTON ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildBottomButton(),
            ),
          ],
        ),
      ),
    );
  }
}
