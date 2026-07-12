import 'package:flutter/material.dart';
import '../models/character.dart';
import '../widgets/game_theme.dart';

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
    final double timeFraction = hoursPassed / 168;
    final bool timeUrgent = hoursLeft <= 48;
    final bool timeCritical = hoursLeft <= 24;

    // Compute effective attack
    int effectiveAtk = player.baseAttack;

    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── TIME DISPLAY ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: timeCritical
                      ? GameColors.danger.withValues(alpha: 0.15)
                      : timeUrgent
                      ? GameColors.warning.withValues(alpha: 0.1)
                      : GameColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: timeCritical
                        ? GameColors.danger.withValues(alpha: 0.5)
                        : timeUrgent
                        ? GameColors.warning.withValues(alpha: 0.4)
                        : GameColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "DAY $days  ·  $hours:00",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: timeCritical
                                ? GameColors.danger
                                : Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: timeCritical
                                ? GameColors.danger.withValues(alpha: 0.2)
                                : timeUrgent
                                ? GameColors.warning.withValues(alpha: 0.2)
                                : GameColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${hoursLeft}h LEFT",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: timeCritical
                                  ? GameColors.danger
                                  : timeUrgent
                                  ? GameColors.warning
                                  : GameColors.accent,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GameProgressBar(
                      fraction: timeFraction,
                      color: timeCritical
                          ? GameColors.danger
                          : timeUrgent
                          ? GameColors.warning
                          : GameColors.accent,
                      height: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── PLAYER CARD ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: GameColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GameColors.border),
                ),
                child: Column(
                  children: [
                    // Character name and class
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      player.className,
                      style: TextStyle(
                        color: GameColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // HP Bar
                    HpBar(
                      current: player.hp,
                      max: player.maxHp,
                      height: 14,
                      showLabel: true,
                      showNumbers: true,
                    ),
                    const SizedBox(height: 12),

                    // Stat chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StatChip(
                          icon: Icons.flash_on,
                          label: '$effectiveAtk ATK',
                          color: GameColors.primary,
                        ),
                        const SizedBox(width: 8),
                        StatChip(
                          icon: Icons.monetization_on,
                          label: '${player.credits}c',
                          color: GameColors.gold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // ── ACTION BUTTONS ──
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: GameColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: GameColors.primary.withValues(alpha: 0.4),
                ),
                onPressed: () => onChangeScreen('travel'),
                child: const Text(
                  "SCOUT ADJACENT NODE",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  foregroundColor: GameColors.accent,
                  side: BorderSide(
                    color: GameColors.accent.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => onChangeScreen('inventory'),
                child: const Text(
                  "MATRIX CONFIGURATION",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
