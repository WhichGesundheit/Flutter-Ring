import 'dart:math';

import 'item.dart';
import 'zone.dart';

/// Types of traveling merchants
enum MerchantType {
  consumable1,
  consumable2,
  consumable3,
  equipment1,
  equipment2,
  legendary,
}

extension MerchantTypeExtension on MerchantType {
  String get label {
    switch (this) {
      case MerchantType.consumable1:
        return 'Nano Pharmacist';
      case MerchantType.consumable2:
        return 'Stim Dealer';
      case MerchantType.consumable3:
        return 'Med Vendor';
      case MerchantType.equipment1:
        return 'Blade Smith';
      case MerchantType.equipment2:
        return 'Armor Forger';
      case MerchantType.legendary:
        return 'Void Antiquarian';
    }
  }

  String get description {
    switch (this) {
      case MerchantType.consumable1:
        return 'Specializes in healing nanites and restorative tech.';
      case MerchantType.consumable2:
        return 'Deals in performance enhancers and stimulants.';
      case MerchantType.consumable3:
        return 'Medical supplies for the discerning runner.';
      case MerchantType.equipment1:
        return 'Crafts weapons of exceptional quality.';
      case MerchantType.equipment2:
        return 'Forges armor from salvaged megastructure plating.';
      case MerchantType.legendary:
        return 'Ancient artifacts of immense power. Prices are steep.';
    }
  }

  String get icon {
    switch (this) {
      case MerchantType.consumable1:
      case MerchantType.consumable2:
      case MerchantType.consumable3:
        return '💊';
      case MerchantType.equipment1:
        return '⚔️';
      case MerchantType.equipment2:
        return '🛡️';
      case MerchantType.legendary:
        return '👑';
    }
  }

  /// Price multiplier for this merchant type
  double get priceMultiplier {
    switch (this) {
      case MerchantType.consumable1:
      case MerchantType.consumable2:
      case MerchantType.consumable3:
        return 1.0;
      case MerchantType.equipment1:
      case MerchantType.equipment2:
        return 1.2;
      case MerchantType.legendary:
        return 2.0;
    }
  }
}

/// A traveling merchant that changes location each day
class TravelingMerchant {
  final MerchantType type;
  ZoneType currentZone;

  TravelingMerchant({required this.type, required this.currentZone});

  /// Generate stock for this merchant
  List<Item> generateStock({Random? rng}) {
    final random = rng ?? Random();
    switch (type) {
      case MerchantType.consumable1:
      case MerchantType.consumable2:
      case MerchantType.consumable3:
        return _generateConsumableStock(random);
      case MerchantType.equipment1:
        return _generateWeaponStock(random);
      case MerchantType.equipment2:
        return _generateArmorStock(random);
      case MerchantType.legendary:
        return _generateLegendaryStock(random);
    }
  }

  List<Item> _generateConsumableStock(Random random) {
    final consumables = Item.chestLootPool
        .where((i) => i.isConsumable)
        .toList();
    consumables.shuffle(random);
    return consumables.take(4).toList();
  }

  List<Item> _generateWeaponStock(Random random) {
    final weapons = Item.chestLootPool
        .where((i) => i.type == SlotType.weapon)
        .toList();
    weapons.shuffle(random);
    final count = min(3, weapons.length);
    return weapons.take(count).toList();
  }

  List<Item> _generateArmorStock(Random random) {
    final armor = Item.chestLootPool
        .where((i) => i.type == SlotType.armor || i.type == SlotType.head)
        .toList();
    armor.shuffle(random);
    final count = min(3, armor.length);
    return armor.take(count).toList();
  }

  List<Item> _generateLegendaryStock(Random random) {
    final legendaries = Item.chestLootPool
        .where((i) => i.rarity == Rarity.legendary)
        .toList();
    legendaries.shuffle(random);
    final count = min(3, legendaries.length);
    return legendaries.take(count).toList();
  }

  /// Get adjusted price for this merchant
  int adjustedPrice(Item item) {
    return (item.cost * type.priceMultiplier).round();
  }
}

/// Manages all traveling merchants for a run
class MerchantManager {
  static final Random _random = Random();

  final List<TravelingMerchant> merchants = [];

  MerchantManager() {
    _initMerchants();
  }

  void _initMerchants() {
    merchants.addAll([
      TravelingMerchant(
        type: MerchantType.consumable1,
        currentZone: ZoneType.forest,
      ),
      TravelingMerchant(
        type: MerchantType.consumable2,
        currentZone: ZoneType.wasteland,
      ),
      TravelingMerchant(
        type: MerchantType.consumable3,
        currentZone: ZoneType.deepCaves,
      ),
      TravelingMerchant(
        type: MerchantType.equipment1,
        currentZone: ZoneType.graveyard,
      ),
      TravelingMerchant(
        type: MerchantType.equipment2,
        currentZone: ZoneType.ruins,
      ),
      TravelingMerchant(
        type: MerchantType.legendary,
        currentZone: ZoneType.citadel,
      ),
    ]);
  }

  /// Rotate merchants to new locations for a new day
  void rotateLocations() {
    final availableZones = ZoneType.values
        .where((z) => z != ZoneType.town)
        .toList();
    availableZones.shuffle(_random);

    for (int i = 0; i < merchants.length; i++) {
      merchants[i].currentZone = availableZones[i % availableZones.length];
    }
  }

  /// Get merchants at a specific zone
  List<TravelingMerchant> getMerchantsAt(ZoneType zone) {
    return merchants.where((m) => m.currentZone == zone).toList();
  }

  /// Reset for new run
  void reset() {
    merchants.clear();
    _initMerchants();
  }
}
