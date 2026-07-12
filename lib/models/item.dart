import 'dart:math';

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
        return 0.25;
      case Rarity.unique:
        return 0.12;
      case Rarity.legendary:
        return 0.04;
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
  });

  bool get isConsumable => healAmount > 0;

  int get sellValue => (cost * rarity.sellFraction).round();

  /// Attempt to roll a drop from [pool]. Returns null if nothing drops.
  static Item? rollDrop(List<Item> pool, {Random? rng}) {
    final random = rng ?? Random();
    // Shuffle to randomise evaluation order
    final candidates = List<Item>.from(pool)..shuffle(random);
    for (final item in candidates) {
      if (random.nextDouble() < item.rarity.dropChance) {
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
      description: 'A small token that nudges fate. +5% Crit.',
      cost: 10,
      critChance: 0.05,
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
    ),
    Item(
      id: 'swift_ring',
      name: 'Swift Ring',
      type: SlotType.item,
      description: 'A vibrating ring that accelerates reflexes.',
      cost: 20,
      critChance: 0.15,
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
    ),
    Item(
      id: 'glass_lens',
      name: 'Glass Cannon Lens',
      type: SlotType.item,
      description: 'Extreme precision. +35% Crit, -2 ATK.',
      cost: 45,
      critChance: 0.35,
      attackBonus: -2,
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

  static List<Item> get chestLootPool => _commonItems.toList(growable: false);

  static List<Item> get shopLootPool => _commonItems.toList(growable: false);
}
