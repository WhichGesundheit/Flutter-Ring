import 'dart:math';
import 'boss.dart';
import 'damage_type.dart';
import 'enemy.dart';
import 'item.dart';
import 'zone.dart';
import 'status_effect.dart';

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
      attackType: DamageType.physical,
      inflictedEffects: [StatusEffectFactory.bleeding(hours: 8)],
      inflictChance: 0.2,
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
      attackType: DamageType.ice,
      inflictedEffects: [StatusEffectFactory.frozen(turns: 2)],
      inflictChance: 0.25,
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
      attackType: DamageType.void_,
      immunities: [DamageType.physical],
      inflictedEffects: [StatusEffectFactory.vulnerability(hours: 12)],
      inflictChance: 0.3,
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
      attackType: DamageType.physical,
      inflictedEffects: [StatusEffectFactory.bleeding(hours: 6)],
      inflictChance: 0.15,
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
      attackType: DamageType.dark,
      resistance: {DamageType.physical: 0.3},
      inflictedEffects: [StatusEffectFactory.weakened(hours: 12)],
      inflictChance: 0.25,
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
      attackType: DamageType.lightning,
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
      attackType: DamageType.poison,
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
      attackType: DamageType.poison,
      resistance: {DamageType.poison: 0.5},
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
      attackType: DamageType.lightning,
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
      attackType: DamageType.physical,
      resistance: {DamageType.physical: 0.2},
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
      attackType: DamageType.void_,
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
      attackType: DamageType.dark,
      immunities: [DamageType.dark],
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
      attackType: DamageType.lightning,
      resistance: {DamageType.lightning: 0.4},
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
      attackType: DamageType.physical,
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
      attackType: DamageType.fire,
      resistance: {DamageType.fire: 0.5, DamageType.physical: 0.2},
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
      attackType: DamageType.dark,
      immunities: [DamageType.holy],
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
      attackType: DamageType.holy,
      immunities: [DamageType.dark],
      resistance: {DamageType.physical: 0.3},
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
      attackType: DamageType.void_,
      resistance: {DamageType.physical: 0.5},
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // Boss Enemies (legacy, replaced by weekly boss system)
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
      attackType: DamageType.physical,
      immunities: [DamageType.physical],
      bossTier: 1,
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
      attackType: DamageType.void_,
      immunities: [DamageType.void_],
      bossTier: 2,
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
      attackType: DamageType.fire,
      immunities: [DamageType.fire],
      bossTier: 3,
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
        if (_random.nextDouble() < 0.3) {
          return getRandomBossEnemy();
        }
        pool = graveyardEnemies;
        break;
      case ZoneType.town:
        pool = standardEnemies;
        break;
      // New zones use appropriate enemy pools
      case ZoneType.ruins:
        pool = graveyardEnemies;
        break;
      case ZoneType.swamp:
        pool = forestEnemies;
        break;
      case ZoneType.mountain:
        pool = deepCavesEnemies;
        break;
      case ZoneType.desert:
        pool = wastelandEnemies;
        break;
      case ZoneType.library:
        pool = deepCavesEnemies;
        break;
      case ZoneType.factory:
        pool = wastelandEnemies;
        break;
      case ZoneType.ocean:
        pool = graveyardEnemies;
        break;
      case ZoneType.volcano:
        pool = wastelandEnemies;
        break;
      case ZoneType.tower:
        pool = deepCavesEnemies;
        break;
      case ZoneType.abyss:
        if (_random.nextDouble() < 0.4) {
          return getRandomBossEnemy();
        }
        pool = graveyardEnemies;
        break;
      // New zones use appropriate enemy pools
      case ZoneType.neonBazaar:
        pool = wastelandEnemies;
        break;
      case ZoneType.crystalMines:
        pool = deepCavesEnemies;
        break;
      case ZoneType.quantumRift:
        if (_random.nextDouble() < 0.5) {
          return getRandomBossEnemy();
        }
        pool = graveyardEnemies;
        break;
      case ZoneType.shadowMarket:
        pool = graveyardEnemies;
        break;
      case ZoneType.voidShrine:
        if (_random.nextDouble() < 0.5) {
          return getRandomBossEnemy();
        }
        pool = graveyardEnemies;
        break;
      case ZoneType.chromeDocks:
        pool = wastelandEnemies;
        break;
      case ZoneType.dataNexus:
        pool = deepCavesEnemies;
        break;
      case ZoneType.ghostTerminal:
        pool = graveyardEnemies;
        break;
      case ZoneType.solarForge:
        pool = wastelandEnemies;
        break;
      case ZoneType.neuralGarden:
        pool = forestEnemies;
        break;
      case ZoneType.circuitMarshes:
        pool = forestEnemies;
        break;
      case ZoneType.echoCaverns:
        pool = deepCavesEnemies;
        break;
      case ZoneType.plasmaFields:
        pool = wastelandEnemies;
        break;
      case ZoneType.obsidianSpire:
        if (_random.nextDouble() < 0.4) {
          return getRandomBossEnemy();
        }
        pool = graveyardEnemies;
        break;
      case ZoneType.voidGate:
        if (_random.nextDouble() < 0.6) {
          return getRandomBossEnemy();
        }
        pool = graveyardEnemies;
        break;
      // New tier zones use appropriate enemy pools
      case ZoneType.ironHarbor:
      case ZoneType.chromeSpire:
      case ZoneType.neonOasis:
      case ZoneType.blackMarketHub:
      case ZoneType.skyDock:
        pool = standardEnemies;
        break;
      case ZoneType.scorchedPipeline:
      case ZoneType.rustCanyon:
      case ZoneType.decayedGrid:
      case ZoneType.shatteredCore:
        pool = wastelandEnemies;
        break;
      case ZoneType.dataTorrent:
        pool = forestEnemies;
        break;
      case ZoneType.forgottenServer:
      case ZoneType.hollowNetwork:
      case ZoneType.deadSignal:
        pool = deepCavesEnemies;
        break;
      case ZoneType.acidSprawl:
      case ZoneType.staticRift:
        pool = forestEnemies;
        break;
      case ZoneType.entropyWell:
      case ZoneType.chromeLabyrinth:
      case ZoneType.voidNexus:
      case ZoneType.deepSpire:
      case ZoneType.quantumSea:
        if (_random.nextDouble() < 0.4) {
          return getRandomBossEnemy();
        }
        pool = graveyardEnemies;
        break;
      // ── TIER 5: ENDGAME GUARDIAN ZONES ──
      case ZoneType.tachyonFaultline:
      case ZoneType.resonanceFault:
      case ZoneType.sanguineConduit:
      case ZoneType.phasmMirage:
      case ZoneType.zeroGVault:
      case ZoneType.cryoCompileCrypt:
      case ZoneType.highForgeMatrix:
        final guardian = GuardianBosses.getGuardianForZone(zone, week: 1);
        if (guardian != null) return guardian;
        pool = graveyardEnemies;
        break;
    }
    return pool[_random.nextInt(pool.length)].clone();
  }
}
