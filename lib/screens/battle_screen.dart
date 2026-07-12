import 'package:flutter/material.dart';
import 'dart:math';
import '../models/character.dart';
import '../models/item.dart';
import '../models/enemy.dart';
import '../widgets/game_image.dart';
import '../widgets/stylish_popup.dart';

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
  List<String> logs = [];

  int netAttack = 0;
  int netBlock = 0;
  int netLifeSteal = 0;
  int netThorns = 0;
  double netCritChance = 0.0;

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

  Future<void> triggerAsyncAutoBattleTicker() async {
    if (isFighting) return;
    setState(() => isFighting = true);
    final random = Random();

    while (widget.enemy.hp > 0 && widget.player.hp > 0) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;

      setState(() {
        bool isCritical = random.nextDouble() < netCritChance;
        int activeStrikePower = isCritical ? netAttack * 2 : netAttack;
        widget.enemy.hp -= activeStrikePower;

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
          _processVictoryBonus();
          return;
        }

        int computedDamageToPlayer = (widget.enemy.attack - netBlock).clamp(
          1,
          widget.enemy.attack,
        );
        widget.player.hp -= computedDamageToPlayer;
        logs.add(
          "🛡️ Enemy attacks you for $computedDamageToPlayer (Blocked $netBlock).",
        );

        if (netThorns > 0) {
          widget.enemy.hp -= netThorns;
          logs.add("🌵 Thorns Matrix: Reflected $netThorns damage.");
        }

        // --- Auto-use Consumables Logic ---
        for (int i = 0; i < widget.equippedSlots.length; i++) {
          final item = widget.equippedSlots[i];
          if (item != null && item.isConsumable) {
            double currentHpPercent = widget.player.hp / widget.player.maxHp;
            // If hpThreshold is 0, it means it's always used if injured (or always used if healAmount > 0)
            // But per task: "if the hp is 38/50 then the item is used but if the hp is 49/50 then the item is not used"
            // So if hpThreshold is 0.0, we can assume it means "any injury" if it's meant to be automatic.
            // Let's use a default threshold of 0.99 for items without a specific threshold if they are consumables.
            double threshold = item.hpThreshold > 0 ? item.hpThreshold : 0.99;

            if (currentHpPercent < threshold) {
              int actualHeal = item.healAmount;
              widget.player.hp = (widget.player.hp + actualHeal).clamp(
                0,
                widget.player.maxHp,
              );
              logs.add(
                "🧪 AUTO-USE: ${item.name} used! Restored $actualHeal HP.",
              );
              // Consume the item
              widget.equippedSlots[i] = null;
              // Re-compile stats as an item was removed (though it only affects heal logic here)
              _compileEquipmentStats();
              break; // Use one item per turn to avoid spamming all potions
            }
          }
        }

        if (widget.player.hp <= 0) {
          widget.player.hp = 0;
          isFighting = false;
          widget.onEnd(false, null);
        }
      });
    }
  }

  void _processVictoryBonus() {
    Item? droppedGear;

    // Rarity-based drop roll: each item in the loot table is independently
    // checked against its rarity drop chance via Item.rollDrop().
    if (widget.enemy.potentialLoot.isNotEmpty) {
      droppedGear = Item.rollDrop(widget.enemy.potentialLoot);
    }

    // Build message lines
    final StringBuffer msg = StringBuffer();
    msg.write('Area secure. Extracted +${widget.enemy.goldReward} Credits.');
    if (droppedGear != null) {
      msg.write('\n\n🎁 EXTRA DROPPED SALVAGE:\n');
      msg.write('${droppedGear.name} (${droppedGear.type.name.toUpperCase()})');
    }
    msg.write('\n\n📜 BATTLE LOG:');
    for (final entry in logs) {
      msg.write('\n$entry');
    }

    showStylishResultOverlay(
      context,
      title: 'THREAT RESOLVED',
      message: msg.toString(),
      buttonLabel: 'BACK TO BASE',
      icon: Icons.emoji_events,
      iconColor: Colors.amberAccent,
      onPressed: () {
        widget.player.credits += widget.enemy.goldReward;
        widget.onEnd(true, droppedGear);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ENGAGED SIMULATION: vs ${widget.enemy.name}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    GameImage(
                      imagePath: widget.player.imagePath,
                      fallbackIcon: Icons.person,
                      size: 60,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.player.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("HP: ${widget.player.hp}/${widget.player.maxHp}"),
                  ],
                ),
                const Text(
                  "VS",
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  children: [
                    GameImage(
                      imagePath: widget.enemy.imagePath,
                      fallbackIcon: Icons.adb,
                      size: 60,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.enemy.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("HP: ${widget.enemy.hp}"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(
                    logs[i],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.enemy.hp > 0 && !isFighting)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  minimumSize: const Size.fromHeight(55),
                ),
                onPressed: triggerAsyncAutoBattleTicker,
                child: const Text("INITIALIZE AUTOMATED COMBAT LOOP"),
              ),
            if (isFighting) const CircularProgressIndicator(color: Colors.red),
          ],
        ),
      ),
    );
  }
}
