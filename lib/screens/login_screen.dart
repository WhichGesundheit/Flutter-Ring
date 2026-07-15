import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/game_theme.dart';
import '../widgets/stylish_popup.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final VoidCallback onGuestPlay;

  const LoginScreen({
    super.key,
    required this.onAuthenticated,
    required this.onGuestPlay,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
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

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      if (kIsWeb) {
        // Web: use OAuth redirect
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          authScreenLaunchMode: LaunchMode.platformDefault,
        );
      } else {
        // Mobile: use native Google Sign-In
        // For now, use the same OAuth flow which works on all platforms
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      }

      if (!mounted) return;
      widget.onAuthenticated();
    } catch (e) {
      if (!mounted) return;
      showStylishPopup(
        context,
        title: 'AUTH FAILED',
        message: 'Google sign-in failed. Please try again.',
        icon: Icons.error_outline,
        iconColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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

              // ── Auth Buttons ──
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: GameColors.primary),
                )
              else ...[
                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _handleGoogleSignIn,
                    label: const Text(
                      "SIGN IN WITH GOOGLE",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Guest Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    icon: Icon(
                      Icons.person_outline,
                      size: 22,
                      color: GameColors.accent,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GameColors.accent,
                      side: BorderSide(
                        color: GameColors.accent.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.onGuestPlay,
                    label: const Text(
                      "PLAY AS GUEST",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Guest info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GameColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: GameColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[500],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Guest saves are stored locally. Sign in with Google to enable cloud sync.",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
