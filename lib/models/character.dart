import 'item.dart';
import 'status_effect.dart';

class Character {
  final String name;
  final String className;
  int hp;
  int maxHp;
  int baseAttack;
  int credits;
  final Item startingItem;
  final List<SlotType> slotLayout;
  final String? imagePath;

  /// Active status effects on this character
  final List<StatusEffect> activeStatusEffects;

  Character({
    required this.name,
    required this.className,
    required this.hp,
    required this.maxHp,
    required this.baseAttack,
    required this.credits,
    required this.startingItem,
    required this.slotLayout,
    this.imagePath,
    List<StatusEffect>? activeStatusEffects,
  }) : activeStatusEffects = activeStatusEffects ?? [];

  // ── Status Effect Management ──

  static const int maxStatusEffects = 20;

  /// Add a status effect. If already present (same type), refresh duration
  /// (keep the higher of the two durations).
  void addStatusEffect(StatusEffect effect) {
    // Check for existing effect of same type
    final existing = activeStatusEffects.where((e) => e.type == effect.type);
    if (existing.isNotEmpty) {
      final existingEffect = existing.first;
      // Refresh: keep higher remaining duration
      if (effect.remainingDuration > existingEffect.remainingDuration) {
        existingEffect.remainingDuration = effect.remainingDuration;
      }
      existingEffect.currentCureProgress = 0;
      return;
    }
    // Add new if under limit
    if (activeStatusEffects.length < maxStatusEffects) {
      activeStatusEffects.add(effect.clone());
    }
  }

  /// Remove a specific status effect by type
  void removeStatusEffect(StatusEffectType type) {
    activeStatusEffects.removeWhere((e) => e.type == type);
  }

  /// Remove all expired effects
  void removeExpiredEffects() {
    activeStatusEffects.removeWhere((e) => e.isExpired);
  }

  /// Remove all battle-only effects (called when leaving battle)
  void removeBattleEffects() {
    activeStatusEffects.removeWhere(
      (e) => e.durationType == StatusDurationType.turns,
    );
  }

  /// Check if the character has a specific status effect
  bool hasStatusEffect(StatusEffectType type) {
    return activeStatusEffects.any((e) => e.type == type);
  }

  /// Get a specific status effect instance
  StatusEffect? getStatusEffect(StatusEffectType type) {
    try {
      return activeStatusEffects.firstWhere((e) => e.type == type);
    } catch (_) {
      return null;
    }
  }

  /// Attempt to cure effects based on a cure method.
  /// Returns the list of effects that were cured.
  List<StatusEffect> attemptCure(CureMethod method) {
    final cured = <StatusEffect>[];
    for (final effect in activeStatusEffects) {
      if (effect.cureMethod == method) {
        effect.currentCureProgress++;
        if (effect.isCured) {
          cured.add(effect);
        }
      }
    }
    for (final effect in cured) {
      activeStatusEffects.remove(effect);
    }
    return cured;
  }

  /// Attempt to cure a specific effect by gambling
  /// Returns true if cured
  bool attemptGamblingCure() {
    final cursed = getStatusEffect(StatusEffectType.cursed);
    if (cursed != null && cursed.cureMethod == CureMethod.gambling) {
      removeStatusEffect(StatusEffectType.cursed);
      return true;
    }
    return false;
  }

  /// Tick all hour-based status effects (called when hoursPassed changes)
  /// Returns the list of effects that expired
  List<StatusEffect> tickHourEffects() {
    final expired = <StatusEffect>[];
    for (final effect in activeStatusEffects) {
      if (effect.durationType == StatusDurationType.hours) {
        effect.tick();
        if (effect.isExpired) {
          expired.add(effect);
        }
      }
    }
    for (final effect in expired) {
      activeStatusEffects.remove(effect);
    }
    return expired;
  }

  /// Process per-hour effects (DoT, healing, etc.)
  /// Returns total damage taken from effects (negative = healing)
  int processHourlyEffects() {
    int totalChange = 0;
    for (final effect in activeStatusEffects) {
      if (effect.durationType == StatusDurationType.hours ||
          effect.durationType == StatusDurationType.permanent) {
        if (effect.damagePerTurn > 0) {
          hp = (hp - effect.damagePerTurn).clamp(0, maxHp);
          totalChange -= effect.damagePerTurn;
        }
        if (effect.healPerTurn > 0) {
          hp = (hp + effect.healPerTurn).clamp(0, effectiveMaxHp);
          totalChange += effect.healPerTurn;
        }
      }
    }
    return totalChange;
  }

  /// Increment cure progress for kill-based cures
  void incrementKillCureProgress() {
    for (final effect in activeStatusEffects) {
      if (effect.cureMethod == CureMethod.killSpecificEnemy) {
        effect.currentCureProgress++;
      }
    }
    // Auto-remove fully cured effects
    activeStatusEffects.removeWhere((e) => e.isCured);
  }

  /// Effective max HP accounting for status effects
  int get effectiveMaxHp {
    int mod = 0;
    for (final effect in activeStatusEffects) {
      mod += effect.maxHpModifier;
    }
    return (maxHp + mod).clamp(1, 9999);
  }

  /// Get total attack modifier from status effects
  int get statusAttackModifier {
    int mod = 0;
    for (final effect in activeStatusEffects) {
      mod += effect.attackModifier;
    }
    return mod;
  }

  /// Get total defense modifier from status effects
  int get statusDefenseModifier {
    int mod = 0;
    for (final effect in activeStatusEffects) {
      mod += effect.defenseModifier;
    }
    return mod;
  }

  /// Get total crit chance modifier from status effects
  double get statusCritModifier {
    double mod = 0.0;
    for (final effect in activeStatusEffects) {
      mod += effect.critChanceModifier;
    }
    return mod;
  }

  /// Get total luck modifier from status effects
  double get statusLuckModifier {
    double mod = 0.0;
    for (final effect in activeStatusEffects) {
      mod += effect.luckModifier;
    }
    return mod;
  }

  /// Get combined damage taken modifier (multiplier)
  double get statusDamageTakenModifier {
    double mod = 1.0;
    for (final effect in activeStatusEffects) {
      mod *= effect.damageTakenModifier;
    }
    return mod;
  }

  /// Get total life steal modifier from status effects
  double get statusLifeStealModifier {
    double mod = 0.0;
    for (final effect in activeStatusEffects) {
      mod += effect.lifeStealModifier;
    }
    return mod;
  }

  // ── Existing Methods ──

  int getEffectiveAttack(List<Item?> equippedSlots) {
    int totalAttack = baseAttack + statusAttackModifier;
    for (var item in equippedSlots) {
      if (item != null) {
        totalAttack += item.effectiveAttackBonus;
      }
    }
    return totalAttack;
  }

  /// Compute effective luck from all equipped items + status effects
  int getEffectiveLuck(List<Item?> equippedSlots) {
    int totalLuck = 0;
    for (var item in equippedSlots) {
      if (item != null) {
        totalLuck += item.effectiveLuckBonus;
      }
    }
    totalLuck += statusLuckModifier.round();
    return totalLuck;
  }

  /// Compute effective crit chance from status effects
  double getEffectiveCritChance(List<Item?> equippedSlots) {
    double totalCrit = statusCritModifier;
    for (var item in equippedSlots) {
      if (item != null) {
        totalCrit += item.effectiveCritChance;
      }
    }
    // Luck adds +1% per point
    totalCrit += getEffectiveLuck(equippedSlots) * 0.01;
    return totalCrit;
  }

  Character clone() {
    return Character(
      name: name,
      className: className,
      hp: maxHp,
      maxHp: maxHp,
      baseAttack: baseAttack,
      credits: name == "Valerie" ? 10 : 45,
      startingItem: startingItem,
      slotLayout: List.from(slotLayout),
      imagePath: imagePath,
      activeStatusEffects: activeStatusEffects.map((e) => e.clone()).toList(),
    );
  }
}
