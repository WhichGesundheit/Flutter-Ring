import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/npc.dart';
import '../models/status_effect.dart';
import '../models/character.dart';
import '../widgets/game_image.dart';
import '../widgets/game_theme.dart';
import 'inventory_screen.dart';

/// GLEED's Gambling Den – Buy mystery boxes, cure status effects
class GleedScreen extends StatefulWidget {
  final Character player;
  final List<Item> inventory;
  final int maxInventory;
  final VoidCallback onExit;
  final VoidCallback onCureStatus;

  const GleedScreen({
    super.key,
    required this.player,
    required this.inventory,
    required this.maxInventory,
    required this.onExit,
    required this.onCureStatus,
  });

  @override
  State<GleedScreen> createState() => _GleedScreenState();
}

class _GleedScreenState extends State<GleedScreen> {
  Item? _lastUnboxedItem;
  bool _showUnboxResult = false;
  MysteryBoxTier? _lastTier;

  void _buyMysteryBox(MysteryBoxTier tier) {
    if (widget.player.credits < tier.price) {
      _showSnackBar(
        'Not enough credits! Need ${tier.price}c',
        Colors.redAccent,
      );
      return;
    }
    if (widget.inventory.length >= widget.maxInventory) {
      _showSnackBar('Inventory full!', Colors.orangeAccent);
      return;
    }

    setState(() {
      widget.player.credits -= tier.price;
      final luckMod = widget.player.getEffectiveLuck([]).toDouble();
      _lastUnboxedItem = GleedShop.rollMysteryBox(tier, luckModifier: luckMod);
      _lastTier = tier;
      _showUnboxResult = true;
    });
  }

  void _collectItem() {
    if (_lastUnboxedItem != null) {
      widget.inventory.add(_lastUnboxedItem!);
      setState(() {
        _lastUnboxedItem = null;
        _showUnboxResult = false;
        _lastTier = null;
      });
    }
  }

  void _scrapItem() {
    if (_lastUnboxedItem != null) {
      setState(() {
        widget.player.credits += _lastUnboxedItem!.sellValue;
        _lastUnboxedItem = null;
        _showUnboxResult = false;
        _lastTier = null;
      });
    }
  }

  void _attemptCure() {
    if (GleedShop.attemptGamblingCure()) {
      widget.onCureStatus();
      _showSnackBar(
        'GLEED\'s luck rubs off — a status effect has been cured!',
        Colors.greenAccent,
      );
    } else {
      _showSnackBar(
        'GLEED shrugs. "Bad luck, friend. Try again."',
        Colors.orangeAccent,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color.withValues(alpha: 0.8),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _hasCureableEffects => widget.player.activeStatusEffects.any(
    (e) => e.cureMethod == CureMethod.gambling,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🃏 ', style: TextStyle(fontSize: 20)),
            Text(
              "GLEED'S DEN",
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF111522),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _showUnboxResult ? _buildUnboxResult() : _buildShop(),
    );
  }

  Widget _buildShop() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // GLEED intro
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: GameColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amberAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text('🃏', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                const Text(
                  '"Welcome, welcome! Step right up to GLEED\'s Den!"',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Credits: ${widget.player.credits}c',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Mystery boxes
          const Text(
            'MYSTERY BOXES',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          ...MysteryBoxTier.values.map((tier) => _buildMysteryBoxCard(tier)),
          const SizedBox(height: 20),

          // Gambling cure
          if (_hasCureableEffects) ...[
            const Text(
              'STATUS CURE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GameColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.tealAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '"Feeling cursed? A gamble might shake it off..."',
                    style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '30% chance to cure cursed/weakened status effects',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _attemptCure,
                    child: const Text(
                      'TRY YOUR LUCK',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Leave button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GameColors.surface,
                foregroundColor: Colors.white54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: widget.onExit,
              child: const Text(
                'LEAVE THE DEN',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMysteryBoxCard(MysteryBoxTier tier) {
    final canAfford = widget.player.credits >= tier.price;
    final hasSpace = widget.inventory.length < widget.maxInventory;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canAfford && hasSpace
              ? Colors.amberAccent.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Box icon
          Text(tier.icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.label,
                  style: TextStyle(
                    color: canAfford ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tier.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),

          // Buy button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford && hasSpace
                  ? Colors.amber[800]
                  : Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: canAfford && hasSpace
                ? () => _buyMysteryBox(tier)
                : null,
            child: Text(
              '${tier.price}c',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnboxResult() {
    if (_lastUnboxedItem == null) return const SizedBox.shrink();

    final item = _lastUnboxedItem!;
    final color = rarityColor(item.rarity);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Reveal animation placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: GameImage(
                imagePath: item.imagePath,
                fallbackIcon: _getSlotIcon(item.type),
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            _lastTier?.label ?? 'Mystery Box',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            item.name,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          rarityBadge(item.rarity, fontSize: 10),
          const SizedBox(height: 12),

          Text(
            item.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Stats preview
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GameColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _getItemStatsPreview(item),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _collectItem,
                  child: const Text(
                    'COLLECT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _scrapItem,
                  child: Text(
                    'SCRAP (+${item.sellValue}c)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getItemStatsPreview(Item item) {
    final stats = <String>[];
    if (item.effectiveAttackBonus > 0)
      stats.add('+${item.effectiveAttackBonus} ATK');
    if (item.effectiveDamageReduction > 0) {
      stats.add('+${item.effectiveDamageReduction} Block');
    }
    if (item.effectiveLifeSteal > 0)
      stats.add('+${item.effectiveLifeSteal} LS');
    if (item.effectiveThorns > 0) stats.add('+${item.effectiveThorns} Thorns');
    if (item.effectiveCritChance > 0) {
      stats.add('+${(item.effectiveCritChance * 100).toInt()}% Crit');
    }
    if (item.effectiveHealAmount > 0)
      stats.add('+${item.effectiveHealAmount} Heal');
    if (item.effectiveLuckBonus > 0)
      stats.add('+${item.effectiveLuckBonus} Luck');
    return stats.isEmpty ? 'No bonus stats' : stats.join('  |  ');
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
