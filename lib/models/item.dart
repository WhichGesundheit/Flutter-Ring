import 'dart:math';

import 'damage_type.dart';

enum SlotType { head, armor, weapon, item }

enum Rarity { common, premium, unique, legendary }

extension RarityExtension on Rarity {
  String get label => name[0].toUpperCase() + name.substring(1);

  /// Base drop chance when an enemy drops loot
  double get dropChance {
    switch (this) {
      case Rarity.common:
        return 0.45;
      case Rarity.premium:
        return 0.22;
      case Rarity.unique:
        return 0.09;
      case Rarity.legendary:
        return 0.025;
    }
  }

  /// Multiplier applied to base stats
  double get statMultiplier {
    switch (this) {
      case Rarity.common:
        return 1.0;
      case Rarity.premium:
        return 1.4;
      case Rarity.unique:
        return 2.0;
      case Rarity.legendary:
        return 3.0;
    }
  }

  /// Fraction of cost recovered when selling
  double get sellFraction {
    switch (this) {
      case Rarity.common:
        return 0.3;
      case Rarity.premium:
        return 0.4;
      case Rarity.unique:
        return 0.5;
      case Rarity.legendary:
        return 0.65;
    }
  }

  int get sortOrder {
    switch (this) {
      case Rarity.common:
        return 0;
      case Rarity.premium:
        return 1;
      case Rarity.unique:
        return 2;
      case Rarity.legendary:
        return 3;
    }
  }

  /// Number of bonus damage type slots for weapons
  int get damageTypeSlots {
    switch (this) {
      case Rarity.common:
        return 0;
      case Rarity.premium:
        return 1;
      case Rarity.unique:
        return 2;
      case Rarity.legendary:
        return 3;
    }
  }

  /// Number of bonus resistance slots for armor
  int get resistanceSlots {
    switch (this) {
      case Rarity.common:
        return 0;
      case Rarity.premium:
        return 1;
      case Rarity.unique:
        return 2;
      case Rarity.legendary:
        return 3;
    }
  }
}

class Item {
  final String id;
  final String name;
  final SlotType type;
  final String description;
  final int cost;
  final int attackBonus;
  final int damageReduction;
  final int lifeSteal;
  final int thorns;
  final double critChance;
  final int healAmount;
  final double hpThreshold;
  final String? imagePath;
  final Rarity rarity;
  final int luckBonus;

  /// Bonus damage per damage type (weapons). E.g. {DamageType.fire: 5}
  final Map<DamageType, int> bonusDamage;

  /// Flat resistance per damage type (armor/helm). E.g. {DamageType.fire: 3}
  final Map<DamageType, int> flatResistance;

  /// Upgrade level (0–5). Each level boosts stats by 20%.
  final int upgradeLevel;

  const Item({
    required this.id,
    required this.name,
    required this.type,
    this.description = '',
    this.cost = 0,
    this.attackBonus = 0,
    this.damageReduction = 0,
    this.lifeSteal = 0,
    this.thorns = 0,
    this.critChance = 0.0,
    this.healAmount = 0,
    this.hpThreshold = 0.0,
    this.imagePath,
    this.rarity = Rarity.common,
    this.bonusDamage = const {},
    this.flatResistance = const {},
    this.upgradeLevel = 0,
    this.luckBonus = 0,
  });

  bool get isConsumable => healAmount > 0;

  int get sellValue => (cost * rarity.sellFraction).round();

  /// Effective luckBonus after upgrade multiplier
  int get effectiveLuckBonus {
    final multiplier = 1.0 + (upgradeLevel * 0.2);
    return (luckBonus * multiplier).round();
  }

  static const int maxUpgradeLevel = 5;

  /// Effective attackBonus after upgrade multiplier
  int get effectiveAttackBonus {
    final multiplier = 1.0 + (upgradeLevel * 0.2);
    return (attackBonus * multiplier).round();
  }

  /// Effective damageReduction after upgrade multiplier
  int get effectiveDamageReduction {
    final multiplier = 1.0 + (upgradeLevel * 0.2);
    return (damageReduction * multiplier).round();
  }

  /// Effective lifeSteal after upgrade multiplier
  int get effectiveLifeSteal {
    final multiplier = 1.0 + (upgradeLevel * 0.2);
    return (lifeSteal * multiplier).round();
  }

  /// Effective thorns after upgrade multiplier
  int get effectiveThorns {
    final multiplier = 1.0 + (upgradeLevel * 0.2);
    return (thorns * multiplier).round();
  }

  /// Effective critChance after upgrade
  double get effectiveCritChance {
    final multiplier = 1.0 + (upgradeLevel * 0.15);
    return critChance * multiplier;
  }

  /// Effective healAmount after upgrade
  int get effectiveHealAmount {
    final multiplier = 1.0 + (upgradeLevel * 0.2);
    return (healAmount * multiplier).round();
  }

  /// Effective bonus damage map after upgrade
  Map<DamageType, int> get effectiveBonusDamage {
    if (bonusDamage.isEmpty) return {};
    final multiplier = 1.0 + (upgradeLevel * 0.2);
    return bonusDamage.map((k, v) => MapEntry(k, (v * multiplier).round()));
  }

  /// Effective resistance map after upgrade
  Map<DamageType, int> get effectiveFlatResistance {
    if (flatResistance.isEmpty) return {};
    final multiplier = 1.0 + (upgradeLevel * 0.2);
    return flatResistance.map((k, v) => MapEntry(k, (v * multiplier).round()));
  }

  /// Number of damage type slots currently used
  int get usedDamageTypeSlots => bonusDamage.length;

  /// Number of available damage type slots based on rarity
  int get availableDamageTypeSlots => rarity.damageTypeSlots;

  /// Number of resistance slots currently used
  int get usedResistanceSlots => flatResistance.length;

  /// Number of available resistance slots based on rarity
  int get availableResistanceSlots => rarity.resistanceSlots;

  /// Whether this item can accept more damage types
  bool get canAddDamageType =>
      (type == SlotType.weapon) &&
      usedDamageTypeSlots < availableDamageTypeSlots;

  /// Whether this item can accept more resistances
  bool get canAddResistance =>
      (type == SlotType.armor || type == SlotType.head) &&
      usedResistanceSlots < availableResistanceSlots;

  /// Create a copy with modifications
  Item copyWith({
    String? id,
    String? name,
    SlotType? type,
    String? description,
    int? cost,
    int? attackBonus,
    int? damageReduction,
    int? lifeSteal,
    int? thorns,
    double? critChance,
    int? healAmount,
    double? hpThreshold,
    String? imagePath,
    Rarity? rarity,
    Map<DamageType, int>? bonusDamage,
    Map<DamageType, int>? flatResistance,
    int? upgradeLevel,
    int? luckBonus,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      attackBonus: attackBonus ?? this.attackBonus,
      damageReduction: damageReduction ?? this.damageReduction,
      lifeSteal: lifeSteal ?? this.lifeSteal,
      thorns: thorns ?? this.thorns,
      critChance: critChance ?? this.critChance,
      healAmount: healAmount ?? this.healAmount,
      hpThreshold: hpThreshold ?? this.hpThreshold,
      imagePath: imagePath ?? this.imagePath,
      rarity: rarity ?? this.rarity,
      bonusDamage: bonusDamage ?? this.bonusDamage,
      flatResistance: flatResistance ?? this.flatResistance,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
      luckBonus: luckBonus ?? this.luckBonus,
    );
  }

  /// Upgrade this item to the next level (combine 3 copies)
  Item? attemptUpgrade() {
    if (upgradeLevel >= maxUpgradeLevel) return null;
    return copyWith(upgradeLevel: upgradeLevel + 1);
  }

  /// Infuse a new damage type into a weapon
  Item? infuseDamageType(DamageType damageType, int power) {
    if (!canAddDamageType) return null;
    if (bonusDamage.containsKey(damageType)) return null;
    final newBonusDamage = Map<DamageType, int>.from(bonusDamage);
    newBonusDamage[damageType] = power;
    return copyWith(bonusDamage: newBonusDamage);
  }

  /// Infuse a new resistance into armor/helm
  Item? infuseResistance(DamageType damageType, int power) {
    if (!canAddResistance) return null;
    if (flatResistance.containsKey(damageType)) return null;
    final newResistance = Map<DamageType, int>.from(flatResistance);
    newResistance[damageType] = power;
    return copyWith(flatResistance: newResistance);
  }

  /// Infuse cost in credits (scales with rarity and upgrade level)
  int get infuseCost {
    int base = 0;
    switch (rarity) {
      case Rarity.common:
        base = 15;
        break;
      case Rarity.premium:
        base = 30;
        break;
      case Rarity.unique:
        base = 50;
        break;
      case Rarity.legendary:
        base = 80;
        break;
    }
    return base + (upgradeLevel * 10);
  }

  /// Upgrade cost in credits
  int get upgradeCost {
    int base = 0;
    switch (rarity) {
      case Rarity.common:
        base = 20;
        break;
      case Rarity.premium:
        base = 40;
        break;
      case Rarity.unique:
        base = 70;
        break;
      case Rarity.legendary:
        base = 100;
        break;
    }
    return base + (upgradeLevel * 15);
  }

  /// Check if player has enough of the same item to upgrade
  static int countSameItem(List<Item> inventory, Item item) {
    return inventory.where((i) => i.id == item.id).length;
  }

  /// Attempt to roll a drop from [pool]. Returns null if nothing drops.
  /// [luckModifier] is added to the base drop chance (e.g. 0.05 = +5%).
  static Item? rollDrop(
    List<Item> pool, {
    Random? rng,
    double luckModifier = 0.0,
  }) {
    final random = rng ?? Random();
    // Shuffle to randomise evaluation order
    final candidates = List<Item>.from(pool)..shuffle(random);
    for (final item in candidates) {
      final adjustedChance = (item.rarity.dropChance + luckModifier).clamp(
        0.0,
        1.0,
      );
      if (random.nextDouble() < adjustedChance) {
        return item;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOOT POOLS – organised by rarity
  // ═══════════════════════════════════════════════════════════════════════════

  // ── COMMON ──
  static const _commonItems = [
    Item(
      id: 'iron_helm',
      name: 'Iron Helm',
      type: SlotType.head,
      description: 'Standard-issue helmet. Basic protection.',
      cost: 10,
      damageReduction: 1,
      rarity: Rarity.common,
    ),
    Item(
      id: 'rusty_blade',
      name: 'Rusty Blade',
      type: SlotType.weapon,
      description: 'A worn blade that still cuts.',
      cost: 8,
      attackBonus: 1,
      rarity: Rarity.common,
      bonusDamage: {DamageType.physical: 1},
    ),
    Item(
      id: 'leather_vest',
      name: 'Leather Vest',
      type: SlotType.armor,
      description: 'Light padding against minor threats.',
      cost: 10,
      damageReduction: 1,
      rarity: Rarity.common,
    ),
    Item(
      id: 'basic_medkit',
      name: 'Basic Medkit',
      type: SlotType.item,
      description: 'Restores 15 HP.',
      cost: 8,
      healAmount: 15,
      rarity: Rarity.common,
    ),
    Item(
      id: 'lucky_charm',
      name: 'Lucky Charm',
      type: SlotType.item,
      description: 'A small token that nudges fate. +5% Crit, +2 Luck.',
      cost: 10,
      critChance: 0.05,
      luckBonus: 2,
      rarity: Rarity.common,
    ),
    Item(
      id: 'scrap_shield',
      name: 'Scrap Shield',
      type: SlotType.armor,
      description: 'Welded together from debris. +2 Block.',
      cost: 12,
      damageReduction: 2,
      rarity: Rarity.common,
    ),
    Item(
      id: 'signal_booster',
      name: 'Signal Booster',
      type: SlotType.item,
      description: 'Amplifies attack output. +1 ATK.',
      cost: 10,
      attackBonus: 1,
      rarity: Rarity.common,
    ),

    // ── PREMIUM ──
    Item(
      id: 'guardian_helm',
      name: 'Guardian Helm',
      type: SlotType.head,
      description: 'An armored helm radiating protective energy.',
      cost: 25,
      damageReduction: 3,
      rarity: Rarity.premium,
      flatResistance: {DamageType.physical: 2},
    ),
    Item(
      id: 'swift_ring',
      name: 'Swift Ring',
      type: SlotType.item,
      description: 'A vibrating ring that accelerates reflexes. +3 Luck.',
      cost: 20,
      critChance: 0.15,
      luckBonus: 3,
      rarity: Rarity.premium,
    ),
    Item(
      id: 'vamp_dagger',
      name: 'Vampiric Razor',
      type: SlotType.weapon,
      description: 'Siphons matrix code on contact.',
      cost: 30,
      attackBonus: 2,
      lifeSteal: 3,
      rarity: Rarity.premium,
      bonusDamage: {DamageType.dark: 2},
    ),
    Item(
      id: 'spiked_pauldron',
      name: 'Spiked Pauldron',
      type: SlotType.armor,
      description: 'Thorns deflect incoming impacts.',
      cost: 30,
      damageReduction: 2,
      thorns: 3,
      rarity: Rarity.premium,
      flatResistance: {DamageType.physical: 1},
    ),
    Item(
      id: 'nano_elixir',
      name: 'Nano Elixir',
      type: SlotType.item,
      description: 'Rapid nanite solution. Restores 35 HP.',
      cost: 15,
      healAmount: 35,
      rarity: Rarity.premium,
    ),
    Item(
      id: 'berserker_greaves',
      name: 'Berserker Greaves',
      type: SlotType.armor,
      description: 'Unleash fury! +3 ATK, -1 Thorns.',
      cost: 25,
      attackBonus: 3,
      thorns: -1,
      rarity: Rarity.premium,
    ),
    Item(
      id: 'medkit_implant',
      name: 'Med-Kit Implant',
      type: SlotType.item,
      description: 'Heals 50 HP if below 75% health.',
      cost: 25,
      healAmount: 50,
      hpThreshold: 0.75,
      rarity: Rarity.premium,
    ),
    Item(
      id: 'repair_nanites',
      name: 'Repair Nanites',
      type: SlotType.item,
      description: 'Restores 20 HP if below 90% health.',
      cost: 15,
      healAmount: 20,
      hpThreshold: 0.90,
      rarity: Rarity.premium,
    ),
    Item(
      id: 'null_shield',
      name: 'Null Shield',
      type: SlotType.item,
      description: 'Absorbs energy. +2 Block, +5 Thorns.',
      cost: 35,
      damageReduction: 2,
      thorns: 5,
      rarity: Rarity.premium,
    ),
    Item(
      id: 'experimental_stim',
      name: 'Experimental Stim',
      type: SlotType.item,
      description: 'Restores 60 HP if below 50% health.',
      cost: 30,
      healAmount: 60,
      hpThreshold: 0.5,
      rarity: Rarity.premium,
    ),

    // ── UNIQUE ──
    Item(
      id: 'titan_core',
      name: 'Titan Core',
      type: SlotType.item,
      description: 'A heavy core overflowing with raw force. +4 ATK.',
      cost: 40,
      attackBonus: 4,
      rarity: Rarity.unique,
    ),
    Item(
      id: 'cursed_edge',
      name: 'Cursed Obsidian Edge',
      type: SlotType.weapon,
      description: 'Massive damage, but drains defense. +8 ATK, -2 Block.',
      cost: 55,
      attackBonus: 8,
      damageReduction: -2,
      rarity: Rarity.unique,
      bonusDamage: {DamageType.dark: 4, DamageType.physical: 2},
    ),
    Item(
      id: 'glass_lens',
      name: 'Glass Cannon Lens',
      type: SlotType.item,
      description: 'Extreme precision. +35% Crit, -2 ATK, +5 Luck.',
      cost: 45,
      critChance: 0.35,
      attackBonus: -2,
      luckBonus: 5,
      rarity: Rarity.unique,
    ),
    Item(
      id: 'heavy_shield_matrix',
      name: 'Heavy Shielding Matrix',
      type: SlotType.armor,
      description: 'Fortress-grade plating. +4 Block, -10% Crit.',
      cost: 50,
      damageReduction: 4,
      critChance: -0.10,
      rarity: Rarity.unique,
      flatResistance: {DamageType.physical: 3, DamageType.fire: 1},
    ),
    Item(
      id: 'plasma_cutter',
      name: 'Plasma Cutter',
      type: SlotType.weapon,
      description: 'Precision cutting edge. +5 ATK, +10% Crit.',
      cost: 55,
      attackBonus: 5,
      critChance: 0.10,
      rarity: Rarity.unique,
      bonusDamage: {DamageType.fire: 3, DamageType.lightning: 2},
    ),
    Item(
      id: 'reactive_plating',
      name: 'Reactive Plating',
      type: SlotType.armor,
      description: 'High-tech armor. +5 Block, -15% Crit.',
      cost: 50,
      damageReduction: 5,
      critChance: -0.15,
      rarity: Rarity.unique,
      flatResistance: {DamageType.lightning: 3, DamageType.ice: 2},
    ),
    Item(
      id: 'phoenix_crest',
      name: 'Phoenix Crest',
      type: SlotType.head,
      description: 'Radiates renewal. +2 Block, +2 LifeSteal.',
      cost: 50,
      damageReduction: 2,
      lifeSteal: 2,
      rarity: Rarity.unique,
      flatResistance: {DamageType.fire: 4},
    ),
    Item(
      id: 'vampire_plate',
      name: 'Vampire Plate',
      type: SlotType.armor,
      description: 'Drains life from attackers. +3 Block, +5 LifeSteal.',
      cost: 60,
      damageReduction: 3,
      lifeSteal: 5,
      rarity: Rarity.unique,
      flatResistance: {DamageType.dark: 3, DamageType.physical: 2},
    ),

    // ── LEGENDARY ──
    Item(
      id: 'overdrive_chip',
      name: 'Overdrive Chip',
      type: SlotType.item,
      description: 'Pushes systems to the absolute limit. +10 ATK, -5 Block.',
      cost: 90,
      attackBonus: 10,
      damageReduction: -5,
      rarity: Rarity.legendary,
    ),
    Item(
      id: 'void_king_crown',
      name: 'Void King Crown',
      type: SlotType.head,
      description:
          'The crown of a fallen digital monarch. +4 Block, +20% Crit, +3 LifeSteal.',
      cost: 120,
      damageReduction: 4,
      critChance: 0.20,
      lifeSteal: 3,
      rarity: Rarity.legendary,
      flatResistance: {
        DamageType.void_: 4,
        DamageType.dark: 3,
        DamageType.holy: 2,
      },
    ),
    Item(
      id: 'abyssal_edge',
      name: 'Abyssal Edge',
      type: SlotType.weapon,
      description:
          'A weapon forged in the void between sectors. +12 ATK, +10% Crit.',
      cost: 130,
      attackBonus: 12,
      critChance: 0.10,
      rarity: Rarity.legendary,
      bonusDamage: {
        DamageType.void_: 5,
        DamageType.dark: 4,
        DamageType.physical: 3,
      },
    ),
    Item(
      id: 'eternal_aegis',
      name: 'Eternal Aegis',
      type: SlotType.armor,
      description:
          'An impenetrable shield from the old world. +8 Block, +5 Thorns.',
      cost: 140,
      damageReduction: 8,
      thorns: 5,
      rarity: Rarity.legendary,
      flatResistance: {
        DamageType.physical: 5,
        DamageType.fire: 3,
        DamageType.ice: 2,
      },
    ),
    Item(
      id: 'seraph_module',
      name: 'Seraph Module',
      type: SlotType.item,
      description:
          'Angel-grade nanite injector. Full heal + 8 LifeSteal passive.',
      cost: 150,
      healAmount: 100,
      lifeSteal: 8,
      hpThreshold: 0.99,
      rarity: Rarity.legendary,
    ),
  ];

  // ── BOSS-SPECIFIC LEGENDARY DROPS ──
  static final List<Item> bossLegendaries = [
    // Boss 1: CIPHER SENTINEL (Physical) - Reflective blade
    Item(
      id: 'boss_sentinel_edge',
      name: "Sentinel's Reflex Edge",
      type: SlotType.weapon,
      description:
          'Forged from the firewall of the Cipher Sentinel. Strikes bounce back at attackers.',
      cost: 160,
      attackBonus: 10,
      thorns: 6,
      critChance: 0.12,
      rarity: Rarity.legendary,
      bonusDamage: {DamageType.physical: 6, DamageType.lightning: 3},
      flatResistance: {},
    ),

    // Boss 2: INFERNO CORE (Fire) - Burning armor
    Item(
      id: 'boss_inferno_core',
      name: "Inferno Core Mantle",
      type: SlotType.armor,
      description:
          'Pulsing with residual heat from the Inferno Core. Scorches all who dare strike it.',
      cost: 170,
      damageReduction: 6,
      thorns: 8,
      critChance: 0.08,
      rarity: Rarity.legendary,
      bonusDamage: {},
      flatResistance: {DamageType.fire: 6, DamageType.physical: 3},
    ),

    // Boss 3: FROST WRAITH (Ice) - Freezing helm
    Item(
      id: 'boss_frost_crown',
      name: "Wraith's Frozen Crown",
      type: SlotType.head,
      description:
          'A crown of eternal ice harvested from the Frost Wraith. Crystallizes enemy protocols on contact.',
      cost: 175,
      damageReduction: 5,
      critChance: 0.15,
      lifeSteal: 3,
      rarity: Rarity.legendary,
      bonusDamage: {},
      flatResistance: {DamageType.ice: 7, DamageType.lightning: 2},
    ),

    // Boss 4: STORM TITAN (Lightning) - Chain lightning gauntlet
    Item(
      id: 'boss_storm_gauntlet',
      name: "Storm Titan's Gauntlet",
      type: SlotType.weapon,
      description:
          'Channels devastating chain-lightning. Each strike arcs to nearby threats.',
      cost: 180,
      attackBonus: 12,
      critChance: 0.18,
      rarity: Rarity.legendary,
      bonusDamage: {DamageType.lightning: 7, DamageType.physical: 3},
    ),

    // Boss 5: PLAGUE VECTOR (Poison) - Toxic shield
    Item(
      id: 'boss_plague_shield',
      name: "Vector's Plague Barrier",
      type: SlotType.armor,
      description:
          'Coated in self-replicating viral code. Infects any organism that makes physical contact.',
      cost: 185,
      damageReduction: 7,
      lifeSteal: 4,
      thorns: 3,
      rarity: Rarity.legendary,
      bonusDamage: {},
      flatResistance: {DamageType.poison: 7, DamageType.dark: 3},
    ),

    // Boss 6: VOID SOVEREIGN (Void) - Void crown
    Item(
      id: 'boss_void_crown',
      name: "Void Sovereign's Diadem",
      type: SlotType.head,
      description:
          'A diadem carved from compressed void space. Drains the very essence of existence.',
      cost: 190,
      damageReduction: 5,
      critChance: 0.20,
      lifeSteal: 5,
      rarity: Rarity.legendary,
      bonusDamage: {},
      flatResistance: {DamageType.void_: 8, DamageType.dark: 3},
    ),

    // Boss 7: SERAPH GUARDIAN (Holy) - Divine blade
    Item(
      id: 'boss_seraph_blade',
      name: "Seraph's Divine裁决",
      type: SlotType.weapon,
      description:
          'A blade of pure holy light. Heals the wielder with each righteous strike.',
      cost: 200,
      attackBonus: 11,
      lifeSteal: 6,
      critChance: 0.14,
      rarity: Rarity.legendary,
      bonusDamage: {DamageType.holy: 6, DamageType.physical: 4},
    ),

    // Boss 8: UMBRA LORD (Dark) - Shadow mantle
    Item(
      id: 'boss_umbral_mantle',
      name: "Umbral Lord's Mantle",
      type: SlotType.armor,
      description:
          'Woven from shadow protocols. Grows stronger as the wearer nears death.',
      cost: 210,
      damageReduction: 8,
      critChance: 0.10,
      lifeSteal: 4,
      thorns: 5,
      rarity: Rarity.legendary,
      bonusDamage: {},
      flatResistance: {DamageType.dark: 8, DamageType.physical: 3},
    ),

    // Boss 9: CHAOS ARBITER - Multi-element engine
    Item(
      id: 'boss_chaos_engine',
      name: "Arbiter's Chaos Engine",
      type: SlotType.item,
      description:
          'An unpredictable artifact that channels all elemental forces simultaneously. Unstable but devastating.',
      cost: 220,
      attackBonus: 8,
      critChance: 0.22,
      lifeSteal: 3,
      rarity: Rarity.legendary,
    ),

    // Boss 10: THE ARCHITECT - Ultimate weapon
    Item(
      id: 'boss_architect_key',
      name: "Architect's Master Key",
      type: SlotType.weapon,
      description:
          'The supreme weapon of the Ring\'s creator. Rewrites the rules of combat with every swing.',
      cost: 250,
      attackBonus: 15,
      critChance: 0.15,
      lifeSteal: 5,
      thorns: 3,
      rarity: Rarity.legendary,
      bonusDamage: {
        DamageType.physical: 4,
        DamageType.void_: 4,
        DamageType.holy: 4,
      },
    ),
  ];

  // ── HYPER BOSS LEGENDARY DROPS (10 items, 1.6× stats, 1.5× cost) ──
  static final List<Item> hyperBossLegendaries = [
    // Hyper 1: CIPHER SENTINEL
    Item(
      id: 'hyper_sentinel_edge',
      name: "⚡ Hyper Sentinel's Edge",
      type: SlotType.weapon,
      description:
          'A blade of pure firewall energy, reforged under hyper-pressure. Reflects damage and amplifies output.',
      cost: 240,
      attackBonus: 16,
      thorns: 10,
      critChance: 0.18,
      rarity: Rarity.legendary,
      bonusDamage: {DamageType.physical: 10, DamageType.lightning: 6},
    ),
    // Hyper 2: INFERNO CORE
    Item(
      id: 'hyper_inferno_mantle',
      name: "⚡ Hyper Inferno Mantle",
      type: SlotType.armor,
      description:
          'Saturated in plasma-heat. Reflects damage back as burning thorns.',
      cost: 255,
      damageReduction: 10,
      thorns: 13,
      critChance: 0.12,
      rarity: Rarity.legendary,
      flatResistance: {DamageType.fire: 10, DamageType.physical: 5},
    ),
    // Hyper 3: FROST WRAITH
    Item(
      id: 'hyper_frost_crown',
      name: "⚡ Hyper Frost Crown",
      type: SlotType.head,
      description:
          'An ice helm that freezes enemy attacks on contact, with extreme life-drain.',
      cost: 260,
      damageReduction: 8,
      critChance: 0.22,
      lifeSteal: 5,
      rarity: Rarity.legendary,
      flatResistance: {DamageType.ice: 12, DamageType.lightning: 4},
    ),
    // Hyper 4: STORM TITAN
    Item(
      id: 'hyper_storm_gauntlet',
      name: "⚡ Hyper Storm Gauntlet",
      type: SlotType.weapon,
      description:
          'A hyper-charged gauntlet that arcs lightning through the entire grid.',
      cost: 270,
      attackBonus: 19,
      critChance: 0.26,
      rarity: Rarity.legendary,
      bonusDamage: {DamageType.lightning: 12, DamageType.physical: 5},
    ),
    // Hyper 5: PLAGUE VECTOR
    Item(
      id: 'hyper_plague_shield',
      name: "⚡ Hyper Plague Shield",
      type: SlotType.armor,
      description:
          'A hyper-mutated bio-armor that leeches life and corrodes attackers.',
      cost: 275,
      damageReduction: 11,
      lifeSteal: 7,
      thorns: 5,
      rarity: Rarity.legendary,
      flatResistance: {DamageType.poison: 12, DamageType.dark: 5},
    ),
    // Hyper 6: VOID SOVEREIGN
    Item(
      id: 'hyper_void_crown',
      name: "⚡ Hyper Void Diadem",
      type: SlotType.head,
      description:
          'A hyper-compressed void diadem that tears at the very fabric of existence.',
      cost: 285,
      damageReduction: 8,
      critChance: 0.30,
      lifeSteal: 8,
      rarity: Rarity.legendary,
      flatResistance: {DamageType.void_: 13, DamageType.dark: 5},
    ),
    // Hyper 7: SERAPH GUARDIAN
    Item(
      id: 'hyper_seraph_blade',
      name: "⚡ Hyper Seraph Blade",
      type: SlotType.weapon,
      description:
          'A hyper-pure holy blade. Each strike heals the wielder for a percentage of damage dealt.',
      cost: 300,
      attackBonus: 18,
      lifeSteal: 10,
      critChance: 0.20,
      rarity: Rarity.legendary,
      bonusDamage: {DamageType.holy: 10, DamageType.physical: 6},
    ),
    // Hyper 8: UMBRA LORD
    Item(
      id: 'hyper_umbral_mantle',
      name: "⚡ Hyper Umbral Mantle",
      type: SlotType.armor,
      description:
          'A hyper-shadow mantle that massively amplifies damage as the wearer nears death.',
      cost: 315,
      damageReduction: 13,
      critChance: 0.15,
      lifeSteal: 7,
      thorns: 8,
      rarity: Rarity.legendary,
      flatResistance: {DamageType.dark: 13, DamageType.physical: 5},
    ),
    // Hyper 9: CHAOS ARBITER
    Item(
      id: 'hyper_chaos_engine',
      name: "⚡ Hyper Chaos Engine",
      type: SlotType.item,
      description:
          'A hyper-unstable core that channels every elemental force at once, catastrophically.',
      cost: 330,
      attackBonus: 13,
      critChance: 0.32,
      lifeSteal: 5,
      rarity: Rarity.legendary,
    ),
    // Hyper 10: THE ARCHITECT
    Item(
      id: 'hyper_architect_key',
      name: "⚡ Hyper Architect Key",
      type: SlotType.weapon,
      description:
          'The supreme hyper-weapon forged from the Architect\'s own code. Rewrites the rules of combat.',
      cost: 375,
      attackBonus: 24,
      critChance: 0.22,
      lifeSteal: 8,
      thorns: 5,
      rarity: Rarity.legendary,
      bonusDamage: {
        DamageType.physical: 7,
        DamageType.void_: 7,
        DamageType.holy: 7,
      },
    ),
  ];

  static List<Item> get chestLootPool => _commonItems.toList(growable: false);

  static List<Item> get shopLootPool => _commonItems.toList(growable: false);
}
