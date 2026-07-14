import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/damage_type.dart';
import '../models/item.dart';
import '../models/zone.dart';
import '../widgets/game_image.dart';
import '../widgets/game_theme.dart';
import '../widgets/status_effect_display.dart';

class MainScreen extends StatelessWidget {
  final Character player;
  final int hoursPassed;
  final ZoneType currentZone;
  final List<Item?> equippedSlots;
  final Function(String) onChangeScreen;

  const MainScreen({
    super.key,
    required this.player,
    required this.hoursPassed,
    required this.currentZone,
    required this.equippedSlots,
    required this.onChangeScreen,
  });

  @override
  Widget build(BuildContext context) {
    final int days = hoursPassed ~/ 24;
    final int hours = hoursPassed % 24;

    // Compute effective stats from equipment
    int totalAtk = player.baseAttack + player.statusAttackModifier;
    int totalBlock = player.statusDefenseModifier;
    int totalLifeSteal = 0;
    int totalThorns = 0;
    double totalCrit = 0.0;
    int totalLuck = 0;
    Map<DamageType, int> totalBonusDamage = {};
    Map<DamageType, int> totalResistances = {};

    for (var item in equippedSlots) {
      if (item == null) continue;
      totalAtk += item.effectiveAttackBonus;
      totalBlock += item.effectiveDamageReduction;
      totalLifeSteal += item.effectiveLifeSteal;
      totalThorns += item.effectiveThorns;
      totalCrit += item.effectiveCritChance;
      totalLuck += item.effectiveLuckBonus;

      item.effectiveBonusDamage.forEach((type, value) {
        totalBonusDamage[type] = (totalBonusDamage[type] ?? 0) + value;
      });

      item.effectiveFlatResistance.forEach((type, value) {
        totalResistances[type] = (totalResistances[type] ?? 0) + value;
      });
    }

    totalCrit += totalLuck * 0.01;
    totalLuck += player.statusLuckModifier.round();

    final zoneData = Zone.worldMap[currentZone]!;

    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── TIME & ZONE DISPLAY ──
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GameColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GameColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "DAY $days  ·  $hours:00",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    zoneData.icon,
                                    color: zoneData.color,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    zoneData.name.toUpperCase(),
                                    style: TextStyle(
                                      color: zoneData.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: GameColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "ONGOING RUN",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: GameColors.accent,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── PLAYER CARD ──
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GameColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GameColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              StatusEffectDisplay(
                                effects: player.activeStatusEffects,
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.25,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.3,
                                  child: GameImage(
                                    imagePath: player.imagePath,
                                    fallbackIcon: Icons.person,
                                    size:
                                        MediaQuery.of(context).size.height *
                                        0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const SizedBox(width: 36),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            player.className,
                            style: TextStyle(
                              color: GameColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // HP Bar
                          HpBar(
                            current: player.hp,
                            max: player.effectiveMaxHp,
                            height: 12,
                            showLabel: true,
                            showNumbers: true,
                          ),
                          const SizedBox(height: 10),

                          // Credits
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: GameColors.gold,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${player.credits} Credits',
                                style: TextStyle(
                                  color: GameColors.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── DETAILED STATS ──
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GameColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GameColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COMBAT STATS',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatGrid(context, [
                            _StatItem(
                              '⚔️',
                              'ATK',
                              '$totalAtk',
                              GameColors.primary,
                              'Attack Power',
                              'The base damage you deal per turn in combat.',
                              'Base ATK (${player.baseAttack}) + Equipment Bonus + Status Effects = $totalAtk',
                            ),
                            _StatItem(
                              '🛡️',
                              'DEF',
                              '$totalBlock',
                              GameColors.accent,
                              'Damage Reduction',
                              'Flat damage subtracted from every enemy attack.',
                              'Each point of DEF reduces incoming damage by 1.\nCurrent: $totalBlock flat reduction.',
                            ),
                            _StatItem(
                              '💥',
                              'CRIT',
                              '${(totalCrit * 100).toInt()}%',
                              GameColors.gold,
                              'Critical Hit Chance',
                              'Chance to deal 2× damage on an attack.',
                              'Crit = Equipment Crit% + (Luck × 1%)\n= ${(totalCrit * 100).toInt()}% chance to deal double damage.',
                            ),
                            _StatItem(
                              '🍀',
                              'LUCK',
                              '$totalLuck',
                              Colors.lightGreen,
                              'Luck',
                              'Increases crit chance (+1% per point), drop rates, and event outcomes.',
                              'Each Luck point adds +1% crit chance and +2% drop chance.\nTotal Luck: $totalLuck',
                            ),
                            if (totalLifeSteal > 0)
                              _StatItem(
                                '🩸',
                                'STEAL',
                                '$totalLifeSteal',
                                Colors.redAccent,
                                'Life Steal',
                                'Heals you for this amount after every successful attack.',
                                'After each attack, heal for $totalLifeSteal HP.\nCannot exceed max HP.',
                              ),
                            if (totalThorns > 0)
                              _StatItem(
                                '🌵',
                                'THORN',
                                '$totalThorns',
                                Colors.green,
                                'Thorns',
                                'Deals flat damage back to the enemy every turn, even when hit.',
                                'Each turn, reflect $totalThorns damage to the attacker.\nApplied after enemy attacks.',
                              ),
                          ]),
                          if (totalBonusDamage.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'BONUS DAMAGE',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: totalBonusDamage.entries
                                  .map(
                                    (e) => GestureDetector(
                                      onTap: () => _showDamageTypePopup(
                                        context,
                                        e.key,
                                        e.value,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: e.key.color.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: e.key.color.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '${e.key.icon} ${e.key.label}: +${e.value}',
                                          style: TextStyle(
                                            color: e.key.color,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                          if (totalResistances.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'RESISTANCES',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: totalResistances.entries
                                  .map(
                                    (e) => GestureDetector(
                                      onTap: () => _showResistancePopup(
                                        context,
                                        e.key,
                                        e.value,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: e.key.color.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: e.key.color.withValues(
                                              alpha: 0.4,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          '${e.key.icon} ${e.key.label}: +${e.value}',
                                          style: TextStyle(
                                            color: e.key.color,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── ACTION BUTTONS (fixed at bottom, don't scroll) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: GameColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: GameColors.primary.withValues(alpha: 0.4),
                      ),
                      onPressed: () => onChangeScreen('travel'),
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
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: GameColors.accent,
                        side: BorderSide(
                          color: GameColors.accent.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => onChangeScreen('inventory'),
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatPopup(
    BuildContext context,
    String icon,
    String label,
    String value,
    Color color,
    String title,
    String description,
    String formula,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Current: $value',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                formula,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showDamageTypePopup(BuildContext context, DamageType type, int value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: type.color.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              type.label,
              style: TextStyle(
                color: type.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type.effectDescription,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: type.color.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Bonus Damage: +$value\nReduces enemy HP by $value each attack (before crit).',
                style: TextStyle(
                  color: type.color,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showResistancePopup(BuildContext context, DamageType type, int value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: type.color.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              '${type.label} Resistance',
              style: TextStyle(
                color: type.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reduces incoming ${type.label} damage by $value flat.\n\n'
              'Applied before other damage modifiers.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: type.color.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Enemy ${type.label} attack - $value resistance = Actual damage\n'
                'Minimum damage is always 1.',
                style: TextStyle(
                  color: type.color,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, List<_StatItem> stats) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats
          .map(
            (s) => GestureDetector(
              onTap: () => _showStatPopup(
                context,
                s.icon,
                s.label,
                s.value,
                s.color,
                s.title,
                s.description,
                s.formula,
              ),
              child: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: s.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      s.value,
                      style: TextStyle(
                        color: s.color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: s.color.withValues(alpha: 0.7),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatItem {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final String title;
  final String description;
  final String formula;

  const _StatItem(
    this.icon,
    this.label,
    this.value,
    this.color,
    this.title,
    this.description,
    this.formula,
  );
}
