// ─────────────────────────────────────────────────────────────────────────────
// auth_service.dart  –  Pure API-based authentication (Firebase removed)
//
// All auth calls go to the FastAPI backend which issues JWT tokens.
// Passwords are hashed server-side with bcrypt.
// ─────────────────────────────────────────────────────────────────────────────

import 'api_service.dart';

class AuthService {
  final _api = ApiService.instance;

  // ── Current user ───────────────────────────────────────────────────────────
  bool    get isLoggedIn => _api.isLoggedIn;
  String? get userName   => _api.userName;
  String? get userEmail  => _api.userEmail;
  String? get userRole   => _api.userRole;

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _api.login(email: email.trim(), password: password);
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Sign-in failed: $e');
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      await _api.register(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
      );
    } on ApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('Sign-up failed: $e');
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
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
