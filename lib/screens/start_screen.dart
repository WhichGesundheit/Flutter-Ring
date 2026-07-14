import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/stylish_popup.dart';
import '../widgets/game_theme.dart';

class StartScreen extends StatefulWidget {
  final VoidCallback onStart;
  const StartScreen({super.key, required this.onStart});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  bool _isAuthenticating = false;
  bool _showTutorial = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAnonymousLogin() async {
    setState(() => _isAuthenticating = true);
    try {
      final response = await Supabase.instance.client.auth.signInAnonymously();
      if (!mounted) return;
      if (response.user != null) {
        widget.onStart();
      }
    } catch (e) {
      if (!mounted) return;
      showStylishPopup(
        context,
        title: 'AUTH FAILED',
        message: 'Authentication failed. Please try again.',
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Title ──
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, child) {
                  return Opacity(
                    opacity: 0.7 + 0.3 * _pulseController.value,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    Icon(
                      Icons.hub_outlined,
                      size: 64,
                      color: GameColors.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "FLUTTER RING",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: GameColors.primary,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Endless optimization-grid rogue-engine.",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const Spacer(flex: 2),

              // ── Quick Tips ──
              if (!_showTutorial) ...[
                _tipRow(
                  Icons.all_inclusive,
                  "Endless run · Hyper boss every 7 days",
                  GameColors.accent,
                ),
                _tipRow(Icons.explore, "16 unique zones", GameColors.success),
                _tipRow(
                  Icons.shield,
                  "Equipment & loot system",
                  GameColors.gold,
                ),
                const Spacer(),
              ],

              // ── Tutorial Panel ──
              if (_showTutorial) ...[
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GameColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GameColors.border),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: GameColors.accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "HOW TO PLAY",
                                style: TextStyle(
                                  color: GameColors.accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _tutorialItem(
                            "⏱️",
                            "QUICK TIME",
                            "Travel costs 2h, exploring costs 2h (or 1h for an empty result), and fighting costs 1h. Manage your time carefully.",
                          ),
                          _tutorialItem(
                            "🗺️",
                            "ZONE TRAVEL",
                            "Move between connected zones on the node map. Each zone has unique enemies, shops, and events.",
                          ),
                          _tutorialItem(
                            "⚔️",
                            "COMBAT",
                            "Encounters are auto-battles. Your equipped items determine ATK, DEF, Crit, LifeSteal, and Thorns. Boss drops are guaranteed.",
                          ),
                          _tutorialItem(
                            "🛒",
                            "SHOPS",
                            "Settlement and traveling-merchant shops refresh their stock every 24h. Merchants relocate every 48h.",
                          ),
                          _tutorialItem(
                            "⚡",
                            "HYPER BOSS",
                            "Every 7 days (day 7, 14, 21, …) a HYPER version of that week's unique boss forces engagement. It is 2.5× stronger and drops a much more powerful legendary.",
                          ),
                          _tutorialItem(
                            "💀",
                            "DEATH = END",
                            "If your HP hits 0, the run ends. There is no day-limit — only the hyper-boss cycle continues.",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Buttons ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _isAuthenticating
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: GameColors.primary,
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GameColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: GameColors.primary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        onPressed: _handleAnonymousLogin,
                        child: const Text(
                          "BEGIN NEW RUN",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GameColors.accent,
                    side: BorderSide(
                      color: GameColors.accent.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () =>
                      setState(() => _showTutorial = !_showTutorial),
                  child: Text(
                    _showTutorial ? "CLOSE TUTORIAL" : "HOW TO PLAY",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tipRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tutorialItem(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: GameColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
