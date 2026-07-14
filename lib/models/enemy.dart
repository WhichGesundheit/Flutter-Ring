import 'damage_type.dart';
import 'item.dart';
import 'status_effect.dart';

/// Special mechanics for bosses
enum BossMechanic {
  none,
  damageReflection, // Reflects % of damage taken
  burn, // Burns player for X damage per turn
  freeze, // Skips player attack every Nth turn
  chainStrike, // Hits twice every other turn
  poison, // Poisons player for damage over turns
  drainMaxHp, // Drains player's max HP
  heal, // Heals % HP each turn
  enrage, // Doubles damage when player < 50% HP
  shiftingTypes, // Changes attack type each turn
  shield, // Creates shields that absorb damage
}

class Enemy {
  final String name;
  final String description;
  int hp;
  int maxHp;
  final int attack;
  final int goldReward;
  final List<Item> potentialLoot;
  final String? imagePath;

  /// Primary damage type this enemy deals
  final DamageType attackType;

  /// Damage types this enemy is immune to (takes 0 damage from these)
  final List<DamageType> immunities;

  /// Percentage resistance to damage types (0.0–1.0). E.g. {DamageType.fire: 0.5}
  final Map<DamageType, double> resistance;

  /// Boss-specific mechanic
  final BossMechanic mechanic;

  /// Mechanic strength (e.g., reflection %, burn damage, heal %)
  final int mechanicValue;

  /// Boss tier (1–10). Higher = stronger scaling.
  final int bossTier;

  /// Whether this is a hyper version of a weekly boss (appears every 7 days).
  final bool isHyper;

  /// Status effects this enemy can inflict on the player
  final List<StatusEffect> inflictedEffects;

  /// Minimum number of turns before enemy can inflict status effects
  final int turnsBeforeInflict;

  /// Chance to inflict status effects after minimum turns (0.0-1.0)
  final double inflictChance;

  /// Whether this is a boss enemy
  bool get isBoss => bossTier > 0;

  Enemy({
    required this.name,
    required this.description,
    required this.hp,
    required this.maxHp,
    required this.attack,
    this.goldReward = 15,
    this.potentialLoot = const [],
    this.imagePath,
    this.attackType = DamageType.physical,
    this.immunities = const [],
    this.resistance = const {},
    this.mechanic = BossMechanic.none,
    this.mechanicValue = 0,
    this.bossTier = 0,
    this.isHyper = false,
    this.inflictedEffects = const [],
    this.turnsBeforeInflict = 5,
    this.inflictChance = 0.3,
  });

  factory Enemy.fromMap(Map<String, dynamic> map) {
    return Enemy(
      name: map['name'] ?? 'Unknown Disturbance',
      description: map['description'] ?? 'Anomalous signature.',
      hp: map['hp'] ?? 30,
      maxHp: map['hp'] ?? 30,
      attack: map['attack'] ?? 5,
      goldReward: map['goldReward'] ?? 15,
      potentialLoot: map['potentialLoot'] ?? [],
      imagePath: map['imagePath'],
      attackType: map['attackType'] ?? DamageType.physical,
      immunities: map['immunities'] ?? [],
      resistance: map['resistance'] ?? {},
    );
  }

  /// Create a scaled version of a boss for a given week
  Enemy scaleForWeek(int week) {
    if (week <= 1) return clone();
    final scaleFactor = 1.0 + ((week - 1) * 0.25);
    return Enemy(
      name: name,
      description: description,
      hp: (maxHp * scaleFactor).round(),
      maxHp: (maxHp * scaleFactor).round(),
      attack: (attack * scaleFactor).round(),
      goldReward: (goldReward * scaleFactor).round(),
      potentialLoot: List.from(potentialLoot),
      imagePath: imagePath,
      attackType: attackType,
      immunities: List.from(immunities),
      resistance: Map.from(resistance),
      mechanic: mechanic,
      mechanicValue: mechanic == BossMechanic.none
          ? 0
          : (mechanicValue * scaleFactor).round(),
      bossTier: bossTier,
      isHyper: isHyper,
      inflictedEffects: inflictedEffects.map((e) => e.clone()).toList(),
      turnsBeforeInflict: turnsBeforeInflict,
      inflictChance: inflictChance,
    );
  }

  // Create a deep copy helper to ensure clean instantiations per battle encounter
  Enemy clone() {
    return Enemy(
      name: name,
      description: description,
      hp: hp,
      maxHp: maxHp,
      attack: attack,
      goldReward: goldReward,
      potentialLoot: List.from(potentialLoot),
      imagePath: imagePath,
      attackType: attackType,
      immunities: List.from(immunities),
      resistance: Map.from(resistance),
      mechanic: mechanic,
      mechanicValue: mechanicValue,
      bossTier: bossTier,
      isHyper: isHyper,
      inflictedEffects: inflictedEffects.map((e) => e.clone()).toList(),
      turnsBeforeInflict: turnsBeforeInflict,
      inflictChance: inflictChance,
    );
  }
}
