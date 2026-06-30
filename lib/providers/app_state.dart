// ─────────────────────────────────────────────────────────────────────────────
// app_state.dart  –  ChangeNotifier for JWT-based auth state
//
// Firebase Auth has been removed.
// Auth state is now driven purely by the JWT token stored in ApiService.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// User roles matching the backend UserRole enum.
enum UserRole { admin, customer, restaurantOwner }

class AppState extends ChangeNotifier {
  final _api = ApiService.instance;

  AppState() {
    // Load persisted token on startup
    _api.loadToken().then((_) => notifyListeners());
  }

  // ── Public getters ─────────────────────────────────────────────────────────
  bool get isLoggedIn => _api.isLoggedIn;

  String get userName  => _api.userName  ?? 'Guest';
  String get userEmail => _api.userEmail ?? '';

  UserRole get userRole {
    switch (_api.userRole) {
      case 'admin':            return UserRole.admin;
      case 'restaurant_owner': return UserRole.restaurantOwner;
      default:                 return UserRole.customer;
    }
  }

  bool get isAdmin           => userRole == UserRole.admin;
  bool get isRestaurantOwner => userRole == UserRole.restaurantOwner;
  bool get isCustomer        => userRole == UserRole.customer;

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Called after a successful login so the UI updates immediately.
  void notifyLogin() => notifyListeners();

  /// Sign out: clear token + notify UI.
  Future<void> logout() async {
    await _api.logout();
    notifyListeners();
  }
}
