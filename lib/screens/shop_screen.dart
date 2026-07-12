import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/item.dart';
import '../widgets/game_image.dart';

class ShopScreen extends StatefulWidget {
  final Character player;
  final List<Item> items;
  final List<Item> inventory;
  final VoidCallback onExit;

  const ShopScreen({
    super.key,
    required this.player,
    required this.items,
    required this.inventory,
    required this.onExit,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Terminal Vendor Interface (Credits: ${widget.player.gold})",
        ),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, idx) {
                final item = widget.items[idx];

                // Construct properties text line based on non-zero modifiers
                List<String> stats = [];
                if (item.attackBonus > 0) {
                  stats.add("+${item.attackBonus} ATK");
                }
                if (item.damageReduction > 0) {
                  stats.add("+${item.damageReduction} Block");
                }
                if (item.lifeSteal > 0) {
                  stats.add("+${item.lifeSteal} LifeSteal");
                }
                if (item.thorns > 0) {
                  stats.add("+${item.thorns} Thorns");
                }
                if (item.critChance > 0) {
                  stats.add("+${(item.critChance * 100).toInt()}% Crit");
                }
                if (item.healAmount > 0) {
                  stats.add("+${item.healAmount} Heal");
                }

                String statsSummary =
                    "[${item.type.name.toUpperCase()}] ${stats.join(' | ')}";

                return ListTile(
                  leading: GameImage(
                    imagePath: item.imagePath,
                    fallbackIcon: _getSlotIcon(item.type),
                    size: 40,
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      color: item.id.endsWith('_sale')
                          ? Colors.orangeAccent
                          : Colors.white,
                      fontWeight: item.id.endsWith('_sale')
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    "${item.description}\n$statsSummary",
                    style: const TextStyle(color: Colors.teal, fontSize: 12),
                  ),
                  trailing: ElevatedButton(
                    onPressed: widget.player.gold >= item.cost
                        ? () {
                            setState(() {
                              widget.player.gold -= item.cost;
                              widget.inventory.add(item);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Transferred ${item.name} to storage bag.",
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Text("Buy (${item.cost}g)"),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: widget.onExit,
              child: const Text("Disconnect Terminal"),
            ),
          ),
        ],
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
