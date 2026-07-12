import 'package:flutter/material.dart';
import '../models/character.dart';

class MainScreen extends StatelessWidget {
  final Character player;
  final int hoursPassed;
  final Function(String) onChangeScreen;

  const MainScreen({
    super.key,
    required this.player,
    required this.hoursPassed,
    required this.onChangeScreen,
  });

  @override
  Widget build(BuildContext context) {
    final int hoursLeft = 168 - hoursPassed;
    final int days = hoursPassed ~/ 24;
    final int hours = hoursPassed % 24;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.red[955],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "TIME: DAY $days, $hours:00\nCOLLAPSE IN: $hoursLeft HOURS",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Colors.grey[900],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        player.className,
                        style: TextStyle(color: Colors.red[400], fontSize: 14),
                      ),
                      const Divider(height: 20),
                      Text(
                        "HP: ${player.hp}/${player.maxHp}  |  Base Force: ${player.baseAttack} ATK  |  Credits: ${player.credits}",
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.red[900],
                ),
                onPressed: () => onChangeScreen('travel'),
                child: const Text(
                  "SCOUT ADJACENT NODE CHOICE",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () => onChangeScreen('inventory'),
                child: const Text("OPEN MATRIX CONFIGURATION"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
