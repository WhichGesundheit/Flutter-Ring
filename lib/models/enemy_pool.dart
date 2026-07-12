import 'dart:math';
import 'enemy.dart';
import 'item.dart';
import 'zone.dart';

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
  // Standard Enemies (zone-agnostic, used for random encounters)
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
  // ZONE-SPECIFIC ENEMIES
  // ─────────────────────────────────────────────────────────────────────────

  // ── Forest (Binary Brush) ──
  static final List<Enemy> forestEnemies = [
    Enemy(
      name: "Thorn Vine Crawler",
      description:
          "A sentient fractal vine that lashes out with razor-sharp data-tendrils.",
      hp: 42,
      maxHp: 42,
      attack: 7,
      goldReward: 18,
      potentialLoot: [
        _pick(Rarity.common),
        _pick(Rarity.premium),
        _pick(Rarity.premium),
      ],
    ),
    Enemy(
      name: "Fungal Malware",
      description:
          "Spore-like code fragments that infect and corrupt nearby systems.",
      hp: 35,
      maxHp: 35,
      attack: 6,
      goldReward: 14,
      potentialLoot: [_pick(Rarity.common), _pick(Rarity.premium)],
    ),
    Enemy(
      name: "Canopy Watcher",
      description:
          "An ancient surveillance node hidden in the fractal canopy. Strikes from above.",
      hp: 48,
      maxHp: 48,
      attack: 9,
      goldReward: 24,
      potentialLoot: [
        _pick(Rarity.premium),
        _pick(Rarity.premium),
        _pick(Rarity.unique),
      ],
    ),
  ];

  // ── Deep Caves ──
  static final List<Enemy> deepCavesEnemies = [
    Enemy(
      name: "Stalactite Sentinel",
      description:
          "A crystalline guardian embedded in the cave ceiling. Drops without warning.",
      hp: 55,
      maxHp: 55,
      attack: 11,
      goldReward: 28,
      potentialLoot: [
        _pick(Rarity.premium),
        _pick(Rarity.premium),
        _pick(Rarity.unique),
      ],
    ),
    Enemy(
      name: "Memory Worm",
      description:
          "A serpentine data-wraith that devours stored memories for sustenance.",
      hp: 40,
      maxHp: 40,
      attack: 8,
      goldReward: 20,
      potentialLoot: [_pick(Rarity.premium), _pick(Rarity.unique)],
    ),
    Enemy(
      name: "Corrupted Archive",
      description:
          "A defensive system guarding ancient deleted files. Still operational after millennia.",
      hp: 60,
      maxHp: 60,
      attack: 10,
      goldReward: 30,
      potentialLoot: [
        _pick(Rarity.premium),
        _pick(Rarity.unique),
        _pick(Rarity.unique),
      ],
    ),
  ];

  // ── Wasteland ──
  static final List<Enemy> wastelandEnemies = [
    Enemy(
      name: "Static Revenant",
      description:
          "A reanimated husk powered by electrical storms. Radiates interference.",
      hp: 50,
      maxHp: 50,
      attack: 10,
      goldReward: 26,
      potentialLoot: [
        _pick(Rarity.premium),
        _pick(Rarity.premium),
        _pick(Rarity.unique),
      ],
    ),
    Enemy(
      name: "Dust Devil Drone",
      description:
          "A sand-worn reconnaissance unit that attacks in blinding swarms.",
      hp: 38,
      maxHp: 38,
      attack: 8,
      goldReward: 18,
      potentialLoot: [_pick(Rarity.common), _pick(Rarity.premium)],
    ),
    Enemy(
      name: "Corrosion Elemental",
      description:
          "A sentient acid cloud that dissolves armor and flesh alike.",
      hp: 55,
      maxHp: 55,
      attack: 12,
      goldReward: 32,
      potentialLoot: [
        _pick(Rarity.premium),
        _pick(Rarity.unique),
        _pick(Rarity.unique),
      ],
    ),
  ];

  // ── Graveyard ──
  static final List<Enemy> graveyardEnemies = [
    Enemy(
      name: "Revenant Protocol",
      description:
          "A ghost subroutine that refuses to terminate. Haunts the rusted circuits.",
      hp: 52,
      maxHp: 52,
      attack: 11,
      goldReward: 28,
      potentialLoot: [
        _pick(Rarity.premium),
        _pick(Rarity.unique),
        _pick(Rarity.unique),
      ],
    ),
    Enemy(
      name: "Tomb Warden",
      description:
          "An elite guardian patrolling the skeletal remains of fallen megastructures.",
      hp: 65,
      maxHp: 65,
      attack: 13,
      goldReward: 35,
      potentialLoot: [
        _pick(Rarity.unique),
        _pick(Rarity.unique),
        _pick(Rarity.legendary),
      ],
    ),
    Enemy(
      name: "Ghost Signal",
      description:
          "An ethereal transmission that attacks your neural interface directly.",
      hp: 45,
      maxHp: 45,
      attack: 9,
      goldReward: 22,
      potentialLoot: [_pick(Rarity.premium), _pick(Rarity.unique)],
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

  /// Get a random enemy appropriate for the given zone.
  /// Falls back to standard enemies if no zone-specific pool exists.
  static Enemy getEnemyForZone(ZoneType zone) {
    final List<Enemy> pool;
    switch (zone) {
      case ZoneType.forest:
      case ZoneType.deepCaves:
        pool = forestEnemies;
        break;
      case ZoneType.wasteland:
        pool = wastelandEnemies;
        break;
      case ZoneType.graveyard:
        pool = graveyardEnemies;
        break;
      case ZoneType.citadel:
        // Citadel uses bosses or tough standard enemies
        if (_random.nextDouble() < 0.3) {
          return getRandomBossEnemy();
        }
        pool = graveyardEnemies; // Reuse graveyard enemies as baseline
        break;
      case ZoneType.town:
        pool = standardEnemies;
        break;
    }
    return pool[_random.nextInt(pool.length)].clone();
  }
}
