import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// DAMAGE TYPE – 8 elemental/physical damage types
/// ═══════════════════════════════════════════════════════════════════════════════
enum DamageType { physical, fire, ice, lightning, poison, void_, holy, dark }

/// Unique status effect that can be applied by damage types
class DamageTypeEffect {
  final DamageType source;
  final String name;
  final String icon;
  int turnsRemaining;

  DamageTypeEffect({
    required this.source,
    required this.name,
    required this.icon,
    required this.turnsRemaining,
  });
}

extension DamageTypeExtension on DamageType {
  String get label {
    switch (this) {
      case DamageType.physical:
        return 'Physical';
      case DamageType.fire:
        return 'Fire';
      case DamageType.ice:
        return 'Ice';
      case DamageType.lightning:
        return 'Lightning';
      case DamageType.poison:
        return 'Poison';
      case DamageType.void_:
        return 'Void';
      case DamageType.holy:
        return 'Holy';
      case DamageType.dark:
        return 'Dark';
    }
  }

  String get icon {
    switch (this) {
      case DamageType.physical:
        return '⚔️';
      case DamageType.fire:
        return '🔥';
      case DamageType.ice:
        return '❄️';
      case DamageType.lightning:
        return '⚡';
      case DamageType.poison:
        return '☠️';
      case DamageType.void_:
        return '🌀';
      case DamageType.holy:
        return '✨';
      case DamageType.dark:
        return '🌑';
    }
  }

  /// Description of the unique combat effect this damage type inflicts
  String get effectDescription {
    switch (this) {
      case DamageType.physical:
        return 'Sunder: 30% chance to weaken enemy ATK by 20% for 2 turns';
      case DamageType.fire:
        return 'Ignite: 30% chance to burn for bonus/2 damage/turn (3 turns)';
      case DamageType.ice:
        return 'Deep Freeze: 20% chance to freeze enemy for 1 turn';
      case DamageType.lightning:
        return 'Chain Strike: 25% chance to deal lightning bonus again';
      case DamageType.poison:
        return 'Venom: 35% chance to poison for bonus×0.4 damage/turn (3 turns)';
      case DamageType.void_:
        return 'Rift: 20% chance to deal 2× void bonus damage this hit';
      case DamageType.holy:
        return 'Judgment: +50% bonus dmg vs enemies >50% HP, heals bonus×0.25';
      case DamageType.dark:
        return 'Leech: Heals bonus×0.35 HP per hit, 15% Weakness chance';
    }
  }

  Color get color {
    switch (this) {
      case DamageType.physical:
        return const Color(0xFFB0BEC5);
      case DamageType.fire:
        return const Color(0xFFFF5722);
      case DamageType.ice:
        return const Color(0xFF00BCD4);
      case DamageType.lightning:
        return const Color(0xFFFFEB3B);
      case DamageType.poison:
        return const Color(0xFF8BC34A);
      case DamageType.void_:
        return const Color(0xFF9C27B0);
      case DamageType.holy:
        return const Color(0xFFFFF176);
      case DamageType.dark:
        return const Color(0xFF311B92);
    }
  }
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// RARITY SLOT LIMITS – determines how many bonus damage types / resistances
/// ═══════════════════════════════════════════════════════════════════════════════
int maxDamageTypeSlots(String rarity) {
  switch (rarity) {
    case 'common':
      return 0;
    case 'premium':
      return 1;
    case 'unique':
      return 2;
    case 'legendary':
      return 3;
    default:
      return 0;
  }
}

int maxResistanceSlots(String rarity) {
  switch (rarity) {
    case 'common':
      return 0;
    case 'premium':
      return 1;
    case 'unique':
      return 2;
    case 'legendary':
      return 3;
    default:
      return 0;
  }
}
