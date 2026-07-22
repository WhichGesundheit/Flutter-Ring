import 'package:flutter/material.dart';
import '../models/item.dart';
import '../widgets/game_theme.dart';

/// Shared warehouse data stored at save-slot level (shared between characters).
class WarehouseData {
  List<List<Item>> tabs;
  int purchasedTabCount; // 1 = first tab free

  WarehouseData({List<List<Item>>? tabs, int? purchasedTabCount})
    : tabs = tabs ?? List.generate(6, (_) => <Item>[]),
      purchasedTabCount = purchasedTabCount ?? 1;

  static const int slotsPerTab = 40;
  static const int maxTabs = 6;
  static const List<int> tabCosts = [0, 500, 1000, 2000, 4000, 8000];

  int get totalSlots => purchasedTabCount * slotsPerTab;
  int get nextTabCost =>
      purchasedTabCount < maxTabs ? tabCosts[purchasedTabCount] : -1;

  Map<String, dynamic> toJson() => {
    'tabs': tabs
        .map((tab) => tab.map((item) => item.toJson()).toList())
        .toList(),
    'purchasedTabCount': purchasedTabCount,
  };

  factory WarehouseData.fromJson(Map<String, dynamic> json) {
    final rawTabs = json['tabs'] as List? ?? [];
    final tabs = rawTabs
        .map(
          (tab) => (tab as List)
              .map((e) => Item.fromJson(e as Map<String, dynamic>))
              .toList(),
        )
        .toList();
    // Ensure at least 1 tab
    while (tabs.length < 1) tabs.add(<Item>[]);
    return WarehouseData(
      tabs: tabs,
      purchasedTabCount: json['purchasedTabCount'] as int? ?? 1,
    );
  }
}

class WarehouseScreen extends StatefulWidget {
  final WarehouseData warehouse;
  final List<Item> playerInventory;
  final int maxPlayerInventory;
  final int playerCredits;
  final Function(WarehouseData) onWarehouseChanged;
  final Function(List<Item>) onInventoryChanged;
  final Function(int) onCreditsChanged;
  final VoidCallback onBack;
  final bool isFloating;

  const WarehouseScreen({
    super.key,
    required this.warehouse,
    required this.playerInventory,
    required this.maxPlayerInventory,
    required this.playerCredits,
    required this.onWarehouseChanged,
    required this.onInventoryChanged,
    required this.onCreditsChanged,
    required this.onBack,
    this.isFloating = false,
  });

  @override
  State<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends State<WarehouseScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;

  Widget _buildWarehouseBody() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            // Tab bar with all tabs (locked + unlocked)
            _buildTabBar(),
            const Divider(height: 1, color: Colors.white10),
            // Content
            Expanded(child: _buildTabContent()),
            // Bottom: Deposit/Withdraw instructions
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFloating) {
      return Container(
        decoration: BoxDecoration(
          color: GameColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Floating header with close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: GameColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.cyanAccent.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warehouse,
                    color: Colors.cyanAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Shared Warehouse',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white54,
                      size: 20,
                    ),
                    onPressed: widget.onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildWarehouseBody()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: GameColors.background,
      appBar: AppBar(
        backgroundColor: GameColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: widget.onBack,
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warehouse, color: Colors.cyanAccent, size: 18),
            SizedBox(width: 8),
            Text('Shared Warehouse'),
          ],
        ),
      ),
      body: _buildWarehouseBody(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      color: GameColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: WarehouseData.maxTabs,
        itemBuilder: (context, index) {
          final isUnlocked = index < widget.warehouse.purchasedTabCount;
          final isSelected = _selectedTab == index && isUnlocked;
          final isNextLocked =
              index == widget.warehouse.purchasedTabCount &&
              widget.warehouse.purchasedTabCount < WarehouseData.maxTabs;

          if (isUnlocked) {
            // Unlocked tab
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.cyanAccent.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.cyanAccent : Colors.white24,
                  ),
                ),
                child: Center(
                  child: Text(
                    'TAB ${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.cyanAccent : Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          } else {
            // Locked tab
            return GestureDetector(
              onTap: isNextLocked ? () => _buyNewTab() : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isNextLocked
                        ? GameColors.gold.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.12),
                    style: isNextLocked ? BorderStyle.solid : BorderStyle.none,
                  ),
                ),
                child: isNextLocked
                    ? Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              color: GameColors.gold.withValues(alpha: 0.7),
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.warehouse.nextTabCost}c',
                              style: TextStyle(
                                color: GameColors.gold.withValues(alpha: 0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.white.withValues(alpha: 0.15),
                          size: 14,
                        ),
                      ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTabContent() {
    final tabItems = widget.warehouse.tabs[_selectedTab];
    return Column(
      children: [
        // Warehouse items header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.inventory_2, color: Colors.cyanAccent, size: 14),
              const SizedBox(width: 6),
              const Text(
                'WAREHOUSE',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${tabItems.length}/${WarehouseData.slotsPerTab}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
        // Warehouse grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1.0,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: WarehouseData.slotsPerTab,
            itemBuilder: (context, index) {
              if (index < tabItems.length) {
                return _buildWarehouseItem(tabItems[index], index);
              }
              return _buildEmptySlot(index);
            },
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        // Player inventory header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.backpack, color: GameColors.gold, size: 14),
              const SizedBox(width: 6),
              Text(
                'YOUR INVENTORY',
                style: TextStyle(
                  color: GameColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.playerInventory.length}/${widget.maxPlayerInventory}',
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ],
          ),
        ),
        // Player inventory grid
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: widget.playerInventory.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _depositItem(index),
                child: Container(
                  width: 64,
                  height: 64,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _rarityColor(
                      widget.playerInventory[index].rarity,
                    ).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _rarityColor(
                        widget.playerInventory[index].rarity,
                      ).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _itemIcon(widget.playerInventory[index].type),
                        color: _rarityColor(
                          widget.playerInventory[index].rarity,
                        ),
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.playerInventory[index].name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 7,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWarehouseItem(Item item, int index) {
    return GestureDetector(
      onTap: () => _withdrawItem(index),
      onLongPress: () => _showItemInfo(item),
      child: Container(
        decoration: BoxDecoration(
          color: _rarityColor(item.rarity).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _rarityColor(item.rarity).withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _itemIcon(item.type),
              color: _rarityColor(item.rarity),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.name,
              style: const TextStyle(color: Colors.white70, fontSize: 7),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: GameColors.surface,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white38, size: 14),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Tap warehouse item = withdraw · Tap inventory item = deposit',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  void _depositItem(int inventoryIndex) {
    final tabItems = widget.warehouse.tabs[_selectedTab];
    if (tabItems.length >= WarehouseData.slotsPerTab) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warehouse tab is full!'),
          backgroundColor: GameColors.danger,
        ),
      );
      return;
    }
    final item = widget.playerInventory[inventoryIndex];
    setState(() {
      widget.playerInventory.removeAt(inventoryIndex);
      tabItems.add(item);
    });
    widget.onInventoryChanged(widget.playerInventory);
    widget.onWarehouseChanged(widget.warehouse);
  }

  void _withdrawItem(int warehouseIndex) {
    if (widget.playerInventory.length >= widget.maxPlayerInventory) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inventory is full! Salvage an item first.'),
          backgroundColor: GameColors.danger,
        ),
      );
      return;
    }
    final tabItems = widget.warehouse.tabs[_selectedTab];
    final item = tabItems[warehouseIndex];
    setState(() {
      tabItems.removeAt(warehouseIndex);
      widget.playerInventory.add(item);
    });
    widget.onInventoryChanged(widget.playerInventory);
    widget.onWarehouseChanged(widget.warehouse);
  }

  void _buyNewTab() {
    final cost = widget.warehouse.nextTabCost;
    if (cost < 0) return;

    if (widget.playerCredits < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Need $cost credits (you have ${widget.playerCredits})',
          ),
          backgroundColor: GameColors.danger,
        ),
      );
      return;
    }

    final newTabIndex = widget.warehouse.purchasedTabCount;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: const Text(
          'Buy Warehouse Tab',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Purchase Tab ${newTabIndex + 1} for $cost credits?\n\nEach tab has 40 slots.',
          style: TextStyle(color: Colors.grey[400]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                widget.onCreditsChanged(-cost);
                widget.warehouse.purchasedTabCount++;
                widget.warehouse.tabs.add(<Item>[]);
                // Auto-advance to the newly unlocked tab
                _selectedTab = newTabIndex;
              });
              widget.onWarehouseChanged(widget.warehouse);
            },
            child: Text(
              'Buy (${cost}c)',
              style: const TextStyle(color: GameColors.gold),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemInfo(Item item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GameColors.surface,
        title: Text(
          item.name,
          style: TextStyle(color: _rarityColor(item.rarity)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${item.type.name.toUpperCase()}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            Text(
              'Rarity: ${item.rarity.label}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (item.attackBonus > 0)
              Text(
                'ATK: +${item.attackBonus}',
                style: TextStyle(color: GameColors.primary),
              ),
            if (item.damageReduction > 0)
              Text(
                'DEF: +${item.damageReduction}',
                style: TextStyle(color: GameColors.accent),
              ),
            if (item.critChance > 0)
              Text(
                'CRIT: +${(item.critChance * 100).toInt()}%',
                style: TextStyle(color: GameColors.gold),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(Rarity rarity) {
    switch (rarity) {
      case Rarity.common:
        return Colors.grey;
      case Rarity.premium:
        return Colors.blueAccent;
      case Rarity.unique:
        return Colors.purpleAccent;
      case Rarity.legendary:
        return Colors.amber;
    }
  }

  IconData _itemIcon(SlotType type) {
    switch (type) {
      case SlotType.head:
        return Icons.face;
      case SlotType.armor:
        return Icons.shield;
      case SlotType.weapon:
        return Icons.gavel;
      case SlotType.item:
        return Icons.diamond;
    }
  }
}
