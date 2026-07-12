enum SlotType { head, armor, weapon, item }

class Item {
  final String id;
  final String name;
  final SlotType type;
  final String description; // Added this line back
  final int cost;
  final int attackBonus;
  final int damageReduction;
  final int lifeSteal;
  final int thorns;
  final double critChance;
  final int healAmount;
  final double hpThreshold; // e.g., 0.8 means use if HP < 80%
  final String? imagePath;

  Item({
    required this.id,
    required this.name,
    required this.type,
    this.description = '', // Added this line back
    this.cost = 0,
    this.attackBonus = 0,
    this.damageReduction = 0,
    this.lifeSteal = 0,
    this.thorns = 0,
    this.critChance = 0.0,
    this.healAmount = 0,
    this.hpThreshold = 0.0,
    this.imagePath,
  });

  bool get isConsumable => healAmount > 0;

  static final List<Item> chestLootPool = [
    Item(
      id: 'guardian_helm',
      name: 'Guardian Helm',
      type: SlotType.head,
      description: 'An armored helm radiating protective energy.',
      cost: 25,
      damageReduction: 3,
    ),
    Item(
      id: 'swift_ring',
      name: 'Swift Ring',
      type: SlotType.item,
      description: 'A vibrating ring that accelerates reflexes.',
      cost: 20,
      critChance: 0.15,
    ),
    Item(
      id: 'vamp_dagger',
      name: 'Vampiric Razor',
      type: SlotType.weapon,
      description: 'Siphons matrix code.',
      cost: 30,
      attackBonus: 2,
      lifeSteal: 3,
    ),
    Item(
      id: 'spiked_pauldron',
      name: 'Spiked Pauldron',
      type: SlotType.armor,
      description: 'Thorns deflect incoming impacts.',
      cost: 30,
      damageReduction: 2,
      thorns: 3,
    ),
    Item(
      id: 'titan_core',
      name: 'Titan Core',
      type: SlotType.item,
      description: 'A heavy core overflowing with raw force.',
      cost: 40,
      attackBonus: 4,
    ),
    Item(
      id: 'nano_elixir_loot',
      name: 'Nano Elixir',
      type: SlotType.item,
      description: 'A rapid nanite solution. Restores 35 HP on consumption.',
      cost: 15,
      healAmount: 35,
    ),
    Item(
      id: 'cursed_edge',
      name: 'Cursed Obsidian Edge',
      type: SlotType.weapon,
      description: 'Massive damage output, but drains defense (-2 Block).',
      cost: 35,
      attackBonus: 8,
      damageReduction: -2,
    ),
    Item(
      id: 'glass_lens',
      name: 'Glass Cannon Lens',
      type: SlotType.item,
      description: 'Boosts crit (+35%), but decreases base force (-2 ATK).',
      cost: 30,
      critChance: 0.35,
      attackBonus: -2,
    ),
    Item(
      id: 'heavy_shield_matrix',
      name: 'Heavy Shielding Matrix',
      type: SlotType.armor,
      description:
          'Increases blocking (+4 Block), but slows crit rate (-10% Crit).',
      cost: 35,
      damageReduction: 4,
      critChance: -0.10,
    ),
    Item(
      id: 'berserker_greaves',
      name: 'Berserker Greaves',
      type: SlotType.armor,
      description:
          'Unleash fury! High force (+3 ATK), but negative thorns (-1 Thorns).',
      cost: 25,
      attackBonus: 3,
      thorns: -1,
    ),
    Item(
      id: 'medkit_implant',
      name: 'Med-Kit Implant',
      type: SlotType.item,
      description: 'Surgical subroutines that heal 50 HP if below 75% health.',
      cost: 25,
      healAmount: 50,
      hpThreshold: 0.75,
    ),
    Item(
      id: 'repair_nanites',
      name: 'Repair Nanites',
      type: SlotType.item,
      description: 'Slow-release healing. Restores 20 HP if below 90% health.',
      cost: 15,
      healAmount: 20,
      hpThreshold: 0.90,
    ),
    Item(
      id: 'overdrive_chip',
      name: 'Overdrive Chip',
      type: SlotType.item,
      description: 'Pushes systems to the limit. +10 ATK, -5 Block.',
      cost: 45,
      attackBonus: 10,
      damageReduction: -5,
    ),
    Item(
      id: 'reactive_plating',
      name: 'Reactive Plating',
      type: SlotType.armor,
      description: 'High-tech armor. +5 Block, -15% Crit.',
      cost: 40,
      damageReduction: 5,
      critChance: -0.15,
    ),
    Item(
      id: 'plasma_cutter',
      name: 'Plasma Cutter',
      type: SlotType.weapon,
      description: 'Precision cutting edge. +5 ATK, +10% Crit.',
      cost: 50,
      attackBonus: 5,
      critChance: 0.10,
    ),
  ];

  static final List<Item> shopLootPool = [
    ...chestLootPool,
    Item(
      id: 'experimental_stim',
      name: 'Experimental Stim',
      type: SlotType.item,
      description: 'Unstable healing. Restores 60 HP if below 50% health.',
      cost: 30,
      healAmount: 60,
      hpThreshold: 0.5,
    ),
    Item(
      id: 'null_shield',
      name: 'Null Shield',
      type: SlotType.item,
      description: 'Absorbs energy. +2 Block, +5 Thorns.',
      cost: 35,
      damageReduction: 2,
      thorns: 5,
    ),
  ];
}
