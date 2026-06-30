import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/restaurant_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../models/category_model.dart';

/// ============================================================
/// API SERVICE - Handles all HTTP requests to the FastAPI backend
/// Single MSSQL database, JWT authentication.
/// ============================================================

/// Custom exception for API errors.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  ApiService._();
  static final ApiService instance = ApiService._();

  // ── Backend URL (auto-detects sandbox vs Android emulator) ─────────────────
  static String get baseUrl {
    if (kIsWeb) {
      final host = Uri.base.host;
      final backendHost = host.replaceFirst('5060-', '8000-');
      return 'https://$backendHost';
    }
    return 'http://10.0.2.2:8000'; // Android emulator → host machine
  }

  // ── JWT token state ────────────────────────────────────────────────────────
  String? _token;
  int?    _userId;
  String? _userName;
  String? _userEmail;
  String? _userRole;   // 'admin' | 'customer' | 'restaurant_owner'

  bool    get isLoggedIn  => _token != null;
  int?    get userId      => _userId;
  String? get userName    => _userName;
  String? get userEmail   => _userEmail;
  String? get userRole    => _userRole;

  static const _tokenKey     = 'auth_token';
  static const _userIdKey    = 'user_id';
  static const _userNameKey  = 'user_name';
  static const _userEmailKey = 'user_email';
  static const _userRoleKey  = 'user_role';

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token     = prefs.getString(_tokenKey);
    _userId    = prefs.getInt(_userIdKey);
    _userName  = prefs.getString(_userNameKey);
    _userEmail = prefs.getString(_userEmailKey);
    _userRole  = prefs.getString(_userRoleKey);
  }

  Future<void> _saveToken(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    _token     = data['access_token'] as String?;
    _userId    = data['user_id'] as int?;
    _userName  = data['full_name'] as String?;
    _userEmail = data['email'] as String?;
    _userRole  = data['role'] as String?;
    if (_token     != null) await prefs.setString(_tokenKey, _token!);
    if (_userId    != null) await prefs.setInt(_userIdKey, _userId!);
    if (_userName  != null) await prefs.setString(_userNameKey, _userName!);
    if (_userEmail != null) await prefs.setString(_userEmailKey, _userEmail!);
    if (_userRole  != null) await prefs.setString(_userRoleKey, _userRole!);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userRoleKey);
    _token = _userName = _userEmail = _userRole = null;
    _userId = null;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Auth REST calls ────────────────────────────────────────────────────────

  /// Login with email + password → stores JWT.
  Future<void> login({required String email, required String password}) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        await _saveToken(jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw ApiException(body['detail']?.toString() ?? 'Login failed');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Backend unreachable: $e');
    }
  }

  /// Register a new account (customer role by default).
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: register
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200 && res.statusCode != 201) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw ApiException(body['detail']?.toString() ?? 'Registration failed');
      }
      // Step 2: auto-login after register
      await login(email: email, password: password);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Registration failed: $e');
    }
  }

  // ======================= USER API =======================

  static Future<UserModel> getUserProfile(int userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return UserModel(
      id: 1,
      name: 'Harry Style',
      email: 'harry.style@email.com',
      phone: '+1 234 567 8900',
      bio: 'Food enthusiast | Love trying new restaurants',
      address: 'Road 6A, Khan Ruseykeo, Phnom Penh',
      isPremium: false,
      points: 25,
    );
  }

  static Future<UserModel> updateUserProfile(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return user;
  }

  static Future<String> uploadAvatar(int userId, dynamic imageFile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://example.com/avatar.jpg';
  }

  // ======================= RESTAURANT API =======================

  static Future<List<RestaurantModel>> getRestaurants() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      RestaurantModel(
        id: 1,
        name: 'KFC - Kentucky Fried Chicken',
        imageUrl: 'assets/images/kfc.jpg',
        rating: 4.5,
        reviewCount: 1200,
        deliveryTimeMin: 15,
        deliveryTimeMax: 25,
        deliveryFee: 1.99,
        priceLevel: '\$\$',
        categories: ['Chicken', 'Fast Food', 'American'],
        isOpen: true,
        openUntil: '11:00 PM',
      ),
      RestaurantModel(
        id: 2,
        name: 'Starbucks Coffee',
        imageUrl: 'assets/images/starbucks.jpg',
        rating: 3.5,
        reviewCount: 8400,
        deliveryTimeMin: 10,
        deliveryTimeMax: 15,
        deliveryFee: 1.20,
        categories: ['Coffee', 'Bakery', 'Beverages'],
      ),
      RestaurantModel(
        id: 3,
        name: 'Burger King',
        imageUrl: 'assets/images/burger_king.jpg',
        rating: 3.8,
        reviewCount: 1200,
        deliveryTimeMin: 30,
        deliveryTimeMax: 40,
        deliveryFee: 2.99,
        categories: ['Burgers', 'Grills', 'Fast Food'],
      ),
    ];
  }

  static Future<List<RestaurantModel>> searchRestaurants(
    String query, {
    double? minRating,
    String? priceLevel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      RestaurantModel(
        id: 4,
        name: 'Iron Grind Burgers',
        imageUrl: 'assets/images/iron_grind.jpg',
        rating: 4.8,
        deliveryTimeMin: 15,
        deliveryTimeMax: 25,
        deliveryFee: 0,
        priceLevel: '\$\$',
        categories: ['American', 'Burgers', 'BBQ'],
        tags: ['Fastest Delivery'],
      ),
      RestaurantModel(
        id: 5,
        name: 'The Burger Lab',
        imageUrl: 'assets/images/burger_lab.jpg',
        rating: 4.6,
        deliveryTimeMin: 25,
        deliveryTimeMax: 35,
        deliveryFee: 1.99,
        categories: ['Fusion', 'Burgers', 'Truffle'],
      ),
    ];
  }

  // ======================= CATEGORY API =======================

  static Future<List<CategoryModel>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      CategoryModel(id: 1, name: 'Burgers', iconType: IconType.burger),
      CategoryModel(id: 2, name: 'Pizza', iconType: IconType.pizza),
      CategoryModel(id: 3, name: 'Soup', iconType: IconType.soup),
      CategoryModel(id: 4, name: 'Coffee', iconType: IconType.coffee),
    ];
  }

  // ======================= MENU ITEM API =======================

  static Future<List<MenuItemModel>> getMenuItems(int restaurantId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      MenuItemModel(
        id: 1,
        restaurantId: restaurantId,
        name: 'Zinger Crunch Box',
        description: 'Zinger burger, 1pc chicken, chips, potato &...',
        price: 13.55,
        imageUrl: 'assets/images/zinger_crunch.jpg',
        category: 'Promotions',
        isPromotion: true,
      ),
      MenuItemModel(
        id: 2,
        restaurantId: restaurantId,
        name: 'ALL STAR BOXES',
        description: '2 Original Recipe burger, chicken, chips, potato &...',
        price: 25.99,
        imageUrl: 'assets/images/all_star.jpg',
        category: 'Promotions',
        isPromotion: true,
      ),
      MenuItemModel(
        id: 3,
        restaurantId: restaurantId,
        name: 'Classic Zinger Burger',
        description: 'Spicy breaded chicken breast, lettuce, and mayo.',
        price: 7.45,
        imageUrl: 'assets/images/zinger_burger.jpg',
        category: 'Individual Meals',
      ),
      MenuItemModel(
        id: 4,
        restaurantId: restaurantId,
        name: '3pc Original Recipe',
        description:
            'Three pieces of secret recipe chicken cooked to perfection.',
        price: 6.89,
        imageUrl: 'assets/images/original_recipe.jpg',
        category: 'Individual Meals',
      ),
    ];
  }

  // ======================= ORDER API =======================

  /// Instance method — calls FastAPI backend to create an order.
  Future<Map<String, dynamic>> createOrder({
    required int restaurantId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String paymentMethod,
    String? specialNotes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/v1/orders'),
        headers: _headers,
        body: jsonEncode({
          'restaurant_id': restaurantId,
          'items': items,
          'delivery_address': deliveryAddress,
          'payment_method': paymentMethod,
          if (specialNotes != null && specialNotes.isNotEmpty)
            'notes': specialNotes,
        }),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Backend unavailable — caller uses fallback order ID
    }
    throw const ApiException('Order API unavailable');
  }

  /// Rename of old static method — kept for any legacy callers.
  static Future<OrderModel> createOrderFromModel(OrderModel order) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return order;
  }

  static Future<List<OrderModel>> getUserOrders(int userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  static Future<double> applyPromoCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 0.0;
  }

  // ─── Instance methods used by screens ──────────────────────────────────────

  /// Cancel an order (best-effort).
  Future<void> cancelOrder(String orderId) async {
    try {
      await http.patch(
        Uri.parse('${ApiService.baseUrl}/api/v1/orders/$orderId/status'),
        headers: _headers,
        body: jsonEncode({'status': 'cancelled'}),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Best-effort
    }
  }

  /// Fetch reviews for a restaurant.
  Future<List<Map<String, dynamic>>> getReviews(int restaurantId) async {
    try {
      final res = await http.get(
        Uri.parse(
            '${ApiService.baseUrl}/api/v1/reviews/restaurant/$restaurantId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          jsonDecode(res.body) as List,
        );
      }
    } catch (_) {
      // Backend unavailable
    }
    return [];
  }

  // ======================= REVIEW API =======================

  static Future<ReviewModel> submitReview(ReviewModel review) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return review;
  }

  static Future<void> markReviewHelpful(int reviewId, int userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
