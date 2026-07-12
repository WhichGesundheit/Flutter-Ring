import 'package:flutter/material.dart';
import '../models/character.dart';
import '../widgets/game_theme.dart';

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
    final int days = hoursPassed ~/ 24;
    final int hours = hoursPassed % 24;

    return Scaffold(
      backgroundColor: GameColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Status Icon ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isVictory ? GameColors.success : GameColors.danger)
                      .withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isVictory ? GameColors.success : GameColors.danger)
                              .withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  isVictory ? Icons.emoji_events : Icons.error_outline,
                  size: 60,
                  color: isVictory ? GameColors.success : GameColors.danger,
                ),
              ),
              const SizedBox(height: 24),

              // ── Title ──
              Text(
                isVictory
                    ? "DATA INTEGRITY SECURED"
                    : "RUN MATRIX DE-ALLOCATED",
                style: TextStyle(
                  fontSize: 24,
                  color: isVictory ? GameColors.success : GameColors.danger,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isVictory
                    ? "Loop Survived Successfully"
                    : (isTimeOut
                          ? "Time Expired: Ring Collapsed"
                          : "Expunged via Grid Defeat"),
                style: TextStyle(
                  color: isVictory ? GameColors.success : GameColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // ── Run Stats Card ──
              if (player != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GameColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: GameColors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        player!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        player!.className,
                        style: TextStyle(
                          color: GameColors.primary,
                          fontSize: 12,
                        ),
                      ),
                      const Divider(height: 20, color: GameColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            'TIME',
                            '$days d ${hours}h',
                            Icons.access_time,
                            GameColors.accent,
                          ),
                          _statItem(
                            'CREDITS',
                            '${player!.credits}',
                            Icons.monetization_on,
                            GameColors.gold,
                          ),
                          _statItem(
                            'HP LEFT',
                            '${player!.hp}/${player!.maxHp}',
                            Icons.favorite,
                            GameColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),

              // ── Restart Button ──
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GameColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: onRestart,
                  child: const Text(
                    "RE-INSTATIATE RUN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
