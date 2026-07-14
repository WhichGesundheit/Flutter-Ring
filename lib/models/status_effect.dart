import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// STATUS EFFECT – Persistent effects that modify player stats or inflict damage
/// ═══════════════════════════════════════════════════════════════════════════════

/// Types of status effects
enum StatusEffectType {
  // ── Negative Effects ──
  poison, // Damage over time
  burn, // Damage over time (fire)
  bleeding, // Damage over time (physical)
  cursed, // Reduces all stats by percentage
  weakened, // Reduces attack damage
  frozen, // May skip turns in battle
  paralyzed, // May skip turns in battle
  corruption, // Reduces max HP over time
  vulnerability, // Takes increased damage
  madness, // Random stat changes each turn
  // ── Positive Effects ──
  regeneration, // Heal over time
  shieldAura, // Flat damage reduction
  blessed, // Increased luck and crit
  empowered, // Increased attack damage
  hasted, // Increased speed / action economy
  luckyBonus, // Increased drop rates and crit
  resistanceBoost, // Increased damage resistance
  lifeStealAura, // Life steal on attacks
}

extension StatusEffectTypeExtension on StatusEffectType {
  String get label {
    switch (this) {
      case StatusEffectType.poison:
        return 'Poisoned';
      case StatusEffectType.burn:
        return 'Burning';
      case StatusEffectType.bleeding:
        return 'Bleeding';
      case StatusEffectType.cursed:
        return 'Cursed';
      case StatusEffectType.weakened:
        return 'Weakened';
      case StatusEffectType.frozen:
        return 'Frozen';
      case StatusEffectType.paralyzed:
        return 'Paralyzed';
      case StatusEffectType.corruption:
        return 'Corruption';
      case StatusEffectType.vulnerability:
        return 'Vulnerable';
      case StatusEffectType.madness:
        return 'Madness';
      case StatusEffectType.regeneration:
        return 'Regeneration';
      case StatusEffectType.shieldAura:
        return 'Shield Aura';
      case StatusEffectType.blessed:
        return 'Blessed';
      case StatusEffectType.empowered:
        return 'Empowered';
      case StatusEffectType.hasted:
        return 'Hasted';
      case StatusEffectType.luckyBonus:
        return 'Lucky';
      case StatusEffectType.resistanceBoost:
        return 'Resistant';
      case StatusEffectType.lifeStealAura:
        return 'Life Steal Aura';
    }
  }

  String get icon {
    switch (this) {
      case StatusEffectType.poison:
        return '☠️';
      case StatusEffectType.burn:
        return '🔥';
      case StatusEffectType.bleeding:
        return '🩸';
      case StatusEffectType.cursed:
        return '🔮';
      case StatusEffectType.weakened:
        return '⬇️';
      case StatusEffectType.frozen:
        return '❄️';
      case StatusEffectType.paralyzed:
        return '⚡';
      case StatusEffectType.corruption:
        return '🟣';
      case StatusEffectType.vulnerability:
        return '🎯';
      case StatusEffectType.madness:
        return '🌀';
      case StatusEffectType.regeneration:
        return '💚';
      case StatusEffectType.shieldAura:
        return '🛡️';
      case StatusEffectType.blessed:
        return '✨';
      case StatusEffectType.empowered:
        return '💪';
      case StatusEffectType.hasted:
        return '💨';
      case StatusEffectType.luckyBonus:
        return '🍀';
      case StatusEffectType.resistanceBoost:
        return '🔰';
      case StatusEffectType.lifeStealAura:
        return '🧛';
    }
  }

  bool get isPositive {
    switch (this) {
      case StatusEffectType.poison:
      case StatusEffectType.burn:
      case StatusEffectType.bleeding:
      case StatusEffectType.cursed:
      case StatusEffectType.weakened:
      case StatusEffectType.frozen:
      case StatusEffectType.paralyzed:
      case StatusEffectType.corruption:
      case StatusEffectType.vulnerability:
      case StatusEffectType.madness:
        return false;
      case StatusEffectType.regeneration:
      case StatusEffectType.shieldAura:
      case StatusEffectType.blessed:
      case StatusEffectType.empowered:
      case StatusEffectType.hasted:
      case StatusEffectType.luckyBonus:
      case StatusEffectType.resistanceBoost:
      case StatusEffectType.lifeStealAura:
        return true;
    }
  }

  Color get color {
    return isPositive ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
  }
}

/// How the duration of a status effect is measured
enum StatusDurationType {
  turns, // Battle-only, lasts N turns
  hours, // World-map hours (ticks with hoursPassed)
  permanent, // Until cured by specific action
}

extension StatusDurationTypeExtension on StatusDurationType {
  String get label {
    switch (this) {
      case StatusDurationType.turns:
        return 'Turns';
      case StatusDurationType.hours:
        return 'Hours';
      case StatusDurationType.permanent:
        return 'Permanent';
    }
  }
}

/// How a status effect can be cured
enum CureMethod {
  resting, // Cured by resting at inn
  doctor, // Visit a doctor NPC (GLEED or town)
  killSpecificEnemy, // Kill N of a specific monster type
  gambling, // Cured by gambling at GLEED
  townOnly, // Cured by being in any settlement
  specificAction, // Custom cure requirement (described in cureDescription)
  battleOnly, // Automatically removed when battle ends
}

extension CureMethodExtension on CureMethod {
  String get label {
    switch (this) {
      case CureMethod.resting:
        return 'Rest at Inn';
      case CureMethod.doctor:
        return 'Visit Doctor';
      case CureMethod.killSpecificEnemy:
        return 'Kill Specific Enemies';
      case CureMethod.gambling:
        return 'Gambling';
      case CureMethod.townOnly:
        return 'Visit Settlement';
      case CureMethod.specificAction:
        return 'Special Action';
      case CureMethod.battleOnly:
        return 'Battle Ends';
    }
  }
}

/// A single status effect instance on the player
class StatusEffect {
  final StatusEffectType type;
  final StatusDurationType durationType;
  int remainingDuration; // turns, hours, or -1 for permanent
  final CureMethod cureMethod;
  final String? cureDescription;
  final int requiredCureCount;
  int currentCureProgress;

  // Stat modifiers (applied while active)
  final int attackModifier;
  final int defenseModifier;
  final double critChanceModifier;
  final double luckModifier;
  final double
  damageTakenModifier; // multiplier on incoming damage (1.0 = normal)
  final int healPerTurn;
  final int damagePerTurn;
  final double lifeStealModifier;
  final int maxHpModifier;

  StatusEffect({
    required this.type,
    required this.durationType,
    required this.remainingDuration,
    this.cureMethod = CureMethod.battleOnly,
    this.cureDescription,
    this.requiredCureCount = 1,
    this.currentCureProgress = 0,
    this.attackModifier = 0,
    this.defenseModifier = 0,
    this.critChanceModifier = 0.0,
    this.luckModifier = 0.0,
    this.damageTakenModifier = 1.0,
    this.healPerTurn = 0,
    this.damagePerTurn = 0,
    this.lifeStealModifier = 0.0,
    this.maxHpModifier = 0,
  });

  bool get isPositive => type.isPositive;
  String get name => type.label;
  String get icon => type.icon;
  Color get color => type.color;

  bool get isExpired =>
      durationType != StatusDurationType.permanent && remainingDuration <= 0;

  bool get isCured =>
      cureMethod != CureMethod.battleOnly &&
      cureMethod != CureMethod.specificAction &&
      currentCureProgress >= requiredCureCount;

  String get durationString {
    switch (durationType) {
      case StatusDurationType.turns:
        return '$remainingDuration turns';
      case StatusDurationType.hours:
        return '$remainingDuration hours';
      case StatusDurationType.permanent:
        final cure = cureDescription ?? cureMethod.label;
        return 'Permanent (cure: $cure)';
    }
  }

  /// Tick the duration down by one unit (hour or turn)
  void tick() {
    if (durationType != StatusDurationType.permanent && remainingDuration > 0) {
      remainingDuration--;
    }
  }

  StatusEffect clone() {
    return StatusEffect(
      type: type,
      durationType: durationType,
      remainingDuration: remainingDuration,
      cureMethod: cureMethod,
      cureDescription: cureDescription,
      requiredCureCount: requiredCureCount,
      currentCureProgress: currentCureProgress,
      attackModifier: attackModifier,
      defenseModifier: defenseModifier,
      critChanceModifier: critChanceModifier,
      luckModifier: luckModifier,
      damageTakenModifier: damageTakenModifier,
      healPerTurn: healPerTurn,
      damagePerTurn: damagePerTurn,
      lifeStealModifier: lifeStealModifier,
      maxHpModifier: maxHpModifier,
    );
  }
}

/// Factory for creating predefined status effects
class StatusEffectFactory {
  static StatusEffect poison({int hours = 24, int damagePerTurn = 3}) {
    return StatusEffect(
      type: StatusEffectType.poison,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.doctor,
      cureDescription: 'Visit a doctor or rest at the inn',
      damagePerTurn: damagePerTurn,
    );
  }

  static StatusEffect burn({int hours = 12, int damagePerTurn = 4}) {
    return StatusEffect(
      type: StatusEffectType.burn,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.resting,
      cureDescription: 'Rest at the inn',
      damagePerTurn: damagePerTurn,
    );
  }

  static StatusEffect bleeding({int hours = 18, int damagePerTurn = 2}) {
    return StatusEffect(
      type: StatusEffectType.bleeding,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.townOnly,
      cureDescription: 'Visit any settlement',
      damagePerTurn: damagePerTurn,
    );
  }

  static StatusEffect cursed({int hours = 48}) {
    return StatusEffect(
      type: StatusEffectType.cursed,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.gambling,
      cureDescription: 'Gambling at GLEED\'s den',
      attackModifier: -2,
      defenseModifier: -2,
      critChanceModifier: -0.10,
      luckModifier: -3,
    );
  }

  static StatusEffect weakened({int hours = 24}) {
    return StatusEffect(
      type: StatusEffectType.weakened,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.resting,
      cureDescription: 'Rest at the inn',
      attackModifier: -4,
    );
  }

  static StatusEffect frozen({int turns = 2}) {
    return StatusEffect(
      type: StatusEffectType.frozen,
      durationType: StatusDurationType.turns,
      remainingDuration: turns,
      cureMethod: CureMethod.battleOnly,
    );
  }

  static StatusEffect paralyzed({int hours = 12}) {
    return StatusEffect(
      type: StatusEffectType.paralyzed,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.doctor,
      cureDescription: 'Visit a doctor',
    );
  }

  static StatusEffect corruption({int hours = 36}) {
    return StatusEffect(
      type: StatusEffectType.corruption,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.killSpecificEnemy,
      cureDescription: 'Kill 5 enemies while corrupted',
      requiredCureCount: 5,
      maxHpModifier: -5,
      damagePerTurn: 2,
    );
  }

  static StatusEffect vulnerability({int hours = 18}) {
    return StatusEffect(
      type: StatusEffectType.vulnerability,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.townOnly,
      cureDescription: 'Visit any settlement',
      damageTakenModifier: 1.25,
    );
  }

  static StatusEffect madness({int hours = 36}) {
    return StatusEffect(
      type: StatusEffectType.madness,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.doctor,
      cureDescription: 'Visit a doctor in town',
      attackModifier: -3,
      defenseModifier: 2,
      critChanceModifier: 0.15,
      luckModifier: -5,
    );
  }

  static StatusEffect regeneration({int hours = 12, int healPerTurn = 3}) {
    return StatusEffect(
      type: StatusEffectType.regeneration,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.battleOnly,
      healPerTurn: healPerTurn,
    );
  }

  static StatusEffect shieldAura({int hours = 12, int defense = 5}) {
    return StatusEffect(
      type: StatusEffectType.shieldAura,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.battleOnly,
      defenseModifier: defense,
    );
  }

  static StatusEffect blessed({int hours = 12}) {
    return StatusEffect(
      type: StatusEffectType.blessed,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.battleOnly,
      luckModifier: 5,
      critChanceModifier: 0.10,
    );
  }

  static StatusEffect empowered({int hours = 6}) {
    return StatusEffect(
      type: StatusEffectType.empowered,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.battleOnly,
      attackModifier: 5,
    );
  }

  static StatusEffect hasted({int hours = 4}) {
    return StatusEffect(
      type: StatusEffectType.hasted,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.battleOnly,
    );
  }

  static StatusEffect luckyBonus({int hours = 6}) {
    return StatusEffect(
      type: StatusEffectType.luckyBonus,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.battleOnly,
      luckModifier: 5,
    );
  }

  static StatusEffect resistanceBoost({int hours = 12, int defense = 3}) {
    return StatusEffect(
      type: StatusEffectType.resistanceBoost,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.battleOnly,
      defenseModifier: defense,
    );
  }

  static StatusEffect lifeStealAura({int hours = 12}) {
    return StatusEffect(
      type: StatusEffectType.lifeStealAura,
      durationType: StatusDurationType.hours,
      remainingDuration: hours,
      cureMethod: CureMethod.battleOnly,
      lifeStealModifier: 3.0,
    );
  }

  /// Create a random negative status effect appropriate for enemies
  static StatusEffect randomNegative({int tier = 1}) {
    final negatives = [
      () => poison(hours: 12 + tier * 6, damagePerTurn: 2 + tier),
      () => burn(hours: 8 + tier * 4, damagePerTurn: 3 + tier),
      () => bleeding(hours: 12 + tier * 6, damagePerTurn: 1 + tier),
      () => weakened(hours: 18 + tier * 6),
      () => vulnerability(hours: 12 + tier * 6),
      () => corrupted(hours: 24 + tier * 12),
    ];
    negatives.shuffle();
    return negatives.first();
  }

  static StatusEffect corrupted({int hours = 24}) => corruption(hours: hours);
}
