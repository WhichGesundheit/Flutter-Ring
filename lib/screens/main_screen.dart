import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/damage_type.dart';
import '../models/item.dart';
import '../models/zone.dart';
import '../widgets/game_image.dart';
import '../widgets/game_theme.dart';
import '../widgets/node_screen_widget.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/status_effect_display.dart';
import 'inventory_screen.dart';

class MainScreen extends StatelessWidget {
  final Character player;
  final int hoursPassed;
  final ZoneType currentZone;
  final List<Item?> equippedSlots;
  final List<Item> inventory;
  final Function(String) onChangeScreen;
  final Future<bool> Function()? onSave;
  final Future<bool> Function()? onSyncCloud;
  final int? saveSlot;
  final VoidCallback? onQuitToTitle;

  const MainScreen({
    super.key,
    required this.player,
    required this.hoursPassed,
    required this.currentZone,
    required this.equippedSlots,
    required this.inventory,
    required this.onChangeScreen,
    this.onSave,
    this.onSyncCloud,
    this.saveSlot,
    this.onQuitToTitle,
  });

  @override
  Widget build(BuildContext context) {
    final int days = hoursPassed ~/ 24;
    final int hours = hoursPassed % 24;

    // Compute effective stats from equipment
    int totalAtk = player.baseAttack + player.statusAttackModifier;
    int totalBlock = player.statusDefenseModifier;
    int totalLifeSteal = 0;
    int totalThorns = 0;
    double totalCrit = 0.0;
    int totalLuck = 0;
    Map<DamageType, int> totalBonusDamage = {};
    Map<DamageType, int> totalResistances = {};

    for (var item in equippedSlots) {
      if (item == null) continue;
      totalAtk += item.effectiveAttackBonus;
      totalBlock += item.effectiveDamageReduction;
      totalLifeSteal += item.effectiveLifeSteal;
      totalThorns += item.effectiveThorns;
      totalCrit += item.effectiveCritChance;
      totalLuck += item.effectiveLuckBonus;

      item.effectiveBonusDamage.forEach((type, value) {
        totalBonusDamage[type] = (totalBonusDamage[type] ?? 0) + value;
      });

      item.effectiveFlatResistance.forEach((type, value) {
        totalResistances[type] = (totalResistances[type] ?? 0) + value;
      });
    }

    totalCrit += totalLuck * 0.01;
    totalLuck += player.statusLuckModifier.round();

    final zoneData = Zone.worldMap[currentZone]!;

    return Scaffold(
      backgroundColor: GameColors.background,
      body: OrientationLayout(
        portrait: _buildPortraitLayout(
          context,
          days,
          hours,
          zoneData,
          totalAtk,
          totalBlock,
          totalLifeSteal,
          totalThorns,
          totalCrit,
          totalLuck,
          totalBonusDamage,
          totalResistances,
        ),
        landscape: _buildLandscapeLayout(
          context,
          days,
          hours,
          zoneData,
          totalAtk,
          totalBlock,
          totalLifeSteal,
          totalThorns,
          totalCrit,
          totalLuck,
          totalBonusDamage,
          totalResistances,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PORTRAIT LAYOUT (original vertical Column)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPortraitLayout(
    BuildContext context,
    int days,
    int hours,
    Zone zoneData,
    int totalAtk,
    int totalBlock,
    int totalLifeSteal,
    int totalThorns,
    double totalCrit,
    int totalLuck,
    Map<DamageType, int> totalBonusDamage,
    Map<DamageType, int> totalResistances,
  ) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTimeBar(context, days, hours, zoneData),
                  const SizedBox(height: 12),
                  _buildPlayerCard(context, false),
                  const SizedBox(height: 12),
                  _buildStatsPanel(
                    context,
                    false,
                    totalAtk,
                    totalBlock,
                    totalLifeSteal,
                    totalThorns,
                    totalCrit,
                    totalLuck,
                    totalBonusDamage,
                    totalResistances,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // Portrait: action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: zoneData.color,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: zoneData.color.withValues(alpha: 0.4),
                    ),
                    onPressed: () => onChangeScreen('node_screen'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(zoneData.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "VIEW NODE — ${zoneData.name.toUpperCase()}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bank & Warehouse buttons for settlements
                if (zoneData.isSettlement) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: GameColors.gold,
                            side: BorderSide(
                              color: GameColors.gold.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => onChangeScreen('bank'),
                          icon: const Icon(Icons.account_balance, size: 16),
                          label: const Text(
                            "BANK",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.cyanAccent,
                            side: BorderSide(
                              color: Colors.cyanAccent.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => onChangeScreen('warehouse'),
                          icon: const Icon(Icons.warehouse, size: 16),
                          label: const Text(
                            "WAREHOUSE",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LANDSCAPE LAYOUT: Left = portrait content, Right = NodeScreenWidget
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLandscapeLayout(
    BuildContext context,
    int days,
    int hours,
    Zone zoneData,
    int totalAtk,
    int totalBlock,
    int totalLifeSteal,
    int totalThorns,
    double totalCrit,
    int totalLuck,
    Map<DamageType, int> totalBonusDamage,
    Map<DamageType, int> totalResistances,
  ) {
    final pad = Responsive.horizontalPadding(context);
    return SafeArea(
      child: Row(
        children: [
          // ── LEFT PANEL: Full portrait content (time + player + stats) ──
          SizedBox(
            width: 400,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTimeBar(context, days, hours, zoneData),
                  const SizedBox(height: 10),
                  _buildPlayerCard(context, true),
                  const SizedBox(height: 10),
                  _buildStatsPanel(
                    context,
                    true,
                    totalAtk,
                    totalBlock,
                    totalLifeSteal,
                    totalThorns,
                    totalCrit,
                    totalLuck,
                    totalBonusDamage,
                    totalResistances,
                  ),
                ],
              ),
            ),
          ),
          // ── RIGHT PANEL: Node screen visual ──
          Expanded(
            child: NodeScreenWidget(
              currentZone: currentZone,
              onScout: () => onChangeScreen('travel'),
              onInventory: () => _showInventoryOverlay(context),
              onBank: zoneData.isSettlement
                  ? () => onChangeScreen('bank')
                  : null,
              onWarehouse: zoneData.isSettlement
                  ? () => onChangeScreen('warehouse')
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows inventory as a floating overlay on the right side in landscape.
  void _showInventoryOverlay(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = (screenWidth * 0.9).clamp(400.0, 900.0);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GameColors.accent.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.centerRight,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogWidth,
            maxHeight: screenHeight * 0.85,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Title bar with close button ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: GameColors.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: GameColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2,
                        color: GameColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'INVENTORY OVERLOAD',
                          style: TextStyle(
                            color: GameColors.accent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          onChangeScreen('main');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: GameColors.surfaceLight,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: GameColors.border),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Inventory content ──
                Flexible(
                  child: InventoryScreen(
                    player: player,
                    inventory: inventory,
                    equippedSlots: equippedSlots,
                    currentZone: currentZone,
                    onBack: () {
                      Navigator.pop(ctx);
                      onChangeScreen('main');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTimeBar(
    BuildContext context,
    int days,
    int hours,
    Zone zoneData,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "DAY $days  ·  $hours:00",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(zoneData.icon, color: zoneData.color, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    zoneData.name.toUpperCase(),
                    style: TextStyle(
                      color: zoneData.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _showMainMenu(context),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: GameColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: GameColors.border),
              ),
              child: const Icon(
                Icons.menu_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, bool isLandscape) {
    final imageHeight = isLandscape
        ? MediaQuery.of(context).size.height * 0.35
        : MediaQuery.of(context).size.height * 0.3;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StatusEffectDisplay(
                effects: player.activeStatusEffects,
                maxHeight: MediaQuery.of(context).size.height * 0.25,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: imageHeight,
                  child: GameImage(
                    imagePath: player.imagePath,
                    fallbackIcon: Icons.person,
                    size: imageHeight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 36),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            player.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            player.className,
            style: TextStyle(
              color: GameColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          HpBar(
            current: player.hp,
            max: player.effectiveMaxHp,
            height: 12,
            showLabel: true,
            showNumbers: true,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monetization_on, color: GameColors.gold, size: 14),
              const SizedBox(width: 4),
              Text(
                '${player.credits} Credits',
                style: TextStyle(
                  color: GameColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(
    BuildContext context,
    bool isLandscape,
    int totalAtk,
    int totalBlock,
    int totalLifeSteal,
    int totalThorns,
    double totalCrit,
    int totalLuck,
    Map<DamageType, int> totalBonusDamage,
    Map<DamageType, int> totalResistances,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GameColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMBAT STATS',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatGrid(context, [
            _StatItem(
              '⚔️',
              'ATK',
              '$totalAtk',
              GameColors.primary,
              'Attack Power',
              'The base damage you deal per turn in combat.',
              'Base ATK (${player.baseAttack}) + Equipment Bonus + Status Effects = $totalAtk',
            ),
            _StatItem(
              '🛡️',
              'DEF',
              '$totalBlock',
              GameColors.accent,
              'Damage Reduction',
              'Flat damage subtracted from every enemy attack.',
              'Each point of DEF reduces incoming damage by 1.\nCurrent: $totalBlock flat reduction.',
            ),
            _StatItem(
              '💥',
              'CRIT',
              '${(totalCrit * 100).toInt()}%',
              GameColors.gold,
              'Critical Hit Chance',
              'Chance to deal 2× damage on an attack.',
              'Crit = Equipment Crit% + (Luck × 1%)\n= ${(totalCrit * 100).toInt()}% chance to deal double damage.',
            ),
            _StatItem(
              '🍀',
              'LUCK',
              '$totalLuck',
              Colors.lightGreen,
              'Luck',
              'Increases crit chance (+1% per point), drop rates, and event outcomes.',
              'Each Luck point adds +1% crit chance and +2% drop chance.\nTotal Luck: $totalLuck',
            ),
            if (totalLifeSteal > 0)
              _StatItem(
                '🩸',
                'STEAL',
                '$totalLifeSteal',
                Colors.redAccent,
                'Life Steal',
                'Heals you for this amount after every successful attack.',
                'After each attack, heal for $totalLifeSteal HP.\nCannot exceed max HP.',
              ),
            if (totalThorns > 0)
              _StatItem(
                '🌵',
                'THORN',
                '$totalThorns',
                Colors.green,
                'Thorns',
                'Deals flat damage back to the enemy every turn, even when hit.',
                'Each turn, reflect $totalThorns damage to the attacker.\nApplied after enemy attacks.',
              ),
          ]),
          if (totalBonusDamage.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'BONUS DAMAGE',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: totalBonusDamage.entries
                  .map(
                    (e) => GestureDetector(
                      onTap: () =>
                          _showDamageTypePopup(context, e.key, e.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: e.key.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: e.key.color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${e.key.icon} ${e.key.label}: +${e.value}',
                          style: TextStyle(
                            color: e.key.color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (totalResistances.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'RESISTANCES',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: totalResistances.entries
                  .map(
                    (e) => GestureDetector(
                      onTap: () =>
                          _showResistancePopup(context, e.key, e.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: e.key.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: e.key.color.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${e.key.icon} ${e.key.label}: +${e.value}',
                          style: TextStyle(
                            color: e.key.color,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAIN MENU
  // ═══════════════════════════════════════════════════════════════════════════

  void _showMainMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MainMenuSheet(
        player: player,
        hasCloudSync: onSyncCloud != null,
        hasSaveSlot: saveSlot != null,
        onSave: onSave,
        onSyncCloud: onSyncCloud,
        onViewHelp: () => _showHelpPopup(context),
        onViewAbout: () => _showAboutPopup(context),
        onLoadSaveManager: () {
          Navigator.pop(ctx);
          onChangeScreen('save_manager');
        },
        onQuitToTitle: () {
          Navigator.pop(ctx);
          if (onQuitToTitle != null) {
            onQuitToTitle!();
          }
        },
        onChangeScreen: onChangeScreen,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELP POPUP
  // ═══════════════════════════════════════════════════════════════════════════

  void _showHelpPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GameColors.accent.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: GameColors.accent, size: 24),
            const SizedBox(width: 10),
            const Text(
              'How to Play',
              style: TextStyle(
                color: GameColors.accent,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _helpSection(
                '⚔️ Combat',
                'Tap "Scout Adjacent Node" to explore. You\'ll encounter enemies, shops, events, and loot. Combat is auto-resolved each turn based on your stats.',
              ),
              _helpSection(
                '🛡️ Equipment',
                'Open "Matrix Configuration" to equip gear. Each class has a unique slot layout — match items to the right slot types for maximum power.',
              ),
              _helpSection(
                '📊 Stats',
                'ATK = damage per turn. DEF = flat damage reduction. CRIT = chance for 2× damage. LUCK boosts crit and drop rates.',
              ),
              _helpSection(
                '🗺️ Zones',
                'Different zones offer different encounters. Towns have shops and healing. The Citadel has a chance for boss fights.',
              ),
              _helpSection(
                '💀 Bosses',
                'Weekly bosses appear on days 2, 4, and 6. On day 7, a HYPER boss forces you into battle. Prepare well!',
              ),
              _helpSection(
                '💾 Saving',
                'Your game auto-saves. Use the menu (☰) to manually save or sync to the cloud.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _helpSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ABOUT POPUP
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAboutPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: GameColors.primary.withValues(alpha: 0.4)),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: GameColors.primary, size: 24),
            const SizedBox(width: 10),
            const Text(
              'About',
              style: TextStyle(
                color: GameColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Flutter Ring',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A cyberpunk roguelike where you navigate corrupted data '
              'zones, battle hostile constructs, and upgrade your gear '
              'to survive the ever-growing threat of the Ring.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GameColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: GameColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Built with Flutter\n'
                'Open Source on GitHub',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAT POPUPS (unchanged)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showStatPopup(
    BuildContext context,
    String icon,
    String label,
    String value,
    Color color,
    String title,
    String description,
    String formula,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Current: $value',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
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
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                formula,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showDamageTypePopup(BuildContext context, DamageType type, int value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: type.color.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              type.label,
              style: TextStyle(
                color: type.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type.effectDescription,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: type.color.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Bonus Damage: +$value\nReduces enemy HP by $value each attack (before crit).',
                style: TextStyle(
                  color: type.color,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showResistancePopup(BuildContext context, DamageType type, int value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1D2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: type.color.withValues(alpha: 0.6)),
        ),
        title: Row(
          children: [
            Text(type.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              '${type.label} Resistance',
              style: TextStyle(
                color: type.color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reduces incoming ${type.label} damage by $value flat.\n\n'
              'Applied before other damage modifiers.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: type.color.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Enemy ${type.label} attack - $value resistance = Actual damage\n'
                'Minimum damage is always 1.',
                style: TextStyle(
                  color: type.color,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, List<_StatItem> stats) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: stats
          .map(
            (s) => GestureDetector(
              onTap: () => _showStatPopup(
                context,
                s.icon,
                s.label,
                s.value,
                s.color,
                s.title,
                s.description,
                s.formula,
              ),
              child: Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: s.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      s.value,
                      style: TextStyle(
                        color: s.color,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: s.color.withValues(alpha: 0.7),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN MENU BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _MainMenuSheet extends StatelessWidget {
  final Character player;
  final bool hasCloudSync;
  final bool hasSaveSlot;
  final Future<bool> Function()? onSave;
  final Future<bool> Function()? onSyncCloud;
  final VoidCallback onViewHelp;
  final VoidCallback onViewAbout;
  final VoidCallback onLoadSaveManager;
  final VoidCallback onQuitToTitle;
  final Function(String) onChangeScreen;

  const _MainMenuSheet({
    required this.player,
    required this.hasCloudSync,
    required this.hasSaveSlot,
    this.onSave,
    this.onSyncCloud,
    required this.onViewHelp,
    required this.onViewAbout,
    required this.onLoadSaveManager,
    required this.onQuitToTitle,
    required this.onChangeScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  GameImage(
                    imagePath: player.imagePath,
                    fallbackIcon: Icons.person,
                    size: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          player.className,
                          style: TextStyle(
                            color: GameColors.primary.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12, height: 1),

            // Menu items
            _buildMenuItem(
              context,
              icon: Icons.save_rounded,
              label: 'Save Game',
              subtitle: hasSaveSlot
                  ? 'Slot ${(hasSaveSlot) ? '— check' : '—'}'
                  : 'No slot',
              color: GameColors.success,
              onTap: () => _handleSave(context),
            ),
            if (hasCloudSync)
              _buildMenuItem(
                context,
                icon: Icons.cloud_upload_rounded,
                label: 'Cloud Sync',
                subtitle: 'Upload save to cloud',
                color: GameColors.accent,
                onTap: () => _handleSync(context),
              ),
            _buildMenuItem(
              context,
              icon: Icons.folder_open_rounded,
              label: 'Load / Save Manager',
              subtitle: 'Switch saves or start new game',
              color: GameColors.gold,
              onTap: onLoadSaveManager,
            ),
            _buildMenuItem(
              context,
              icon: Icons.inventory_2_rounded,
              label: 'Inventory',
              subtitle: 'Manage equipment and items',
              color: GameColors.accent,
              onTap: () {
                Navigator.pop(context);
                onChangeScreen('inventory');
              },
            ),

            const Divider(color: Colors.white12, height: 1),

            _buildMenuItem(
              context,
              icon: Icons.help_outline_rounded,
              label: 'How to Play',
              subtitle: 'Game tips and mechanics',
              color: Colors.white70,
              onTap: () {
                Navigator.pop(context);
                onViewHelp();
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.info_outline_rounded,
              label: 'About',
              subtitle: 'Flutter Ring v1.0.0',
              color: Colors.white70,
              onTap: () {
                Navigator.pop(context);
                onViewAbout();
              },
            ),

            const Divider(color: Colors.white12, height: 1),

            _buildMenuItem(
              context,
              icon: Icons.exit_to_app_rounded,
              label: 'Quit to Title',
              subtitle: 'Return to save manager',
              color: GameColors.danger,
              onTap: onQuitToTitle,
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave(BuildContext context) async {
    if (onSave == null) return;
    Navigator.pop(context);

    final scaffold = ScaffoldMessenger.of(context);
    final success = await onSave!();

    if (!context.mounted) return;

    if (success) {
      scaffold.showSnackBar(
        SnackBar(
          content: const Text('Game saved successfully'),
          backgroundColor: GameColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      scaffold.showSnackBar(
        SnackBar(
          content: const Text('Failed to save game'),
          backgroundColor: GameColors.danger,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleSync(BuildContext context) async {
    if (onSyncCloud == null) return;
    Navigator.pop(context);

    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(
        content: Text('Syncing to cloud...'),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await onSyncCloud!();

    if (!context.mounted) return;

    if (success) {
      scaffold.showSnackBar(
        SnackBar(
          content: const Text('Cloud sync complete'),
          backgroundColor: GameColors.success,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      scaffold.showSnackBar(
        SnackBar(
          content: const Text('Cloud sync failed'),
          backgroundColor: GameColors.danger,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

class _StatItem {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final String title;
  final String description;
  final String formula;

  const _StatItem(
    this.icon,
    this.label,
    this.value,
    this.color,
    this.title,
    this.description,
    this.formula,
  );
}
