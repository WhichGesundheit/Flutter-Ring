import 'dart:math';
import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/enemy_pool.dart'; // Ensure this is imported!

class TravelScreen extends StatelessWidget {
  final int hoursPassed;
  final Function(String type, dynamic data) onChoiceSelected;
  final VoidCallback onCancel;

  const TravelScreen({
    super.key,
    required this.hoursPassed,
    required this.onChoiceSelected,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final int days = hoursPassed ~/ 24;
    final int hours = hoursPassed % 24;
    // Flag changes to true on Day 7 and onward (168 hours = 7 days)
    final bool isBossTime =
        (hoursPassed >= 144); // Start boss encounters on day 6

    return Scaffold(
      appBar: AppBar(title: const Text("Select Travel Path Vector")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isBossTime
                  ? "⚠️ CRITICAL LEVEL CONVERGENCE: ANOMALOUS OVERSEER ENGAGED"
                  : "Select path coordinates (Day $days, $hours:00 - Travel: 6h, Fight: 2h):",
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: isBossTime ? Colors.red : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (isBossTime) ...[
              Card(
                color: Colors.red[950],
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "APEX THREAT DETECTED",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "The layout matrix loop concludes here. Escape vectors are sealed. Survive the wipe sequence.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () {
                          // Dynamic Randomized Boss Selector Execution!
                          final randomBoss = EnemyPool.getRandomBossEnemy();
                          onChoiceSelected('Enemy', randomBoss);
                        },
                        child: const Text(
                          "COMMENCE APEX COMBAT",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.red[950],
                ),
                icon: const Icon(Icons.gavel, color: Colors.red),
                label: const Text(
                  "Threat Presence Detected",
                  style: TextStyle(fontSize: 15),
                ),
                onPressed: () {
                  final randomizedTarget = EnemyPool.getRandomStandardEnemy();
                  onChoiceSelected('Enemy', randomizedTarget);
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.blueGrey[900],
                ),
                icon: const Icon(Icons.store, color: Colors.amber),
                label: const Text(
                  "Wandering Outpost Supply",
                  style: TextStyle(fontSize: 15),
                ),
                onPressed: () {
                  final random = Random();
                  List<Item> pool = List.from(Item.shopLootPool);
                  pool.shuffle(random);
                  // Select 4-6 random items
                  int itemCount = 4 + random.nextInt(3);
                  List<Item> selection = pool.take(itemCount).toList();

                  // Add one random special sale (50% off)
                  int saleIdx = random.nextInt(selection.length);
                  Item original = selection[saleIdx];
                  selection[saleIdx] = Item(
                    id: '${original.id}_sale',
                    name: '${original.name} (SALE!)',
                    type: original.type,
                    description: original.description,
                    cost: (original.cost * 0.5).toInt(),
                    attackBonus: original.attackBonus,
                    damageReduction: original.damageReduction,
                    lifeSteal: original.lifeSteal,
                    thorns: original.thorns,
                    critChance: original.critChance,
                    healAmount: original.healAmount,
                    hpThreshold: original.hpThreshold,
                  );

                  onChoiceSelected('Shop', selection);
                },
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.grey[850],
                ),
                icon: const Icon(Icons.help_outline, color: Colors.green),
                label: const Text(
                  "Debris Extraction Point",
                  style: TextStyle(fontSize: 15),
                ),
                onPressed: () {
                  final random = Random();
                  final rolledItem = Item
                      .chestLootPool[random.nextInt(Item.chestLootPool.length)];
                  onChoiceSelected('Loot', rolledItem);
                },
              ),
            ],
            const Spacer(),
            if (!isBossTime)
              TextButton(
                onPressed: onCancel,
                child: const Text("Abstain & Maintain Perimeter"),
              ),
          ],
        ),
      ),
    );
  }
}
