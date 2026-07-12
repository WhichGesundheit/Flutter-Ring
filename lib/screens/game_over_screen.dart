import 'package:flutter/material.dart';
import '../models/character.dart';

class GameOverScreen extends StatelessWidget {
  final Character? player;
  final int hoursPassed;
  final VoidCallback onRestart;

  const GameOverScreen({
    super.key,
    this.player,
    required this.hoursPassed,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTimeOut = hoursPassed >= 168;
    final bool isVictory = player != null && player!.hp > 0 && !isTimeOut;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isVictory
                    ? "DATA INTEGRITY SECURED"
                    : "RUN MATRIX DE-ALLOCATED",
                style: TextStyle(
                  fontSize: 28,
                  color: isVictory ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (player != null) ...[
                Text(
                  "Vessel Designation: ${player!.name} (${player!.className})",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text("Accumulated Assets: ${player!.gold} Credits"),
                const SizedBox(height: 5),
                Text(
                  isVictory
                      ? "Loop Survived Successfully"
                      : (isTimeOut
                            ? "Time Expired: Ring Collapsed"
                            : "Expunged via Grid Defeat"),
                  style: TextStyle(
                    color: isVictory ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 50),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                onPressed: onRestart,
                child: const Text("Re-instantiate Run Loop"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
