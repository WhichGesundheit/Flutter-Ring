import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// DAMAGE TYPE – 8 elemental/physical damage types
/// ═══════════════════════════════════════════════════════════════════════════════
enum DamageType { physical, fire, ice, lightning, poison, void_, holy, dark }

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
