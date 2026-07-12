import 'package:flutter/material.dart';
import '../models/character.dart';
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

  void _showInspectDialog(Item item, {bool isEquipped = false, int? index}) {
    List<String> stats = [];
    if (item.attackBonus != 0) {
      stats.add("${item.attackBonus > 0 ? '+' : ''}${item.attackBonus} ATK");
    }
    if (item.damageReduction != 0) {
      stats.add(
        "${item.damageReduction > 0 ? '+' : ''}${item.damageReduction} Block",
      );
    }
    if (item.lifeSteal != 0) {
      stats.add("${item.lifeSteal > 0 ? '+' : ''}${item.lifeSteal} LifeSteal");
    }
    if (item.thorns != 0) {
      stats.add("${item.thorns > 0 ? '+' : ''}${item.thorns} Thorns");
    }
    if (item.critChance != 0) {
      stats.add(
        "${item.critChance > 0 ? '+' : ''}${(item.critChance * 100).toInt()}% Crit",
      );
    }
    if (item.healAmount > 0) {
      stats.add("+${item.healAmount} HP Heal");
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    rarityBadge(item.rarity, fontSize: 9),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
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
              const SizedBox(height: 12),
              if (stats.isNotEmpty) ...[
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
                const SizedBox(height: 12),
              ],
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
            ),
            if (!isEquipped && index != null && item.healAmount > 0)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    widget.player.hp = (widget.player.hp + item.healAmount)
                        .clamp(0, widget.player.maxHp);
                    widget.inventory.removeAt(index);
                    _selectedInventoryIndex = null;
                    _selectedEquippedIndex = null;
                  });
                  showStylishPopup(
                    context,
                    title: 'CONSUMED',
                    message:
                        '${item.name} used! Healed +${item.healAmount} HP.',
                    icon: Icons.local_hospital,
                    iconColor: Colors.greenAccent,
                  );
                },
                icon: const Icon(Icons.local_hospital, size: 16),
                label: const Text("USE TO HEAL"),
              ),
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
            if (isEquipped && index != null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[850],
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "HP: ${widget.player.hp}/${widget.player.maxHp}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Credits: ${widget.player.credits}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    Text(
                      "Total ATK: ${widget.player.getEffectiveAttack(widget.equippedSlots)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
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
                    "BACKPACK INVENTORY (Tap to Inspect / Equip)",
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
