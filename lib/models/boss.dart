import 'dart:math';

import 'damage_type.dart';
import 'enemy.dart';
import 'item.dart';
import 'zone.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// WEEKLY BOSS DEFINITIONS – 10 unique bosses with unique mechanics
/// Each boss appears on a rotating basis, getting stronger every week.
/// Every 7 days a HYPER version spawns, automatically engaging the player.
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

  /// Get the HYPER version of the boss for a specific week.
  /// Hyper bosses are 2.5× stronger (HP/attack/gold/mechanicValue)
  /// and drop the much-stronger `Item.hyperBossLegendaries` weapon.
  static Enemy getHyperBossForWeek(int week) {
    final index = (week - 1) % allBosses.length;
    final normal = getBossForWeek(week);
    const double hyperScale = 2.5;

    final hp = (normal.maxHp * hyperScale).round();
    final atk = (normal.attack * hyperScale).round();
    final gold = (normal.goldReward * hyperScale).round();
    final mVal = normal.mechanic == BossMechanic.none
        ? 0
        : (normal.mechanicValue * hyperScale).round();

    // Build the hyper loot pool: hyper-specific legendary + 2 random legendaries.
    final List<Item> hyperLoot = [];
    final hyperLegendary = Item.hyperBossLegendaries[index];
    hyperLoot.add(hyperLegendary);
    hyperLoot.add(_pick(Rarity.legendary));
    hyperLoot.add(_pick(Rarity.legendary));

    return Enemy(
      name: '⚡ HYPER ${normal.name}',
      description:
          'A massively amplified construct of pure hostile code. '
          '${normal.description}',
      hp: hp,
      maxHp: hp,
      attack: atk,
      goldReward: gold,
      potentialLoot: hyperLoot,
      imagePath: normal.imagePath,
      attackType: normal.attackType,
      immunities: List.from(normal.immunities),
      resistance: Map.from(normal.resistance),
      mechanic: normal.mechanic,
      mechanicValue: mVal,
      bossTier: normal.bossTier + 10, // ensure > 0 and visually elevated
      isHyper: true,
    );
  }

  /// Days within a 7-day window that the normal (opt-in) weekly boss appears.
  /// Day 7 is reserved for the HYPER boss which is forced and cannot be skipped.
  static List<int> get bossEncounterDays => [2, 4, 6];

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

/// ═══════════════════════════════════════════════════════════════════════════════
/// GUARDIAN BOSSES – 7 endgame guardians guarding Flutter-Rings
/// Each guardian is tied to a specific endgame zone and drops its Flutter-Ring.
/// ═══════════════════════════════════════════════════════════════════════════════
class GuardianBosses {
  static final Random _random = Random();

  static Item _pick(Rarity r) {
    final pool = Item.chestLootPool.where((i) => i.rarity == r).toList();
    return pool[_random.nextInt(pool.length)];
  }

  /// All 7 legendary guardians guarding the Flutter-Rings (All Tier 9 Endgame Scale)
  static final List<Enemy Function(int week)> allGuardians = [
    // 1. FLICKER GUARDIAN: Chrono-Glitch Tachyon
    // Guards: Flutter-Ring: Flicker (Hasted / Madness)
    (week) => Enemy(
      name: 'CHRONO-GLITCH TACHYON',
      description:
          'A hyper-velocity anomaly flickering between parallel processing '
          'execution threads. It strikes twice in a single frame.',
      hp: 310,
      maxHp: 310,
      attack: 22,
      goldReward: 180,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.lightning,
      immunities: [DamageType.lightning],
      mechanic: BossMechanic.chainStrike,
      mechanicValue: 2,
      bossTier: 9,
    ),

    // 2. SHUDDER GUARDIAN: Richter Engine
    // Guards: Flutter-Ring: Shudder (Empowered / Vulnerability)
    (week) => Enemy(
      name: 'RICHTER ENGINE',
      description:
          'A structural testing mainframe gone rogue. It vibrates with destructive '
          'seismic resonance, doubling its damage output when pushed.',
      hp: 300,
      maxHp: 300,
      attack: 24,
      goldReward: 180,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.physical,
      immunities: [DamageType.physical],
      mechanic: BossMechanic.enrage,
      mechanicValue: 200,
      bossTier: 9,
    ),

    // 3. ARRHYTHMIA GUARDIAN: Sanguine Core
    // Guards: Flutter-Ring: Arrhythmia (LifeStealAura / Corruption)
    (week) => Enemy(
      name: 'SANGUINE CORE',
      description:
          'A parasitic computational entity pumping crimson code. It continuously '
          'siphons and degrades the player\'s maximum structural integrity.',
      hp: 320,
      maxHp: 320,
      attack: 21,
      goldReward: 180,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.dark,
      immunities: [DamageType.dark],
      mechanic: BossMechanic.drainMaxHp,
      mechanicValue: 5,
      bossTier: 9,
    ),

    // 4. WAVER GUARDIAN: Phantasmagoria
    // Guards: Flutter-Ring: Waver (Blessed / Weakened)
    (week) => Enemy(
      name: 'PHANTASMAGORIA',
      description:
          'A shimmering, illusory phantom that wavers inside a shifting elemental '
          'axis, breaking all systemic target locks.',
      hp: 330,
      maxHp: 330,
      attack: 23,
      goldReward: 180,
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

    // 5. HOVER GUARDIAN: Null-G Colossus
    // Guards: Flutter-Ring: Hover (ShieldAura / Paralyzed)
    (week) => Enemy(
      name: 'NULL-G COLOSSUS',
      description:
          'A massive gravity-inverting citadel hovering above the scrap grid. '
          'It wraps itself in thick, regenerating sub-space shield layers.',
      hp: 340,
      maxHp: 340,
      attack: 22,
      goldReward: 180,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.void_,
      immunities: [DamageType.void_],
      mechanic: BossMechanic.shield,
      mechanicValue: 45,
      bossTier: 9,
    ),

    // 6. CHRYSALIS GUARDIAN: Permafrost Cocoon
    // Guards: Flutter-Ring: Chrysalis (Regeneration / Frozen)
    (week) => Enemy(
      name: 'PERMAFROST COCOON',
      description:
          'A frozen crystalline vault housing a dormant horror. It rapidly '
          're-compiles its damaged code blocks every single turn.',
      hp: 320,
      maxHp: 320,
      attack: 20,
      goldReward: 180,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.ice,
      immunities: [DamageType.ice],
      mechanic: BossMechanic.heal,
      mechanicValue: 15,
      bossTier: 9,
    ),

    // 7. CAPRICE GUARDIAN: The Grand Arbiter
    // Guards: Flutter-Ring: Caprice (LuckyBonus / Cursed)
    (week) => Enemy(
      name: 'THE GRAND ARBITER',
      description:
          'The capricious warden of the high forge. It reflects the player\'s '
          'input streams directly back into their face.',
      hp: 350,
      maxHp: 350,
      attack: 25,
      goldReward: 220,
      potentialLoot: [
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
        _pick(Rarity.legendary),
      ],
      attackType: DamageType.holy,
      immunities: [DamageType.holy, DamageType.dark],
      mechanic: BossMechanic.damageReflection,
      mechanicValue: 30,
      bossTier: 9,
    ),
  ];

  /// Mapping from ZoneType to guardian index (0-6)
  static final Map<ZoneType, int> _zoneToGuardianIndex = {
    ZoneType.tachyonFaultline: 0,
    ZoneType.resonanceFault: 1,
    ZoneType.sanguineConduit: 2,
    ZoneType.phasmMirage: 3,
    ZoneType.zeroGVault: 4,
    ZoneType.cryoCompileCrypt: 5,
    ZoneType.highForgeMatrix: 6,
  };

  /// Mapping from ZoneType to Flutter-Ring index (0-6)
  static final Map<ZoneType, int> _zoneToRingIndex = {
    ZoneType.tachyonFaultline: 0, // Flicker
    ZoneType.resonanceFault: 1, // Shudder
    ZoneType.sanguineConduit: 2, // Arrhythmia
    ZoneType.phasmMirage: 3, // Waver
    ZoneType.zeroGVault: 4, // Hover
    ZoneType.cryoCompileCrypt: 5, // Chrysalis
    ZoneType.highForgeMatrix: 6, // Caprice
  };

  /// Get the guardian boss for a specific zone, scaled by the given week.
  static Enemy? getGuardianForZone(ZoneType zone, {int week = 1}) {
    final index = _zoneToGuardianIndex[zone];
    if (index == null) return null;
    final boss = allGuardians[index](week);
    final scaled = boss.scaleForWeek(week);

    // Ensure the corresponding Flutter-Ring is in the loot pool
    final ringIndex = _zoneToRingIndex[zone]!;
    final ring = Item.flutterRings[ringIndex];
    if (!scaled.potentialLoot.any((i) => i.id == ring.id)) {
      scaled.potentialLoot.add(ring);
    }
    return scaled;
  }

  /// Check if a zone contains a guardian boss
  static bool isGuardianZone(ZoneType zone) =>
      _zoneToGuardianIndex.containsKey(zone);

  /// All guardian zone types
  static final Set<ZoneType> guardianZones = _zoneToGuardianIndex.keys.toSet();
}
