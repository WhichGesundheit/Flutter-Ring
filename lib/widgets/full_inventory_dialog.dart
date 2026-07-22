import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/character.dart';
import '../screens/inventory_screen.dart';
import '../widgets/game_image.dart';
import '../widgets/game_theme.dart';

/// Dialog shown when the player's inventory is full and they receive new loot.
/// Shows the incoming item at the top and the current inventory below with
/// SALVAGE buttons. After each salvage, auto-adds the incoming item if space.
class FullInventoryDialog extends StatefulWidget {
  final Item incomingItem;
  final List<Item> inventory;
  final Character player;
  final VoidCallback onSalvageDone; // Called when space is freed and item added
  final VoidCallback onDismiss; // Called when player dismisses (item lost)

  const FullInventoryDialog({
    super.key,
    required this.incomingItem,
    required this.inventory,
    required this.player,
    required this.onSalvageDone,
    required this.onDismiss,
  });

  @override
  State<FullInventoryDialog> createState() => _FullInventoryDialogState();
}

class _FullInventoryDialogState extends State<FullInventoryDialog> {
  @override
  Widget build(BuildContext context) {
    final incomingColor = rarityColor(widget.incomingItem.rarity);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1D2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: GameColors.danger.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: GameColors.danger, size: 24),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'INVENTORY FULL',
              style: TextStyle(
                color: GameColors.danger,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Incoming item preview ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: incomingColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: incomingColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  GameImage(
                    imagePath: widget.incomingItem.imagePath,
                    fallbackIcon: Icons.inventory_2,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INCOMING ITEM',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.incomingItem.name,
                          style: TextStyle(
                            color: incomingColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        rarityBadge(widget.incomingItem.rarity, fontSize: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Instructions ──
            Text(
              'Salvage an item to free a slot. Salvaged items give their sell value in credits.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 8),

            // ── Inventory list ──
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(6),
                itemCount: widget.inventory.length,
                itemBuilder: (context, index) {
                  final item = widget.inventory[index];
                  final color = rarityColor(item.rarity);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(_getSlotIcon(item.type), color: color, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Sell: ${item.sellValue}c',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[900],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _salvageItem(index),
                          child: const Text(
                            'SALVAGE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onDismiss,
          child: Text(
            'LOSE ITEM',
            style: TextStyle(
              color: GameColors.danger.withValues(alpha: 0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _salvageItem(int index) {
    final item = widget.inventory[index];
    final sellValue = item.sellValue;

    setState(() {
      widget.inventory.removeAt(index);
      widget.player.credits += sellValue;
    });

    // Check if space is now available
    if (widget.inventory.length < 10) {
      // 10 is the max inventory size
      widget.onSalvageDone();
      Navigator.of(context).pop(true);
      return;
    }
  }

  IconData _getSlotIcon(SlotType type) {
    switch (type) {
      case SlotType.weapon:
        return Icons.flash_on;
      case SlotType.armor:
        return Icons.shield;
      case SlotType.head:
        return Icons.psychology;
      case SlotType.item:
        return Icons.inventory_2;
    }
  }
}
