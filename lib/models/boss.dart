import 'dart:math';

import 'damage_type.dart';
import 'enemy.dart';
import 'item.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// WEEKLY BOSS DEFINITIONS – 10 unique bosses with unique mechanics
/// Each boss appears on a rotating basis, getting stronger every week
/// ═══════════════════════════════════════════════════════════════════════════════
class WeeklyBosses {
  static final Random _random = Random();

  static Item _pick(Rarity r) {
    final pool = Item.chestLootPool.where((i) => i.rarity == r).toList();
    return pool[_random.nextInt(pool.length)];
  }

  /// All 10 weekly bosses in order
  static final List<Enemy Function(int week)> allBosses = [
    // Week 1: CIPHER SENTINEL – Physical, immune to Physical, reflects damage
    (week) => Enemy(
      name: 'CIPHER SENTINEL',
      description:
          'An ancient firewall guardian that reflects intruder protocols back at their source.',
      hp: 120,
      maxHp: 120,
      attack: 12,
      goldReward: 80,
      potentialLoot: [
        _pick(Rarity.unique),
        _pick(Rarity.unique),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.physical,
      immunities: [DamageType.physical],
      mechanic: BossMechanic.damageReflection,
      mechanicValue: 20,
      bossTier: 1,
    ),

    // Week 2: INFERNO CORE – Fire, immune to Fire, burns player
    (week) => Enemy(
      name: 'INFERNO CORE',
      description:
          'A molten processing core that radiates searing data-flames, igniting all intruders.',
      hp: 140,
      maxHp: 140,
      attack: 14,
      goldReward: 90,
      potentialLoot: [
        _pick(Rarity.unique),
        _pick(Rarity.unique),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.fire,
      immunities: [DamageType.fire],
      mechanic: BossMechanic.burn,
      mechanicValue: 4,
      bossTier: 2,
    ),

    // Week 3: FROST WRAITH – Ice, immune to Ice, freezes player
    (week) => Enemy(
      name: 'FROST WRAITH',
      description:
          'A sub-zero entity from frozen memory banks. Its touch crystallizes neural pathways.',
      hp: 160,
      maxHp: 160,
      attack: 13,
      goldReward: 100,
      potentialLoot: [
        _pick(Rarity.unique),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.ice,
      immunities: [DamageType.ice],
      mechanic: BossMechanic.freeze,
      mechanicValue: 3,
      bossTier: 3,
    ),

    // Week 4: STORM TITAN – Lightning, immune to Lightning, chain strike
    (week) => Enemy(
      name: 'STORM TITAN',
      description:
          'A towering electrical anomaly that channels devastating chain-lightning through the grid.',
      hp: 180,
      maxHp: 180,
      attack: 16,
      goldReward: 110,
      potentialLoot: [
        _pick(Rarity.unique),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.lightning,
      immunities: [DamageType.lightning],
      mechanic: BossMechanic.chainStrike,
      mechanicValue: 2,
      bossTier: 4,
    ),

    // Week 5: PLAGUE VECTOR – Poison, immune to Poison, poisons player
    (week) => Enemy(
      name: 'PLAGUE VECTOR',
      description:
          'A self-replicating viral construct that corrupts and degrades organic code over time.',
      hp: 200,
      maxHp: 200,
      attack: 15,
      goldReward: 120,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.poison,
      immunities: [DamageType.poison],
      mechanic: BossMechanic.poison,
      mechanicValue: 5,
      bossTier: 5,
    ),

    // Week 6: VOID SOVEREIGN – Void, immune to Void, drains max HP
    (week) => Enemy(
      name: 'VOID SOVEREIGN',
      description:
          'A monarch of deleted space that consumes the very foundation of your existence.',
      hp: 220,
      maxHp: 220,
      attack: 18,
      goldReward: 130,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.void_,
      immunities: [DamageType.void_],
      mechanic: BossMechanic.drainMaxHp,
      mechanicValue: 3,
      bossTier: 6,
    ),

    // Week 7: SERAPH GUARDIAN – Holy, immune to Holy, heals each turn
    (week) => Enemy(
      name: 'SERAPH GUARDIAN',
      description:
          'A divine security protocol that regenerates endlessly, purging all corruption with holy light.',
      hp: 250,
      maxHp: 250,
      attack: 17,
      goldReward: 140,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.holy,
      immunities: [DamageType.holy],
      mechanic: BossMechanic.heal,
      mechanicValue: 10,
      bossTier: 7,
    ),

    // Week 8: UMBRA LORD – Dark, immune to Dark, enrage mechanic
    (week) => Enemy(
      name: 'UMBRA LORD',
      description:
          'A lord of shadow protocols that grows exponentially more dangerous as its prey weakens.',
      hp: 280,
      maxHp: 280,
      attack: 20,
      goldReward: 150,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.dark,
      immunities: [DamageType.dark],
      mechanic: BossMechanic.enrage,
      mechanicValue: 200,
      bossTier: 8,
    ),

    // Week 9: CHAOS ARBITER – All types, shifting immunity
    (week) => Enemy(
      name: 'CHAOS ARBITER',
      description:
          'An unpredictable entity that shifts its elemental alignment with every cycle, defying all strategies.',
      hp: 300,
      maxHp: 300,
      attack: 22,
      goldReward: 160,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.physical,
      immunities: [],
      resistance: {
        DamageType.physical: 0.3,
        DamageType.fire: 0.3,
        DamageType.ice: 0.3,
        DamageType.lightning: 0.3,
      },
      mechanic: BossMechanic.shiftingTypes,
      mechanicValue: 0,
      bossTier: 9,
    ),

    // Week 10+: THE ARCHITECT – The ultimate boss, creates shields
    (week) => Enemy(
      name: 'THE ARCHITECT',
      description:
          'The supreme digital entity that constructed the Ring itself. Unfathomably powerful and nearly indestructible.',
      hp: 350,
      maxHp: 350,
      attack: 25,
      goldReward: 200,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.void_,
      immunities: [DamageType.void_, DamageType.holy],
      resistance: {
        DamageType.physical: 0.2,
        DamageType.fire: 0.2,
        DamageType.ice: 0.2,
        DamageType.lightning: 0.2,
        DamageType.poison: 0.2,
        DamageType.dark: 0.2,
      },
      mechanic: BossMechanic.shield,
      mechanicValue: 30,
      bossTier: 10,
    ),
  ];

  /// Get the boss for a specific week (1-indexed). Wraps around after 10.
  static Enemy getBossForWeek(int week) {
    final index = (week - 1) % allBosses.length;
    final boss = allBosses[index](week);
    final scaled = boss.scaleForWeek(week);

    // Ensure the unique legendary drop is in the loot pool
    final legendary = Item.bossLegendaries[index];
    if (!scaled.potentialLoot.any((i) => i.id == legendary.id)) {
      scaled.potentialLoot.add(legendary);
    }
    return scaled;
  }

  /// Get boss encounter days within a 7-day run
  /// Returns the day numbers when bosses appear
  static List<int> get bossEncounterDays => [2, 4, 6, 7];

  /// Get the boss for a specific encounter day and total day
  static Enemy getBossForEncounter(int encounterIndex, int currentDay) {
    final week = currentDay ~/ 7 + 1;
    return getBossForWeek(week);
  }

  /// Get a description of the upcoming boss
  static String getBossPreview(int week) {
    final index = (week - 1) % allBosses.length;
    final boss = allBosses[index](week);
    return '${boss.name}\n${boss.description}\n'
        'Type: ${boss.attackType.icon} ${boss.attackType.label} | '
        'Immune: ${boss.immunities.map((d) => "${d.icon} ${d.label}").join(", ")}';
  }
}

/// Tracks boss encounters during a run
class BossEncounterTracker {
  int _encounterIndex = 0;
  final List<int> _defeatedBosses = [];

  int get encounterIndex => _encounterIndex;
  List<int> get defeatedBosses => List.unmodifiable(_defeatedBosses);

  /// Check if a boss encounter should happen on the given day
  bool shouldEncounterBoss(int currentDay) {
    return WeeklyBosses.bossEncounterDays.contains(currentDay);
  }

  /// Get the next boss to encounter
  Enemy getNextBoss(int currentDay) {
    final week = currentDay ~/ 7 + 1;
    return WeeklyBosses.getBossForWeek(week);
  }

  /// Mark the current boss as defeated
  void markDefeated(int currentDay) {
    _defeatedBosses.add(currentDay);
    _encounterIndex++;
  }

  /// Reset for a new run
  void reset() {
    _encounterIndex = 0;
    _defeatedBosses.clear();
  }
}
