import 'package:flutter/material.dart';
import '../models/zone.dart';
import '../widgets/game_theme.dart';
import '../widgets/node_screen_widget.dart';

/// Full-screen portrait wrapper for NodeScreenWidget.
/// Provides an AppBar with back button and zone name.
class NodeScreen extends StatelessWidget {
  final ZoneType currentZone;
  final VoidCallback onScout;
  final VoidCallback onInventory;
  final VoidCallback? onBank;
  final VoidCallback? onWarehouse;
  final VoidCallback? onShop;
  final VoidCallback onBack;

  const NodeScreen({
    super.key,
    required this.currentZone,
    required this.onScout,
    required this.onInventory,
    this.onBank,
    this.onWarehouse,
    this.onShop,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final zoneData = Zone.worldMap[currentZone]!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: GameColors.surface,
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Back to Base',
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(zoneData.icon, color: zoneData.color, size: 18),
            const SizedBox(width: 8),
            Text(zoneData.name),
          ],
        ),
      ),
      body: NodeScreenWidget(
        currentZone: currentZone,
        onScout: onScout,
        onInventory: onInventory,
        onBank: onBank,
        onWarehouse: onWarehouse,
        onShop: onShop,
      ),
    );
  }
}
