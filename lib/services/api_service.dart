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
/// API SERVICE - Handles all HTTP requests to the backend
/// ============================================================
/// TODO: [MySQL INTEGRATION] - Configure your backend API base URL
/// This service communicates with your backend (e.g., Node.js, PHP, Python)
/// which in turn queries the MySQL database.
///
/// Replace the base URL with your actual backend server URL.
/// All methods currently return mock data for UI development.
/// Replace mock data with actual HTTP calls when backend is ready.
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

  bool    get isLoggedIn  => _token != null;
  int?    get userId      => _userId;
  String? get userName    => _userName;
  String? get userEmail   => _userEmail;

  static const _tokenKey     = 'auth_token';
  static const _userIdKey    = 'user_id';
  static const _userNameKey  = 'user_name';
  static const _userEmailKey = 'user_email';

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token     = prefs.getString(_tokenKey);
    _userId    = prefs.getInt(_userIdKey);
    _userName  = prefs.getString(_userNameKey);
    _userEmail = prefs.getString(_userEmailKey);
  }

  Future<void> _saveToken(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    _token     = data['access_token'] as String?;
    _userId    = data['user_id'] as int?;
    _userName  = data['full_name'] as String?;
    _userEmail = data['email'] as String?;
    if (_token     != null) await prefs.setString(_tokenKey, _token!);
    if (_userId    != null) await prefs.setInt(_userIdKey, _userId!);
    if (_userName  != null) await prefs.setString(_userNameKey, _userName!);
    if (_userEmail != null) await prefs.setString(_userEmailKey, _userEmail!);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    _token = _userName = _userEmail = null;
    _userId = null;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Auth REST calls (to FastAPI backend, best-effort) ─────────────────────
  Future<void> login({required String email, required String password}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));
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

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200 || res.statusCode == 201) {
        await _saveToken(jsonDecode(res.body) as Map<String, dynamic>);
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        throw ApiException(body['detail']?.toString() ?? 'Registration failed');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Backend unreachable: $e');
    }
  }

  // ======================= USER API =======================

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Fetch user profile
  /// Endpoint: GET /api/users/{userId}
  /// MySQL Query: SELECT * FROM User WHERE id = ?
  /// -------------------------------------------------------
  static Future<UserModel> getUserProfile(int userId) async {
    // TODO: Uncomment and use when backend is ready
    // final response = await http.get(
    //   Uri.parse('$baseUrl/users/$userId'),
    //   headers: _headers,
    // );
    // if (response.statusCode == 200) {
    //   return UserModel.fromJson(json.decode(response.body));
    // } else {
    //   throw Exception('Failed to load user profile');
    // }

    // Mock data for UI development
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

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Update user profile
  /// Endpoint: PUT /api/users/{userId}
  /// MySQL Query: UPDATE User SET name=?, email=?, phone=?, bio=?, ... WHERE id=?
  /// -------------------------------------------------------
  static Future<UserModel> updateUserProfile(UserModel user) async {
    // TODO: Uncomment and use when backend is ready
    // final response = await http.put(
    //   Uri.parse('$baseUrl/users/${user.id}'),
    //   headers: _headers,
    //   body: json.encode(user.toJson()),
    // );
    // if (response.statusCode == 200) {
    //   return UserModel.fromJson(json.decode(response.body));
    // } else {
    //   throw Exception('Failed to update user profile');
    // }

    // Mock - return updated user
    await Future.delayed(const Duration(milliseconds: 500));
    return user;
  }

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Upload user avatar
  /// Endpoint: POST /api/users/{userId}/avatar
  /// MySQL Query: UPDATE User SET avatar_url=? WHERE id=?
  /// Use multipart form data for file upload
  /// -------------------------------------------------------
  static Future<String> uploadAvatar(int userId, dynamic imageFile) async {
    // TODO: Implement file upload
    // var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/$userId/avatar'));
    // request.files.add(await http.MultipartFile.fromPath('avatar', imageFile.path));
    // request.headers.addAll(_headers);
    // var response = await request.send();
    // if (response.statusCode == 200) {
    //   var responseBody = await response.stream.bytesToString();
    //   return json.decode(responseBody)['avatar_url'];
    // }
    // throw Exception('Failed to upload avatar');

    await Future.delayed(const Duration(milliseconds: 500));
    return 'https://example.com/avatar.jpg';
  }

  // ======================= RESTAURANT API =======================

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Fetch all restaurants (home page)
  /// Endpoint: GET /api/restaurants
  /// MySQL Query: SELECT r.*, GROUP_CONCAT(c.name) as categories
  ///              FROM Restaurant r
  ///              LEFT JOIN RestaurantCategory rc ON r.id = rc.restaurant_id
  ///              LEFT JOIN Category c ON rc.category_id = c.id
  ///              GROUP BY r.id
  ///              ORDER BY r.rating DESC
  /// -------------------------------------------------------
  static Future<List<RestaurantModel>> getRestaurants() async {
    // TODO: Replace with actual API call
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

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Search restaurants
  /// Endpoint: GET /api/restaurants/search?q={query}&filters={filters}
  /// MySQL Query: SELECT r.* FROM Restaurant r
  ///              LEFT JOIN RestaurantCategory rc ON r.id = rc.restaurant_id
  ///              LEFT JOIN Category c ON rc.category_id = c.id
  ///              WHERE r.name LIKE ? OR c.name LIKE ?
  ///              AND r.rating >= ? (if filter applied)
  /// -------------------------------------------------------
  static Future<List<RestaurantModel>> searchRestaurants(
    String query, {
    double? minRating,
    String? priceLevel,
  }) async {
    // TODO: Replace with actual API call
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
      RestaurantModel(
        id: 6,
        name: 'Griller',
        imageUrl: 'assets/images/griller.jpg',
        rating: 4.9,
        deliveryTimeMin: 20,
        deliveryTimeMax: 30,
        deliveryFee: 1.20,
        categories: ['Rich', 'Flavor Full', 'Hard Bite'],
      ),
      RestaurantModel(
        id: 7,
        name: 'Diner 99',
        imageUrl: 'assets/images/diner_99.jpg',
        rating: 4.4,
        deliveryTimeMin: 30,
        deliveryTimeMax: 45,
        deliveryFee: 2.10,
        categories: ['Classic', 'Old Fashion', 'Fries'],
      ),
    ];
  }

  // ======================= CATEGORY API =======================

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Fetch categories
  /// Endpoint: GET /api/categories
  /// MySQL Query: SELECT * FROM Category ORDER BY name
  /// -------------------------------------------------------
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

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Fetch menu items for a restaurant
  /// Endpoint: GET /api/restaurants/{restaurantId}/menu
  /// MySQL Query: SELECT * FROM MenuItem WHERE restaurant_id = ?
  ///              ORDER BY category, name
  /// -------------------------------------------------------
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
      MenuItemModel(
        id: 5,
        restaurantId: restaurantId,
        name: 'Twill Twister',
        description: 'Two chicken strips, lettuce, tomatoes and potato ma...',
        price: 6.50,
        imageUrl: 'assets/images/twill_twister.jpg',
        category: 'Individual Meals',
      ),
      MenuItemModel(
        id: 6,
        restaurantId: restaurantId,
        name: '10pc Family Feast',
        description:
            '10 pieces of chicken, 2 large chips, 1 large potato & gravy, 1 large coleslaw and a 1.25L drink.',
        price: 32.00,
        imageUrl: 'assets/images/family_feast.jpg',
        category: 'Party/Family Buckets',
      ),
      MenuItemModel(
        id: 7,
        restaurantId: restaurantId,
        name: 'Party Pack',
        description:
            '15 pieces Original Recipe chicken, 30 chicken tenders, 50 nuggets and 1 mega chips, 1 mega chicken burger, 1 pepsi,...',
        price: 103.85,
        imageUrl: 'assets/images/party_pack.jpg',
        category: 'Party/Family Buckets',
      ),
    ];
  }

  // ======================= ORDER API =======================

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Create new order
  /// Endpoint: POST /api/orders
  /// MySQL Queries:
  ///   INSERT INTO `Order` (user_id, restaurant_id, subtotal, ...) VALUES (?, ?, ?, ...)
  ///   INSERT INTO OrderItem (order_id, menu_item_id, quantity, price) VALUES (?, ?, ?, ?)
  ///   UPDATE OrderStatus SET ... (or insert status record)
  /// -------------------------------------------------------
  static Future<OrderModel> createOrderFromModel(OrderModel order) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
    return order;
  }

  /// Instance createOrder used by CheckoutScreen — calls FastAPI backend.
  /// Falls back gracefully if backend is unreachable.
  Future<Map<String, dynamic>> createOrder({
    required int restaurantId,
    required List<Map<String, dynamic>> items,
    required String deliveryAddress,
    required String paymentMethod,
    String? specialNotes,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/orders/'),
        headers: _headers,
        body: jsonEncode({
          'restaurant_id': restaurantId,
          'items': items,
          'delivery_address': deliveryAddress,
          'payment_method': paymentMethod,
          if (specialNotes != null && specialNotes.isNotEmpty)
            'special_notes': specialNotes,
        }),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (_) {
      // Backend unavailable — caller uses fallback order ID
    }
    throw ApiException('Order API unavailable');
  }

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Fetch user orders
  /// Endpoint: GET /api/users/{userId}/orders
  /// MySQL Query: SELECT o.*, oi.*, mi.name, mi.image_url
  ///              FROM `Order` o
  ///              JOIN OrderItem oi ON o.id = oi.order_id
  ///              JOIN MenuItem mi ON oi.menu_item_id = mi.id
  ///              WHERE o.user_id = ?
  ///              ORDER BY o.created_at DESC
  /// -------------------------------------------------------
  static Future<List<OrderModel>> getUserOrders(int userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Apply promo code
  /// Endpoint: POST /api/orders/promo
  /// MySQL Query: SELECT * FROM PromoCode WHERE code = ? AND expiry_date > NOW()
  /// -------------------------------------------------------
  static Future<double> applyPromoCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 0.0; // Return discount amount
  }

  // ── Instance methods used by screens ─────────────────────────────────────

  /// Cancel an order (best-effort — screen proceeds even if API fails).
  Future<void> cancelOrder(String orderId) async {
    try {
      await http.patch(
        Uri.parse('${ApiService.baseUrl}/orders/$orderId/cancel'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Best-effort: local UI already reflects cancellation
    }
  }

  /// Fetch reviews for a restaurant. Returns raw JSON maps; caller converts.
  Future<List<Map<String, dynamic>>> getReviews(int restaurantId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/reviews/restaurant/$restaurantId'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(
          jsonDecode(res.body) as List,
        );
      }
    } catch (_) {
      // Backend unavailable — caller falls back to sample data
    }
    return [];
  }

  // ======================= REVIEW API =======================

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Submit a review
  /// Endpoint: POST /api/reviews
  /// MySQL Query: INSERT INTO Review (user_id, restaurant_id, rating, comment) VALUES (?, ?, ?, ?)
  /// Also update Restaurant.rating (recalculate average)
  /// -------------------------------------------------------
  static Future<ReviewModel> submitReview(ReviewModel review) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return review;
  }

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Mark review as helpful
  /// Endpoint: POST /api/reviews/{reviewId}/helpful
  /// MySQL Query: INSERT INTO ReviewHelpful (review_id, user_id) VALUES (?, ?)
  /// -------------------------------------------------------
  static Future<void> markReviewHelpful(int reviewId, int userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
