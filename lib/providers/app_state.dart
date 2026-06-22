// ─────────────────────────────────────────────────────────────────────────────
// app_state.dart  –  ChangeNotifier that mirrors Firebase auth state
//
// Listens to FirebaseAuth.authStateChanges() so the UI reacts automatically
// whenever the user signs in or out (including token refresh / expiry).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _fbAuth = FirebaseAuth.instance;
  final _api = ApiService.instance;

  late final StreamSubscription<User?> _authSub;

  User? _firebaseUser;

  AppState() {
    // Seed with the current user (in case app was already logged in)
    _firebaseUser = _fbAuth.currentUser;

    // Subscribe to future auth changes
    _authSub = _fbAuth.authStateChanges().listen((user) {
      _firebaseUser = user;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // ── Public getters ─────────────────────────────────────────────────────────
  bool    get isLoggedIn => _firebaseUser != null;
  User?   get firebaseUser => _firebaseUser;

  /// Display name: prefer Firebase profile, fall back to REST API name.
  String  get userName  =>
      _firebaseUser?.displayName?.isNotEmpty == true
          ? _firebaseUser!.displayName!
          : (_api.userName ?? 'Guest');

  String  get userEmail =>
      _firebaseUser?.email ?? _api.userEmail ?? '';

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Called after a successful Firebase sign-in / sign-up so the UI updates
  /// immediately without waiting for the stream event.
  void notifyLogin() => notifyListeners();

  /// Signs out of Firebase + clears REST API token.
  Future<void> logout() async {
    await _fbAuth.signOut();
    await _api.logout();
    // notifyListeners() will be called automatically by the auth stream
  }
}
