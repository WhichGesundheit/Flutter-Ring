import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/stylish_popup.dart';

class StartScreen extends StatefulWidget {
  final VoidCallback onStart;
  const StartScreen({super.key, required this.onStart});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  bool _isAuthenticating = false;

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "FLUTTER RING",
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.red[955],
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Build optimization grid rogue-engine.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 50),
            _isAuthenticating
                ? const CircularProgressIndicator(color: Colors.red)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[900],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    onPressed: _handleAnonymousLogin,
                    child: const Text(
                      "BEGIN NEW RUN",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
