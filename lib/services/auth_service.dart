// ─────────────────────────────────────────────────────────────────────────────
// auth_service.dart  –  Firebase Auth (email / password) wrapper
//
// Handles:
//   • Sign-up    (createUserWithEmailAndPassword + displayName update)
//   • Sign-in    (signInWithEmailAndPassword)
//   • Sign-out
//   • Password reset email (sendPasswordResetEmail)
//   • Auth-state stream (used by AppState provider)
//   • Sync with ApiService for JWT-based REST calls (optional dual-auth)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_auth/firebase_auth.dart';
import 'api_service.dart';

/// Translates Firebase [FirebaseAuthException] codes into readable messages.
String _friendlyMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'No account found for that email address.';
    case 'wrong-password':
      return 'Incorrect password. Please try again.';
    case 'invalid-credential':
      return 'Invalid email or password. Please check and try again.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'too-many-requests':
      return 'Too many failed attempts. Please try again later.';
    case 'network-request-failed':
      return 'Network error. Please check your connection.';
    case 'user-disabled':
      return 'This account has been disabled.';
    default:
      return e.message ?? 'Authentication failed. Please try again.';
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _api = ApiService.instance;

  // ── Current user ───────────────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  // កែតម្រូវៈ តម្រូវការ Firebase និង RestAPI ដើម្បីចូលទៅកាន់
  bool get isLoggedIn => _auth.currentUser != null && _api.isLoggedIn;

  String? get userName => _auth.currentUser?.displayName ?? _api.userName;
  String? get userEmail => _auth.currentUser?.email ?? _api.userEmail;

  /// Stream of Firebase auth-state changes (null = signed out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Also log in to FastAPI backend for JWT (required for REST calls)
      try {
        await _api.login(email: email.trim(), password: password);
      } on ApiException catch (e) {
        // Surface the real backend error so it's debuggable
        throw AuthException('Backend login failed: ${e.message}');
      } catch (e) {
        throw AuthException('Backend unreachable: $e');
      }

      return cred;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign-in failed: $e');
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<UserCredential> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    UserCredential? cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Store display name in Firebase profile
      await cred.user?.updateDisplayName(fullName.trim());
      await cred.user?.reload();

      // Also register in FastAPI backend (required for REST calls).
      // If this fails, roll back the Firebase account so the user can retry
      // without hitting "email already in use".
      try {
        await _api.register(
          fullName: fullName.trim(),
          email: email.trim(),
          password: password,
        );
      } catch (e) {
        // Best-effort cleanup of the Firebase account
        try {
          await cred.user?.delete();
        } catch (_) {}
        // Re-throw with the real error so it's debuggable
        if (e is ApiException) {
          throw AuthException('Backend registration failed: ${e.message}');
        }
        throw AuthException('Backend unreachable: $e');
      }

      return cred;
    } on FirebaseAuthException catch (e) {
      // Roll back if Firebase created the user but a follow-up step failed
      try {
        await cred?.user?.delete();
      } catch (_) {}
      throw AuthException(_friendlyMessage(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Sign-up failed: $e');
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    await _api.logout();
  }
}

/// Thrown by [AuthService] methods with a user-friendly message.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
