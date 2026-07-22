import 'dart:math';

import 'item.dart';
import 'zone.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// TRAVELING NPCs and GLEED Gambling Shop
/// ═══════════════════════════════════════════════════════════════════════════════

/// Types of traveling NPCs
enum NPCType {
  travelingUpgrader, // ROOK - Can upgrade items on the road
  travelingMerchant, // VEX - Can buy/sell items on the road
}

extension NPCTypeExtension on NPCType {
  String get name {
    switch (this) {
      case NPCType.travelingUpgrader:
        return 'ROOK';
      case NPCType.travelingMerchant:
        return 'VEX';
    }
  }

  String get title {
    switch (this) {
      case NPCType.travelingUpgrader:
        return 'The Wandering Artificer';
      case NPCType.travelingMerchant:
        return 'The Road Peddler';
    }
  }

  String get icon {
    switch (this) {
      case NPCType.travelingUpgrader:
        return '🔧';
      case NPCType.travelingMerchant:
        return '🎒';
    }
  }

  String get description {
    switch (this) {
      case NPCType.travelingUpgrader:
        return 'A roaming mechanic who can upgrade equipment anywhere on the road. '
            'Charges a premium for the convenience.';
      case NPCType.travelingMerchant:
        return 'A traveling merchant who buys and sells goods at any location. '
            'Prices are slightly higher than settlement shops.';
    }
  }

  /// Price multiplier for upgrades
  double get upgradeMultiplier {
    switch (this) {
      case NPCType.travelingUpgrader:
        return 1.5; // 50% more expensive than town
      case NPCType.travelingMerchant:
        return 1.0;
    }
  }

  /// Price multiplier for buying
  double get buyMultiplier {
    switch (this) {
      case NPCType.travelingUpgrader:
        return 1.0;
      case NPCType.travelingMerchant:
        return 1.3; // 30% more expensive than town
    }
  }

  /// Sell fraction multiplier (lower = pays less)
  double get sellMultiplier {
    switch (this) {
      case NPCType.travelingUpgrader:
        return 1.0;
      case NPCType.travelingMerchant:
        return 0.7; // Pays 70% of normal sell value
    }
  }
}

/// A traveling NPC that changes location each day
class TravelingNPC {
  final NPCType type;
  ZoneType currentZone;

  /// Cached stock and the hour it was last generated.
  List<Item>? _cachedStock;
  int _lastStockRefreshHour = -1000;

  TravelingNPC({required this.type, required this.currentZone});

  /// Generate stock for this NPC
  List<Item> generateStock({Random? rng}) {
    final random = rng ?? Random();
    if (type == NPCType.travelingMerchant) {
      return _generateMerchantStock(random);
    }
    return [];
  }

  /// Get current stock with cache
  List<Item> getStock(int currentHour) {
    if (type != NPCType.travelingMerchant) return [];
    if (_cachedStock == null || (currentHour - _lastStockRefreshHour) >= 24) {
      _cachedStock = generateStock();
      _lastStockRefreshHour = currentHour;
    }
    return _cachedStock!;
  }

  List<Item> _generateMerchantStock(Random random) {
    // Mix of consumables and equipment
    final pool = List<Item>.from(Item.chestLootPool)..shuffle(random);
    return pool.take(5).toList();
  }

  /// Calculate upgrade cost with NPC multiplier
  int upgradeCost(Item item) {
    return (item.upgradeCost * type.upgradeMultiplier).round();
  }

  /// Calculate buy price with NPC multiplier
  int buyPrice(Item item) {
    return (item.cost * type.buyMultiplier).round();
  }

  /// Calculate sell price with NPC multiplier
  int sellPrice(Item item) {
    return (item.sellValue * type.sellMultiplier).round();
  }
}

/// Manages all traveling NPCs for a run
class NPCManager {
  static final Random _random = Random();

  final List<TravelingNPC> npcs = [];

  int lastRotationHour = -1000;

  NPCManager() {
    _initNPCs();
  }

  void _initNPCs() {
    npcs.addAll([
      TravelingNPC(
        type: NPCType.travelingUpgrader,
        currentZone: ZoneType.forest,
      ),
      TravelingNPC(
        type: NPCType.travelingMerchant,
        currentZone: ZoneType.wasteland,
      ),
    ]);
  }

  /// Rotate NPCs to new locations every 48h
  void rotateLocationsIfDue(int currentHour) {
    if ((currentHour - lastRotationHour) < 48) return;
    _rotateLocations();
    lastRotationHour = currentHour;
  }

  void _rotateLocations() {
    final availableZones = ZoneType.values
        .where((z) => z != ZoneType.town)
        .toList();
    availableZones.shuffle(_random);

    for (int i = 0; i < npcs.length; i++) {
      npcs[i].currentZone = availableZones[i % availableZones.length];
    }
  }

  /// Get NPCs at a specific zone
  List<TravelingNPC> getNPCsAt(ZoneType zone) {
    return npcs.where((n) => n.currentZone == zone).toList();
  }

  /// Reset for new run
  void reset() {
    npcs.clear();
    _initNPCs();
    lastRotationHour = -1000;
  }
}

/// ═══════════════════════════════════════════════════════════════════════════════
/// GLEED - The Gambling Shop NPC
/// Found in ALL towns (settlements)
/// Player can buy unknown items at lower odds
/// ═══════════════════════════════════════════════════════════════════════════════

enum MysteryBoxTier {
  basic, // 50c - mostly common/premium
  deluxe, // 120c - better odds for premium/unique
  elite, // 250c - best odds, can get legendary
}

extension MysteryBoxTierExtension on MysteryBoxTier {
  String get label {
    switch (this) {
      case MysteryBoxTier.basic:
        return 'Basic Mystery Box';
      case MysteryBoxTier.deluxe:
        return 'Deluxe Mystery Box';
      case MysteryBoxTier.elite:
        return 'Elite Mystery Box';
    }
  }

  int get price {
    switch (this) {
      case MysteryBoxTier.basic:
        return 50;
      case MysteryBoxTier.deluxe:
        return 120;
      case MysteryBoxTier.elite:
        return 250;
    }
  }

  String get icon {
    switch (this) {
      case MysteryBoxTier.basic:
        return '📦';
      case MysteryBoxTier.deluxe:
        return '🎁';
      case MysteryBoxTier.elite:
        return '👑';
    }
  }

  String get description {
    switch (this) {
      case MysteryBoxTier.basic:
        return 'A worn container with unknown contents. Mostly common items.';
      case MysteryBoxTier.deluxe:
        return 'A reinforced case. Better chance of quality gear.';
      case MysteryBoxTier.elite:
        return 'A vault-grade container. Legends whisper of its contents.';
    }
  }
}

class GleedShop {
  static final Random _random = Random();

  /// Cost per gambling attempt at Gleed's Den
  static const int gamblingCost = 30;

  /// Credits won on successful cure (on top of cost refund)
  static const int cureBonusCredits = 20;

  /// Roll a mystery box item.
  /// Odds are lower than normal drop rates but influenced by luck.
  /// Returns a random item based on tier odds + luck modifier.
  static Item rollMysteryBox(MysteryBoxTier tier, {double luckModifier = 0.0}) {
    // Base odds (lower than normal drop rates)
    double commonChance;
    double premiumChance;
    double uniqueChance;
    double legendaryChance;

    switch (tier) {
      case MysteryBoxTier.basic:
        commonChance = 0.55;
        premiumChance = 0.30;
        uniqueChance = 0.12;
        legendaryChance = 0.03;
        break;
      case MysteryBoxTier.deluxe:
        commonChance = 0.35;
        premiumChance = 0.40;
        uniqueChance = 0.20;
        legendaryChance = 0.05;
        break;
      case MysteryBoxTier.elite:
        commonChance = 0.15;
        premiumChance = 0.35;
        uniqueChance = 0.35;
        legendaryChance = 0.15;
        break;
    }

    // Luck modifier: shift odds toward higher rarities
    // Each luck point adds ~1% to higher rarities, taken from common
    final luckBonus = luckModifier * 0.01;
    commonChance = (commonChance - luckBonus * 3).clamp(0.05, 0.90);
    premiumChance = (premiumChance + luckBonus).clamp(0.05, 0.80);
    uniqueChance = (uniqueChance + luckBonus).clamp(0.02, 0.60);
    legendaryChance = (legendaryChance + luckBonus).clamp(0.01, 0.40);

    // Normalize
    final total = commonChance + premiumChance + uniqueChance + legendaryChance;
    commonChance /= total;
    premiumChance /= total;
    uniqueChance /= total;
    legendaryChance /= total;

    // Roll rarity
    final roll = _random.nextDouble();
    Rarity selectedRarity;

    if (roll < commonChance) {
      selectedRarity = Rarity.common;
    } else if (roll < commonChance + premiumChance) {
      selectedRarity = Rarity.premium;
    } else if (roll < commonChance + premiumChance + uniqueChance) {
      selectedRarity = Rarity.unique;
    } else {
      selectedRarity = Rarity.legendary;
    }

    // Pick random item of that rarity
    final pool = Item.chestLootPool
        .where((i) => i.rarity == selectedRarity)
        .toList();

    if (pool.isEmpty) {
      // Fallback to any common item
      final fallback = Item.chestLootPool
          .where((i) => i.rarity == Rarity.common)
          .toList();
      return fallback[_random.nextInt(fallback.length)];
    }

    return pool[_random.nextInt(pool.length)];
  }

  /// Attempt to cure a status effect through gambling
  /// Returns true if cured
  static bool attemptGamblingCure() {
    // 30% chance to cure on each gamble
    return _random.nextDouble() < 0.30;
  }
}
