import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/item.dart';
import '../widgets/game_image.dart';
import '../widgets/stylish_popup.dart';

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
  bool _showSellTab = false;

  Color _rarityColor(Rarity r) {
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

  Widget _rarityBadge(Rarity r) {
    final color = _rarityColor(r);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        r.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Terminal Vendor  ·  Credits: ${widget.player.credits}"),
        automaticallyImplyLeading: false,
        actions: [
          // Toggle buy/sell tabs
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                _tabChip('BUY', !_showSellTab, () {
                  setState(() => _showSellTab = false);
                }),
                const SizedBox(width: 4),
                _tabChip('SELL', _showSellTab, () {
                  setState(() => _showSellTab = true);
                }),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _showSellTab ? _buildSellList() : _buildBuyList()),
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

  // ── Tab chip helper ──
  Widget _tabChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? Colors.cyanAccent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? Colors.cyanAccent : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.cyanAccent : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUY TAB
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildBuyList() {
    // Sort by rarity then cost
    final sorted = List<Item>.from(widget.items)
      ..sort((a, b) {
        final rarityCmp = a.rarity.sortOrder.compareTo(b.rarity.sortOrder);
        if (rarityCmp != 0) return rarityCmp;
        return a.cost.compareTo(b.cost);
      });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, idx) {
        final item = sorted[idx];
        final color = _rarityColor(item.rarity);
        final canBuy = widget.player.credits >= item.cost;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              GameImage(
                imagePath: item.imagePath,
                fallbackIcon: _getSlotIcon(item.type),
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _rarityBadge(item.rarity),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canBuy ? color : Colors.grey[800],
                  foregroundColor: canBuy ? Colors.black : Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                onPressed: canBuy
                    ? () {
                        setState(() {
                          widget.player.credits -= item.cost;
                          widget.inventory.add(item);
                        });
                        showStylishPopup(
                          context,
                          title: 'ACQUIRED',
                          message:
                              '${item.name} (${item.rarity.label}) transferred to storage.',
                          icon: Icons.inventory_2,
                          iconColor: _rarityColor(item.rarity),
                        );
                      }
                    : null,
                child: Text(
                  '${item.cost}c',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SELL TAB
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildSellList() {
    if (widget.inventory.isEmpty) {
      return const Center(
        child: Text(
          'No items to sell.',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    // Sort inventory: rarity desc, then cost desc (most valuable first)
    final sorted = List<Item>.from(widget.inventory)
      ..sort((a, b) {
        final rarityCmp = b.rarity.sortOrder.compareTo(a.rarity.sortOrder);
        if (rarityCmp != 0) return rarityCmp;
        return b.cost.compareTo(a.cost);
      });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, idx) {
        final item = sorted[idx];
        final color = _rarityColor(item.rarity);

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D2E),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              GameImage(
                imagePath: item.imagePath,
                fallbackIcon: _getSlotIcon(item.type),
                size: 36,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _rarityBadge(item.rarity),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    widget.inventory.removeAt(widget.inventory.indexOf(item));
                    widget.player.credits += item.sellValue;
                  });
                  showStylishPopup(
                    context,
                    title: 'SOLD',
                    message: '${item.name} sold for ${item.sellValue} credits.',
                    icon: Icons.monetization_on,
                    iconColor: Colors.greenAccent,
                  );
                },
                child: Text(
                  '+${item.sellValue}c',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
