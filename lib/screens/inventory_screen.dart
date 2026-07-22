import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/damage_type.dart';
import '../models/item.dart';
import '../models/zone.dart';
import '../widgets/game_image.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/stylish_popup.dart';

Color rarityColor(Rarity r) {
  switch (r) {
    case Rarity.common:
      return Colors.grey;
    case Rarity.premium:
      return Colors.tealAccent;
    case Rarity.unique:
      return Colors.deepPurpleAccent;
    case Rarity.legendary:
      return Colors.amberAccent;
  }
}

Widget rarityBadge(Rarity r, {double fontSize = 8}) {
  final color = rarityColor(r);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: color.withValues(alpha: 0.5)),
    ),
    child: Text(
      r.label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
  );
}

enum SortType { rarity, damage, defense, stats, name }

extension SortTypeExtension on SortType {
  String get label {
    switch (this) {
      case SortType.rarity:
        return 'Rarity';
      case SortType.damage:
        return 'Damage';
      case SortType.defense:
        return 'Defense';
      case SortType.stats:
        return 'Stats';
      case SortType.name:
        return 'Name';
    }
  }

  IconData get icon {
    switch (this) {
      case SortType.rarity:
        return Icons.diamond;
      case SortType.damage:
        return Icons.flash_on;
      case SortType.defense:
        return Icons.shield;
      case SortType.stats:
        return Icons.analytics;
      case SortType.name:
        return Icons.sort_by_alpha;
    }
  }
}

class InventoryScreen extends StatefulWidget {
  final Character player;
  final List<Item> inventory;
  final List<Item?> equippedSlots;
  final ZoneType currentZone;
  final VoidCallback onBack;

  const InventoryScreen({
    super.key,
    required this.player,
    required this.inventory,
    required this.equippedSlots,
    required this.currentZone,
    required this.onBack,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int? _selectedInventoryIndex;
  int? _selectedEquippedIndex;
  SortType _currentSort = SortType.rarity;

  static const int maxInventorySize = 10;

  /// Get sorted inventory indices
  List<int> _sortedIndices() {
    final indices = List<int>.generate(widget.inventory.length, (i) => i);
    indices.sort((a, b) {
      final itemA = widget.inventory[a];
      final itemB = widget.inventory[b];
      switch (_currentSort) {
        case SortType.rarity:
          final r = itemB.rarity.sortOrder.compareTo(itemA.rarity.sortOrder);
          if (r != 0) return r;
          return itemB.cost.compareTo(itemA.cost);
        case SortType.damage:
          return itemB.effectiveAttackBonus.compareTo(
            itemA.effectiveAttackBonus,
          );
        case SortType.defense:
          return itemB.effectiveDamageReduction.compareTo(
            itemA.effectiveDamageReduction,
          );
        case SortType.stats:
          final statsA =
              itemA.effectiveAttackBonus +
              itemA.effectiveDamageReduction +
              itemA.effectiveLifeSteal +
              itemA.effectiveThorns +
              (itemA.effectiveCritChance * 100).toInt();
          final statsB =
              itemB.effectiveAttackBonus +
              itemB.effectiveDamageReduction +
              itemB.effectiveLifeSteal +
              itemB.effectiveThorns +
              (itemB.effectiveCritChance * 100).toInt();
          return statsB.compareTo(statsA);
        case SortType.name:
          return itemA.name.compareTo(itemB.name);
      }
    });
    return indices;
  }

  void _attemptEquipSequence(Item item, int inventoryIndex) {
    // Find a matching empty slot first
    int targetingIndex = -1;
    for (int i = 0; i < widget.player.slotLayout.length; i++) {
      if (widget.player.slotLayout[i] == item.type &&
          widget.equippedSlots[i] == null) {
        targetingIndex = i;
        break;
      }
    }

    if (targetingIndex != -1) {
      // Empty slot found - equip directly
      setState(() {
        widget.equippedSlots[targetingIndex] = item;
        widget.inventory.removeAt(inventoryIndex);
        _selectedInventoryIndex = null;
        _selectedEquippedIndex = null;
      });
      showStylishPopup(
        context,
        title: 'EQUIPPED',
        message: '${item.name} equipped successfully.',
        icon: Icons.check_circle,
        iconColor: Colors.greenAccent,
      );
    } else {
      // No empty slot - check if there's a slot of the same type (swap)
      int swapIndex = -1;
      for (int i = 0; i < widget.player.slotLayout.length; i++) {
        if (widget.player.slotLayout[i] == item.type) {
          swapIndex = i;
          break;
        }
      }

      if (swapIndex != -1) {
        // Swap items
        final currentlyEquipped = widget.equippedSlots[swapIndex];
        setState(() {
          widget.inventory.removeAt(inventoryIndex);
          widget.inventory.add(currentlyEquipped!);
          widget.equippedSlots[swapIndex] = item;
          _selectedInventoryIndex = null;
          _selectedEquippedIndex = null;
        });
        showStylishPopup(
          context,
          title: 'SWAPPED',
          message: '${item.name} swapped with ${currentlyEquipped!.name}.',
          icon: Icons.swap_horiz,
          iconColor: Colors.cyanAccent,
        );
      } else {
        showStylishPopup(
          context,
          title: 'SLOT UNAVAILABLE',
          message: 'No open ${item.type.name.toUpperCase()} slot available.',
          icon: Icons.warning_amber,
          iconColor: Colors.orangeAccent,
        );
      }
    }
  }

  void _unequipItem(int index) {
    final item = widget.equippedSlots[index];
    if (item != null) {
      if (widget.inventory.length >= maxInventorySize) {
        showStylishPopup(
          context,
          title: 'INVENTORY FULL',
          message:
              'Cannot unequip — backpack is full ($maxInventorySize/$maxInventorySize).',
          icon: Icons.warning_amber,
          iconColor: Colors.orangeAccent,
        );
        return;
      }
      setState(() {
        widget.inventory.add(item);
        widget.equippedSlots[index] = null;
        _selectedInventoryIndex = null;
        _selectedEquippedIndex = null;
      });
      showStylishPopup(
        context,
        title: 'UNEQUIPPED',
        message: '${item.name} removed and returned to backpack.',
        icon: Icons.remove_circle_outline,
        iconColor: Colors.cyanAccent,
      );
    }
  }

  void _salvageItem(Item item, int index) {
    final sellValue = item.sellValue;
    setState(() {
      widget.inventory.removeAt(index);
      widget.player.credits += sellValue;
      _selectedInventoryIndex = null;
      _selectedEquippedIndex = null;
    });
    showStylishPopup(
      context,
      title: 'SALVAGED',
      message: '${item.name} salvaged for ${sellValue} credits.',
      icon: Icons.recycling,
      iconColor: Colors.orangeAccent,
    );
  }

  bool get _isInSettlement =>
      widget.currentZone == ZoneType.town ||
      widget.currentZone == ZoneType.ruins ||
      widget.currentZone == ZoneType.citadel;

  void _upgradeItem(Item item, int inventoryIndex) {
    final sameCount = Item.countSameItem(widget.inventory, item);
    if (sameCount < 3) {
      showStylishPopup(
        context,
        title: 'INSUFFICIENT COPIES',
        message: 'Need 3 copies to upgrade. You have $sameCount.',
        icon: Icons.warning_amber,
        iconColor: Colors.orangeAccent,
      );
      return;
    }
    if (item.upgradeLevel >= Item.maxUpgradeLevel) {
      showStylishPopup(
        context,
        title: 'MAX LEVEL',
        message:
            'This item is already at max upgrade level (+${item.upgradeLevel}).',
        icon: Icons.star,
        iconColor: Colors.amberAccent,
      );
      return;
    }
    if (widget.player.credits < item.upgradeCost) {
      showStylishPopup(
        context,
        title: 'INSUFFICIENT CREDITS',
        message:
            'Need ${item.upgradeCost}c to upgrade. You have ${widget.player.credits}c.',
        icon: Icons.monetization_on,
        iconColor: Colors.orangeAccent,
      );
      return;
    }

    final upgraded = item.attemptUpgrade();
    if (upgraded == null) return;

    setState(() {
      int removed = 0;
      for (int i = widget.inventory.length - 1; i >= 0 && removed < 2; i--) {
        if (widget.inventory[i].id == item.id) {
          widget.inventory.removeAt(i);
          removed++;
        }
      }
      final idx = widget.inventory.indexOf(item);
      if (idx >= 0) {
        widget.inventory[idx] = upgraded;
      }
      widget.player.credits -= item.upgradeCost;
    });

    showStylishPopup(
      context,
      title: 'UPGRADED!',
      message:
          '${item.name} → +${upgraded.upgradeLevel}\nStats boosted by ${(upgraded.upgradeLevel * 20)}%!',
      icon: Icons.upgrade,
      iconColor: Colors.amberAccent,
    );
  }

  void _infuseDamageType(Item item, int inventoryIndex) {
    if (!item.canAddDamageType) {
      showStylishPopup(
        context,
        title: 'NO SLOTS',
        message: item.type != SlotType.weapon
            ? 'Only weapons can have damage types.'
            : 'No available damage type slots (${item.usedDamageTypeSlots}/${item.availableDamageTypeSlots}).',
        icon: Icons.warning_amber,
        iconColor: Colors.orangeAccent,
      );
      return;
    }
    if (widget.player.credits < item.infuseCost) {
      showStylishPopup(
        context,
        title: 'INSUFFICIENT CREDITS',
        message:
            'Need ${item.infuseCost}c to infuse. You have ${widget.player.credits}c.',
        icon: Icons.monetization_on,
        iconColor: Colors.orangeAccent,
      );
      return;
    }

    final available = DamageType.values
        .where((dt) => !item.bonusDamage.containsKey(dt))
        .toList();
    if (available.isEmpty) {
      showStylishPopup(
        context,
        title: 'ALL TYPES FILLED',
        message: 'This weapon already has all damage types.',
        icon: Icons.warning_amber,
        iconColor: Colors.orangeAccent,
      );
      return;
    }

    available.shuffle();
    final chosen = available.first;
    final power = 2 + item.rarity.sortOrder;

    final infused = item.infuseDamageType(chosen, power);
    if (infused == null) return;

    setState(() {
      widget.inventory[inventoryIndex] = infused;
      widget.player.credits -= item.infuseCost;
    });

    showStylishPopup(
      context,
      title: 'DAMAGE TYPE INFUSED!',
      message:
          '${chosen.icon} ${chosen.label} (+$power) added to ${item.name}!',
      icon: Icons.local_fire_department,
      iconColor: chosen.color,
    );
  }

  void _infuseResistance(Item item, int inventoryIndex) {
    if (!item.canAddResistance) {
      showStylishPopup(
        context,
        title: 'NO SLOTS',
        message: (item.type != SlotType.armor && item.type != SlotType.head)
            ? 'Only armor/helmets can have resistances.'
            : 'No available resistance slots (${item.usedResistanceSlots}/${item.availableResistanceSlots}).',
        icon: Icons.warning_amber,
        iconColor: Colors.orangeAccent,
      );
      return;
    }
    if (widget.player.credits < item.infuseCost) {
      showStylishPopup(
        context,
        title: 'INSUFFICIENT CREDITS',
        message:
            'Need ${item.infuseCost}c to infuse. You have ${widget.player.credits}c.',
        icon: Icons.monetization_on,
        iconColor: Colors.orangeAccent,
      );
      return;
    }

    final available = DamageType.values
        .where((dt) => !item.flatResistance.containsKey(dt))
        .toList();
    if (available.isEmpty) {
      showStylishPopup(
        context,
        title: 'ALL TYPES FILLED',
        message: 'This armor already has all resistance types.',
        icon: Icons.warning_amber,
        iconColor: Colors.orangeAccent,
      );
      return;
    }

    available.shuffle();
    final chosen = available.first;
    final power = 1 + item.rarity.sortOrder;

    final infused = item.infuseResistance(chosen, power);
    if (infused == null) return;

    setState(() {
      widget.inventory[inventoryIndex] = infused;
      widget.player.credits -= item.infuseCost;
    });

    showStylishPopup(
      context,
      title: 'RESISTANCE INFUSED!',
      message:
          '${chosen.icon} ${chosen.label} (+$power) added to ${item.name}!',
      icon: Icons.shield,
      iconColor: chosen.color,
    );
  }

  void _showInspectDialog(Item item, {bool isEquipped = false, int? index}) {
    List<String> stats = [];
    if (item.effectiveAttackBonus != 0) {
      stats.add(
        "${item.effectiveAttackBonus > 0 ? '+' : ''}${item.effectiveAttackBonus} ATK",
      );
    }
    if (item.effectiveDamageReduction != 0) {
      stats.add(
        "${item.effectiveDamageReduction > 0 ? '+' : ''}${item.effectiveDamageReduction} Block",
      );
    }
    if (item.effectiveLifeSteal != 0) {
      stats.add(
        "${item.effectiveLifeSteal > 0 ? '+' : ''}${item.effectiveLifeSteal} LifeSteal",
      );
    }
    if (item.effectiveThorns != 0) {
      stats.add(
        "${item.effectiveThorns > 0 ? '+' : ''}${item.effectiveThorns} Thorns",
      );
    }
    if (item.effectiveCritChance != 0) {
      stats.add(
        "${item.effectiveCritChance > 0 ? '+' : ''}${(item.effectiveCritChance * 100).toInt()}% Crit",
      );
    }
    if (item.effectiveHealAmount > 0) {
      stats.add("+${item.effectiveHealAmount} HP Heal");
    }
    if (item.effectiveLuckBonus != 0) {
      stats.add("+${item.effectiveLuckBonus} Luck");
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isEquipped
                      ? Colors.redAccent
                      : rarityColor(item.rarity),
                  width: 1,
                ),
              ),
              title: Row(
                children: [
                  GameImage(
                    imagePath: item.imagePath,
                    fallbackIcon: _getSlotIcon(item.type),
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (item.upgradeLevel > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${item.upgradeLevel}',
                                  style: const TextStyle(
                                    color: Colors.amberAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        rarityBadge(item.rarity, fontSize: 9),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TYPE: ${item.type.name.toUpperCase()}",
                      style: TextStyle(
                        color: rarityColor(item.rarity),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "Stats:",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.join("  |  "),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    // ── Damage Types ──
                    if (item.bonusDamage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "Damage Types:",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.bonusDamage.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: e.key.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: e.key.color.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              "${e.key.icon} ${e.key.label} +${e.value}",
                              style: TextStyle(
                                color: e.key.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (item.canAddDamageType)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Slots: ${item.usedDamageTypeSlots}/${item.availableDamageTypeSlots} (can infuse more)",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                    if (item.type == SlotType.weapon &&
                        item.bonusDamage.isEmpty &&
                        item.availableDamageTypeSlots > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Weapon slots: ${item.usedDamageTypeSlots}/${item.availableDamageTypeSlots} (can infuse damage types)",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                          ),
                        ),
                      ),

                    // ── Resistances ──
                    if (item.flatResistance.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        "Resistances:",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.flatResistance.entries.map((e) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: e.key.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: e.key.color.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              "${e.key.icon} ${e.key.label} +${e.value}",
                              style: TextStyle(
                                color: e.key.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (item.canAddResistance)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Slots: ${item.usedResistanceSlots}/${item.availableResistanceSlots} (can infuse more)",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ),
                    ],
                    if ((item.type == SlotType.armor ||
                            item.type == SlotType.head) &&
                        item.flatResistance.isEmpty &&
                        item.availableResistanceSlots > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Armor slots: ${item.usedResistanceSlots}/${item.availableResistanceSlots} (can infuse resistances)",
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 9,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),
                    const Text(
                      "Description:",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description.isNotEmpty
                          ? item.description
                          : "No further description available.",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    if (!isEquipped && item.sellValue > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Salvage value: ${item.sellValue}c",
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "CLOSE",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                // Upgrade button (for non-equipped items in inventory, town only)
                if (!isEquipped && index != null && item.type != SlotType.item)
                  _buildUpgradeButton(item, index, setDialogState),

                // Infuse buttons (for weapons in inventory, town only)
                if (!isEquipped &&
                    index != null &&
                    item.type == SlotType.weapon &&
                    item.canAddDamageType)
                  _buildInfuseDamageButton(item, index, setDialogState),

                // Infuse buttons (for armor/head in inventory, town only)
                if (!isEquipped &&
                    index != null &&
                    (item.type == SlotType.armor ||
                        item.type == SlotType.head) &&
                    item.canAddResistance)
                  _buildInfuseResistButton(item, index, setDialogState),

                // Use consumable
                if (!isEquipped && index != null && item.healAmount > 0)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      setState(() {
                        widget.player.hp =
                            (widget.player.hp + item.effectiveHealAmount).clamp(
                              0,
                              widget.player.maxHp,
                            );
                        widget.inventory.removeAt(index);
                        _selectedInventoryIndex = null;
                        _selectedEquippedIndex = null;
                      });
                      showStylishPopup(
                        context,
                        title: 'CONSUMED',
                        message:
                            '${item.name} used! Healed +${item.effectiveHealAmount} HP.',
                        icon: Icons.local_hospital,
                        iconColor: Colors.greenAccent,
                      );
                    },
                    icon: const Icon(Icons.local_hospital, size: 16),
                    label: const Text("USE TO HEAL"),
                  ),

                // Salvage button (for inventory items)
                if (!isEquipped && index != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[900],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _showSalvageConfirmation(item, index);
                    },
                    icon: const Icon(Icons.recycling, size: 16),
                    label: Text("SALVAGE (+${item.sellValue}c)"),
                  ),

                // Equip button (shows SWAP if slot is occupied)
                if (!isEquipped && index != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _attemptEquipSequence(item, index);
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: Text(_getEquipLabel(item)),
                  ),

                // Unequip button
                if (isEquipped && index != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[800],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _unequipItem(index);
                    },
                    icon: const Icon(Icons.remove_circle_outline, size: 16),
                    label: const Text("UNEQUIP"),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _getEquipLabel(Item item) {
    // Check if there's an empty slot of this type
    for (int i = 0; i < widget.player.slotLayout.length; i++) {
      if (widget.player.slotLayout[i] == item.type &&
          widget.equippedSlots[i] == null) {
        return "EQUIP";
      }
    }
    // Check if there's a slot of this type (would be a swap)
    for (int i = 0; i < widget.player.slotLayout.length; i++) {
      if (widget.player.slotLayout[i] == item.type) {
        return "SWAP";
      }
    }
    return "EQUIP";
  }

  void _showSalvageConfirmation(Item item, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.orangeAccent),
        ),
        title: const Text(
          "SALVAGE ITEM?",
          style: TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Salvage ${item.name} for ${item.sellValue} credits?\n\nThis cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[800],
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _salvageItem(item, index);
            },
            child: const Text("SALVAGE"),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton(Item item, int index, StateSetter setDialogState) {
    final sameCount = Item.countSameItem(widget.inventory, item);
    final canUpgrade =
        _isInSettlement &&
        sameCount >= 3 &&
        item.upgradeLevel < Item.maxUpgradeLevel &&
        widget.player.credits >= item.upgradeCost;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: canUpgrade ? Colors.amber[800] : Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      onPressed: canUpgrade
          ? () {
              Navigator.pop(context);
              _upgradeItem(item, index);
            }
          : null,
      icon: const Icon(Icons.upgrade, size: 16),
      label: Text(
        _isInSettlement
            ? "UPGRADE (+$item.upgradeLevel)\n$sameCount/3 · ${item.upgradeCost}c"
            : "UPGRADE (settlement only)\n$sameCount/3 · ${item.upgradeCost}c",
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildInfuseDamageButton(
    Item item,
    int index,
    StateSetter setDialogState,
  ) {
    final canInfuse =
        _isInSettlement && widget.player.credits >= item.infuseCost;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: canInfuse ? Colors.deepOrange[800] : Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      onPressed: canInfuse
          ? () {
              Navigator.pop(context);
              _infuseDamageType(item, index);
            }
          : null,
      icon: const Icon(Icons.local_fire_department, size: 16),
      label: Text(
        _isInSettlement
            ? "INFUSE DAMAGE\n${item.usedDamageTypeSlots}/${item.availableDamageTypeSlots} · ${item.infuseCost}c"
            : "INFUSE (settlement only)\n${item.usedDamageTypeSlots}/${item.availableDamageTypeSlots} · ${item.infuseCost}c",
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildInfuseResistButton(
    Item item,
    int index,
    StateSetter setDialogState,
  ) {
    final canInfuse =
        _isInSettlement && widget.player.credits >= item.infuseCost;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: canInfuse ? Colors.blue[800] : Colors.grey[800],
        foregroundColor: Colors.white,
      ),
      onPressed: canInfuse
          ? () {
              Navigator.pop(context);
              _infuseResistance(item, index);
            }
          : null,
      icon: const Icon(Icons.shield, size: 16),
      label: Text(
        _isInSettlement
            ? "INFUSE RESIST\n${item.usedResistanceSlots}/${item.availableResistanceSlots} · ${item.infuseCost}c"
            : "INFUSE (settlement only)\n${item.usedResistanceSlots}/${item.availableResistanceSlots} · ${item.infuseCost}c",
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "HP: ${widget.player.hp}/${widget.player.maxHp}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              "Credits: ${widget.player.credits}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              "ATK: ${widget.player.getEffectiveAttack(widget.equippedSlots)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
                fontSize: 12,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeInfoBox() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.upgrade, color: Colors.amberAccent, size: 14),
              SizedBox(width: 6),
              Text(
                'UPGRADE SYSTEM',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '• Combine 3 same items → +1 upgrade level (+20% stats)\n'
            '• Infuse weapons with damage types\n'
            '• Infuse armor with resistances\n'
            '• Salvage items for credits\n'
            '• Rarity determines max slots (Common:0, Premium:1, Unique:2, Legendary:3)',
            style: TextStyle(color: Colors.white38, fontSize: 9, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// Equipped section: grid + backpack + save button (portrait layout)
  Widget _buildEquippedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildEquippedGrid(),
        const SizedBox(height: 30),
        _buildBackpackSection(),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey[900],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.save),
          label: const Text(
            "SAVE MATRIX CONFIGURATION",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          onPressed: widget.onBack,
        ),
      ],
    );
  }

  /// Equipped grid only (no backpack, used in landscape layout)
  Widget _buildEquippedGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.shield_rounded, color: Colors.redAccent, size: 18),
            SizedBox(width: 8),
            Text(
              "EQUIPPED MATRIX",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.redAccent,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: widget.player.slotLayout.length,
          itemBuilder: (ctx, i) {
            final requiredType = widget.player.slotLayout[i];
            final activeItem = widget.equippedSlots[i];
            final itemColor = activeItem != null
                ? rarityColor(activeItem.rarity)
                : null;

            return InkWell(
              onTap: () {
                if (activeItem != null) {
                  setState(() {
                    _selectedEquippedIndex = i;
                    _selectedInventoryIndex = null;
                  });
                  _showInspectDialog(activeItem, isEquipped: true, index: i);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: activeItem != null
                      ? itemColor!.withValues(alpha: 0.1)
                      : Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedEquippedIndex == i
                        ? Colors.redAccent
                        : (activeItem != null
                              ? itemColor!.withValues(alpha: 0.6)
                              : Colors.transparent),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    GameImage(
                      imagePath: activeItem?.imagePath,
                      fallbackIcon: _getSlotIcon(requiredType),
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            requiredType.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activeItem?.name ?? "[ Vacant ]",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: activeItem != null
                                        ? itemColor
                                        : Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (activeItem != null) ...[
                                const SizedBox(width: 4),
                                rarityBadge(activeItem.rarity),
                              ],
                            ],
                          ),
                          if (activeItem != null && activeItem.upgradeLevel > 0)
                            Text(
                              '+${activeItem.upgradeLevel} UPGRADED',
                              style: const TextStyle(
                                fontSize: 7,
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackpackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.backpack, color: Colors.tealAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "BACKPACK (${widget.inventory.length}/$maxInventorySize)",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.tealAccent,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.inventory.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SortType.values.map((sort) {
                final isSelected = _currentSort == sort;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(sort.icon, size: 12),
                        const SizedBox(width: 4),
                        Text(sort.label),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: Colors.tealAccent.withValues(alpha: 0.2),
                    backgroundColor: Colors.grey[900],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.tealAccent : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() => _currentSort = sort);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 8),
        if (widget.inventory.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                "Storage Bag is currently empty.",
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.inventory.length,
            itemBuilder: (ctx, i) {
              final sortedIdx = _sortedIndices()[i];
              final item = widget.inventory[sortedIdx];
              final sameCount = Item.countSameItem(widget.inventory, item);
              final itemColor = rarityColor(item.rarity);
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedInventoryIndex = sortedIdx;
                    _selectedEquippedIndex = null;
                  });
                  _showInspectDialog(item, isEquipped: false, index: sortedIdx);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedInventoryIndex == sortedIdx
                          ? Colors.tealAccent
                          : itemColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      GameImage(
                        imagePath: item.imagePath,
                        fallbackIcon: _getSlotIcon(item.type),
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.type.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                color: itemColor.withValues(alpha: 0.7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: itemColor,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                rarityBadge(item.rarity),
                              ],
                            ),
                            Row(
                              children: [
                                if (item.upgradeLevel > 0)
                                  Text(
                                    '+${item.upgradeLevel} ',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (sameCount >= 3 &&
                                    item.type != SlotType.item)
                                  Text(
                                    '★$sameCount',
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                if (item.effectiveAttackBonus > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      '⚔${item.effectiveAttackBonus}',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                if (item.effectiveDamageReduction > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      '🛡${item.effectiveDamageReduction}',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                  ),
                                if (item.effectiveCritChance > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Text(
                                      '⚡${(item.effectiveCritChance * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 8,
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.white24,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD & LAYOUTS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isLandscape = Responsive.isLandscape(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Loadout Processing Node")),
      body: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderInfo(),
            const SizedBox(height: 10),
            _buildUpgradeInfoBox(),
            const SizedBox(height: 20),
            _buildEquippedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    final pad = Responsive.horizontalPadding(context);
    return Row(
      children: [
        // ── LEFT: Equipped + Info (no backpack here) ──
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(pad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderInfo(),
                const SizedBox(height: 8),
                _buildUpgradeInfoBox(),
                const SizedBox(height: 12),
                _buildEquippedGrid(),
              ],
            ),
          ),
        ),
        // ── RIGHT: Backpack ──
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0E1018),
              border: Border(left: BorderSide(color: Color(0xFF2A2D3E))),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
                    child: _buildBackpackSection(),
                  ),
                ),
                // Back button
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "SAVE",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: widget.onBack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getSlotIcon(SlotType type) {
    switch (type) {
      case SlotType.head:
        return Icons.military_tech;
      case SlotType.armor:
        return Icons.shield;
      case SlotType.weapon:
        return Icons.gavel;
      case SlotType.item:
        return Icons.hardware;
    }
  }
}
