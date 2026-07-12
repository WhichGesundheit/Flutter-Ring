import 'dart:math';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/enemy_pool.dart';
import '../models/zone.dart';
import '../models/character.dart';

class TravelScreen extends StatelessWidget {
  final int hoursPassed;
  final ZoneType currentZone;
  final Character player;
  final Function(ZoneType target) onZoneTravel;
  final Function(String type, dynamic data, int cost) onAction;
  final VoidCallback onCancel;

  const TravelScreen({
    super.key,
    required this.hoursPassed,
    required this.currentZone,
    required this.player,
    required this.onZoneTravel,
    required this.onAction,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final zoneData = Zone.worldMap[currentZone]!;
    final int days = hoursPassed ~/ 24;
    final int hours = hoursPassed % 24;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(zoneData.name),
            Text(
              "Day $days, $hours:00",
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildZoneInfo(zoneData),
            const SizedBox(height: 24),
            const Text(
              "REGION NAVIGATION",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const Divider(),
            ...zoneData.connections.map((targetType) {
              final targetZone = Zone.worldMap[targetType]!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[900],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.map, size: 18),
                  label: Text("Travel to ${targetZone.name} (12h)"),
                  onPressed: () => onZoneTravel(targetType),
                ),
              );
            }),
            const SizedBox(height: 32),
            const Text(
              "LOCAL AREA EXPLORATION",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const Divider(),
            _buildContextualActions(context),
            const SizedBox(height: 40),
            TextButton(
              onPressed: onCancel,
              child: const Text("Return to Main Terminal"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneInfo(Zone zone) {
    return Card(
      color: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              zone.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextualActions(BuildContext context) {
    if (currentZone == ZoneType.town) {
      return Column(
        children: [
          _buildActionButton(
            icon: Icons.shutter_speed,
            label: "Blacksmith Supply Terminal",
            color: Colors.orange[900]!,
            onPressed: () {
              final random = Random();
              List<Item> pool = List.from(Item.shopLootPool);
              pool.shuffle(random);
              int itemCount = 4 + random.nextInt(3);
              List<Item> selection = pool.take(itemCount).toList();
              onAction('Shop', selection, 0);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.bed,
            label: "Rest at Data-Inn (10 Credits)",
            color: Colors.green[900]!,
            onPressed: player.credits >= 10
                ? () {
                    player.credits -= 10;
                    onAction('Heal', null, 0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("System Restored. HP Full."),
                      ),
                    );
                  }
                : null,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            label: "Talk to Local NPC",
            color: Colors.blue[900]!,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "'The binary brush is thicker than usual today...'",
                  ),
                ),
              );
            },
          ),
        ],
      );
    } else {
      // Forest or Deep Caves
      return _buildActionButton(
        icon: Icons.search,
        label: "Scout Deeper into Brush",
        color: Colors.red[900]!,
        onPressed: () {
          final random = Random();
          final roll = random.nextDouble();
          if (roll < 0.6) {
            // 60% Battle
            final enemy = EnemyPool.getRandomStandardEnemy();
            onAction('Enemy', enemy, 4); // Scouting takes 4 hours
          } else if (roll < 0.9) {
            // 30% Loot
            final loot =
                Item.chestLootPool[random.nextInt(Item.chestLootPool.length)];
            onAction('Loot', loot, 4);
          } else {
            // 10% Empty
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Area perimeter clear. No anomalies found."),
              ),
            );
            onAction('Empty', null, 2);
          }
        },
      );
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size.fromHeight(50),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}
