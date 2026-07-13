import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/damage_type.dart';
import '../models/item.dart';
import '../widgets/game_image.dart';
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

class InventoryScreen extends StatefulWidget {
  final Character player;
  final List<Item> inventory;
  final List<Item?> equippedSlots;
  final VoidCallback onBack;

  const InventoryScreen({
    super.key,
    required this.player,
    required this.inventory,
    required this.equippedSlots,
    required this.onBack,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int? _selectedInventoryIndex;
  int? _selectedEquippedIndex;

  void _attemptEquipSequence(Item item, int inventoryIndex) {
    int targetingIndex = -1;
    for (int i = 0; i < widget.player.slotLayout.length; i++) {
      if (widget.player.slotLayout[i] == item.type &&
          widget.equippedSlots[i] == null) {
        targetingIndex = i;
        break;
      }
    }

    if (targetingIndex != -1) {
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
      showStylishPopup(
        context,
        title: 'SLOT UNAVAILABLE',
        message: 'No open ${item.type.name.toUpperCase()} slot available.',
        icon: Icons.warning_amber,
        iconColor: Colors.orangeAccent,
      );
    }
  }

  void _unequipItem(int index) {
    final item = widget.equippedSlots[index];
    if (item != null) {
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
      // Remove 2 copies from inventory (the base stays, 2 are consumed)
      int removed = 0;
      for (int i = widget.inventory.length - 1; i >= 0 && removed < 2; i--) {
        if (widget.inventory[i].id == item.id) {
          widget.inventory.removeAt(i);
          removed++;
        }
      }
      // Replace the original with the upgraded version
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

    // Pick a random damage type that isn't already on the item
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
                  color: isEquipped ? Colors.redAccent : Colors.tealAccent,
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
                            style: TextStyle(
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
                          style: TextStyle(color: Colors.white38, fontSize: 9),
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
                            style: TextStyle(
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
                          style: TextStyle(color: Colors.white38, fontSize: 9),
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

                // Upgrade button (for non-equipped items in inventory)
                if (!isEquipped && index != null && item.type != SlotType.item)
                  _buildUpgradeButton(item, index, setDialogState),

                // Infuse buttons (for weapons in inventory)
                if (!isEquipped &&
                    index != null &&
                    item.type == SlotType.weapon &&
                    item.canAddDamageType)
                  _buildInfuseDamageButton(item, index, setDialogState),

                // Infuse buttons (for armor/head in inventory)
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

                // Equip button
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
                    label: const Text("EQUIP"),
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

  Widget _buildUpgradeButton(Item item, int index, StateSetter setDialogState) {
    final sameCount = Item.countSameItem(widget.inventory, item);
    final canUpgrade =
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
        "UPGRADE (+$item.upgradeLevel)\n$sameCount/3 · ${item.upgradeCost}c",
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildInfuseDamageButton(
    Item item,
    int index,
    StateSetter setDialogState,
  ) {
    final canInfuse = widget.player.credits >= item.infuseCost;
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
        "INFUSE DAMAGE\n${item.usedDamageTypeSlots}/${item.availableDamageTypeSlots} · ${item.infuseCost}c",
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildInfuseResistButton(
    Item item,
    int index,
    StateSetter setDialogState,
  ) {
    final canInfuse = widget.player.credits >= item.infuseCost;
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
        "INFUSE RESIST\n${item.usedResistanceSlots}/${item.availableResistanceSlots} · ${item.infuseCost}c",
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Loadout Processing Node")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER INFO
              Container(
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
              ),
              const SizedBox(height: 10),

              // ── UPGRADE INFO BOX ──
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.upgrade,
                          color: Colors.amberAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
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
                    const SizedBox(height: 4),
                    Text(
                      '• Combine 3 same items → +1 upgrade level (+20% stats)\n'
                      '• Infuse weapons with damage types\n'
                      '• Infuse armor with resistances\n'
                      '• Rarity determines max slots (Common:0, Premium:1, Unique:2, Legendary:3)',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // EQUIPPED MATRIX SECTION
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Colors.redAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "EQUIPPED MATRIX (Tap to Inspect / Unequip)",
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

                  return InkWell(
                    onTap: () {
                      if (activeItem != null) {
                        setState(() {
                          _selectedEquippedIndex = i;
                          _selectedInventoryIndex = null;
                        });
                        _showInspectDialog(
                          activeItem,
                          isEquipped: true,
                          index: i,
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: activeItem != null
                            ? Colors.red[950]?.withValues(alpha: 0.6)
                            : Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedEquippedIndex == i
                              ? Colors.redAccent
                              : (activeItem != null
                                    ? Colors.red[900]!
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
                                              ? Colors.white
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
                                if (activeItem != null &&
                                    activeItem.upgradeLevel > 0)
                                  Text(
                                    '+${activeItem.upgradeLevel} UPGRADED',
                                    style: TextStyle(
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
              const SizedBox(height: 30),

              // BACKPACK INVENTORY SECTION
              const Row(
                children: [
                  Icon(Icons.backpack, color: Colors.tealAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "BACKPACK INVENTORY (Tap to Inspect / Equip / Upgrade)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.tealAccent,
                      letterSpacing: 1,
                    ),
                  ),
                ],
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: widget.inventory.length,
                  itemBuilder: (ctx, i) {
                    final item = widget.inventory[i];
                    final sameCount = Item.countSameItem(
                      widget.inventory,
                      item,
                    );
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedInventoryIndex = i;
                          _selectedEquippedIndex = null;
                        });
                        _showInspectDialog(item, isEquipped: false, index: i);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedInventoryIndex == i
                                ? Colors.tealAccent
                                : Colors.grey[800]!,
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
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.teal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
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
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.amberAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (sameCount >= 3 &&
                                          item.type != SlotType.item)
                                        Text(
                                          '★$sameCount',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.amberAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ...item.bonusDamage.entries
                                          .take(2)
                                          .map(
                                            (e) => Padding(
                                              padding: const EdgeInsets.only(
                                                right: 2,
                                              ),
                                              child: Text(
                                                e.key.icon,
                                                style: TextStyle(fontSize: 8),
                                              ),
                                            ),
                                          ),
                                      ...item.flatResistance.entries
                                          .take(2)
                                          .map(
                                            (e) => Padding(
                                              padding: const EdgeInsets.only(
                                                right: 2,
                                              ),
                                              child: Text(
                                                e.key.icon,
                                                style: TextStyle(fontSize: 8),
                                              ),
                                            ),
                                          ),
                                    ],
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
              const SizedBox(height: 30),

              // SAVE MATRIX CONFIGURATION
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
          ),
        ),
      ),
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
