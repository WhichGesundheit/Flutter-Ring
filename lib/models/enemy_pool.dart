import 'dart:math';
import 'enemy.dart';
import 'item.dart';

class EnemyPool {
  static final Random _random = Random();

  // ── Helper: grab items of a specific rarity from the master pool ──
  static List<Item> _itemsOf(Rarity r) =>
      Item.chestLootPool.where((i) => i.rarity == r).toList();

  // ── Helper: grab one random item from a rarity tier ──
  static Item _pick(Rarity r) {
    final pool = _itemsOf(r);
    return pool[_random.nextInt(pool.length)];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Standard Enemies
  // ─────────────────────────────────────────────────────────────────────────
  static final List<Enemy> standardEnemies = [
    Enemy(
      name: "Void Drone",
      description:
          "Automated perimeter cleaner infected by corrupted subroutines.",
      hp: 35,
      maxHp: 35,
      attack: 5,
      goldReward: 12,
      potentialLoot: [
        _pick(Rarity.common),
        _pick(Rarity.common),
        _pick(Rarity.premium),
      ],
    ),
    Enemy(
      name: "Crystalline Ghoul",
      description:
          "A mutated mineral construct feeding on rogue processing nodes.",
      hp: 45,
      maxHp: 45,
      attack: 8,
      goldReward: 20,
      potentialLoot: [
        _pick(Rarity.common),
        _pick(Rarity.premium),
        _pick(Rarity.premium),
      ],
    ),
    Enemy(
      name: "Glitch Spectre",
      description:
          "A phasing sequence anomaly that ignores physical shield signatures.",
      hp: 40,
      maxHp: 40,
      attack: 10,
      goldReward: 25,
      potentialLoot: [
        _pick(Rarity.premium),
        _pick(Rarity.premium),
        _pick(Rarity.unique),
      ],
    ),
    Enemy(
      name: "Rust Crawler",
      description:
          "A corroded automaton that drags itself through abandoned sectors.",
      hp: 30,
      maxHp: 30,
      attack: 4,
      goldReward: 8,
      potentialLoot: [_pick(Rarity.common), _pick(Rarity.common)],
    ),
    Enemy(
      name: "Data Phantom",
      description:
          "A ghostly echo of deleted data that lashes out at intruders.",
      hp: 50,
      maxHp: 50,
      attack: 9,
      goldReward: 22,
      potentialLoot: [
        _pick(Rarity.premium),
        _pick(Rarity.premium),
        _pick(Rarity.unique),
      ],
    ),
    Enemy(
      name: "Iron Swarm",
      description:
          "A cloud of nanoscopic drones acting as a single hostile entity.",
      hp: 38,
      maxHp: 38,
      attack: 7,
      goldReward: 16,
      potentialLoot: [_pick(Rarity.common), _pick(Rarity.premium)],
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Boss Enemies
  // ─────────────────────────────────────────────────────────────────────────
  static final List<Enemy> bossEnemies = [
    Enemy(
      name: "OMEGA OVERSEER",
      description:
          "Primary sector routing mainframe running aggressive deletion loops.",
      hp: 140,
      maxHp: 140,
      attack: 16,
      goldReward: 100,
      potentialLoot: [
        _pick(Rarity.unique),
        _pick(Rarity.unique),
        _pick(Rarity.legendary),
      ],
    ),
    Enemy(
      name: "NEXUS WORLD-EATER",
      description:
          "A colossal grid-singularity tearing apart unallocated space.",
      hp: 160,
      maxHp: 160,
      attack: 14,
      goldReward: 120,
      potentialLoot: [_pick(Rarity.unique), _pick(Rarity.legendary)],
    ),
    Enemy(
      name: "RING OMNI-BEAST",
      description: "The structural apex defense construct of the local loop.",
      hp: 150,
      maxHp: 150,
      attack: 15,
      goldReward: 110,
      potentialLoot: [
        _pick(Rarity.premium),
        _pick(Rarity.unique),
        _pick(Rarity.legendary),
      ],
    ),
  ];

  // ── Randomizer Selector Functions ──

  static Enemy getRandomStandardEnemy() {
    return standardEnemies[_random.nextInt(standardEnemies.length)].clone();
  }

  static Enemy getRandomBossEnemy() {
    return bossEnemies[_random.nextInt(bossEnemies.length)].clone();
  }
}
