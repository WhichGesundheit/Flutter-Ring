import 'dart:math';
import 'enemy.dart';
import 'item.dart';

class EnemyPool {
  static final Random _random = Random();

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
      potentialLoot: [Item.chestLootPool[0], Item.chestLootPool[5]],
    ),
    Enemy(
      name: "Crystalline Ghoul",
      description:
          "A mutated mineral construct feeding on rogue processing nodes.",
      hp: 45,
      maxHp: 45,
      attack: 8,
      goldReward: 20,
      potentialLoot: [Item.chestLootPool[1], Item.chestLootPool[2]],
    ),
    Enemy(
      name: "Glitch Spectre",
      description:
          "A phasing sequence anomaly that ignores physical shield signatures.",
      hp: 40,
      maxHp: 40,
      attack: 10,
      goldReward: 25,
      potentialLoot: [Item.chestLootPool[4], Item.chestLootPool[7]],
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
      potentialLoot: [Item.chestLootPool[6], Item.chestLootPool[14]],
    ),
    Enemy(
      name: "NEXUS WORLD-EATER",
      description:
          "A colossal grid-singularity tearing apart unallocated space.",
      hp: 160,
      maxHp: 160,
      attack: 14,
      goldReward: 120,
      potentialLoot: [Item.chestLootPool[12], Item.chestLootPool[13]],
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
