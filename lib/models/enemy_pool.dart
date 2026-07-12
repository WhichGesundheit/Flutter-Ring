import 'dart:math';
import 'enemy.dart';
import 'item.dart';

class EnemyPool {
  static final Random _random = Random();

  // Defining standard item rewards database drops
  static final List<Item> _commonDrops = [
    Item(
      id: 'scrap_shrapnel',
      name: 'Scrap Metal',
      type: SlotType.item,
      description: 'Melted circuitry.',
      attackBonus: 1,
    ),
    Item(
      id: 'rusted_ring',
      name: 'Rusted Ring',
      type: SlotType.item,
      description: 'Slight residual energy.',
      critChance: 0.05,
    ),
  ];

  static final List<Item> _rareDrops = [
    Item(
      id: 'titan_edge',
      name: 'Titan Edge',
      type: SlotType.weapon,
      description: 'Heavy tactical blade.',
      attackBonus: 7,
    ),
    Item(
      id: 'vamp_dagger',
      name: 'Vampiric Razor',
      type: SlotType.weapon,
      description: 'Siphons matrix code.',
      attackBonus: 2,
      lifeSteal: 3,
    ),
  ];

  // Monster
  static final List<Enemy> standardEnemies = [
    Enemy(
      name: "Void Drone",
      description:
          "Automated perimeter cleaner infected by corrupted subroutines.",
      hp: 35,
      maxHp: 35,
      attack: 5,
      goldReward: 12,
      potentialLoot: [_commonDrops[0]],
    ),
    Enemy(
      name: "Crystalline Ghoul",
      description:
          "A mutated mineral construct feeding on rogue processing nodes.",
      hp: 45,
      maxHp: 45,
      attack: 8,
      goldReward: 20,
      potentialLoot: [_commonDrops[1], _rareDrops[0]],
    ),
    Enemy(
      name: "Glitch Spectre",
      description:
          "A phasing sequence anomaly that ignores physical shield signatures.",
      hp: 40,
      maxHp: 40,
      attack: 10,
      goldReward: 25,
      potentialLoot: [_rareDrops[1]],
    ),
  ];
  // Boss
  static final List<Enemy> bossEnemies = [
    Enemy(
      name: "OMEGA OVERSEER",
      description:
          "Primary sector routing mainframe running aggressive deletion loops.",
      hp: 140,
      maxHp: 140,
      attack: 16,
      goldReward: 100,
      potentialLoot: [_rareDrops[0]],
    ),
    Enemy(
      name: "NEXUS WORLD-EATER",
      description:
          "A colossal grid-singularity tearing apart unallocated space.",
      hp: 160,
      maxHp: 160,
      attack: 14,
      goldReward: 120,
      potentialLoot: [_rareDrops[1]],
    ),
    Enemy(
      name: "RING OMNI-BEAST",
      description: "The structural apex defense construct of the local loop.",
      hp: 150,
      maxHp: 150,
      attack: 15,
      goldReward: 110,
    ),
  ];
  // Randomizer Selector Functions
  static Enemy getRandomStandardEnemy() {
    return standardEnemies[_random.nextInt(standardEnemies.length)].clone();
  }

  // Boss Selector Function
  static Enemy getRandomBossEnemy() {
    return bossEnemies[_random.nextInt(bossEnemies.length)].clone();
  }
}
