import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// AUTH SERVICE – Google OAuth + Guest auth wrapper
/// ═══════════════════════════════════════════════════════════════════════════════

class AuthService {
  final SupabaseClient _supabase;
  late final GoogleSignIn _googleSignIn;

  AuthService({required SupabaseClient supabase}) : _supabase = supabase {
    _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  }

  /// Get current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is logged in (not guest)
  bool get isLoggedIn => currentUser != null;

  /// Check if user is a guest (no auth session)
  bool get isGuest => currentUser == null;

  /// Sign in with Google (mobile - native flow)
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('AuthService: Google sign-in was cancelled');
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('AuthService: No ID token received from Google');
        return null;
      }

      // Send the ID token to Supabase
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        debugPrint(
          'AuthService: Successfully signed in with Google as ${response.user!.email}',
        );
      }

      return response.user;
    } catch (e) {
      debugPrint('AuthService: Error signing in with Google: $e');
      return null;
    }
  }

  /// Sign in with Google (web/desktop - OAuth redirect)
  Future<void> signInWithGoogleOAuth() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.fluttermgring://login-callback/',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('AuthService: Error with Google OAuth: $e');
    }
  }

  /// Play as guest (no auth)
  /// Returns null - all saves will be local only
  User? playAsGuest() {
    debugPrint('AuthService: Playing as guest (local saves only)');
    return null;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      debugPrint('AuthService: Signed out successfully');
    } catch (e) {
      debugPrint('AuthService: Error signing out: $e');
    }
  }

  /// Listen for auth state changes
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  /// Get user display name
  String get userDisplayName {
    if (currentUser == null) return 'Guest';
    return currentUser!.userMetadata?['full_name'] as String? ??
        currentUser!.email ??
        'Player';
  }

  /// Get user email
  String? get userEmail => currentUser?.email;
}
