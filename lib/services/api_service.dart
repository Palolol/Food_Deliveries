import 'dart:convert';
// import 'package:http/http.dart' as http; // TODO: Uncomment when connecting to backend

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

class ApiService {
  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Set your backend API base URL
  /// Example: 'http://localhost:3000/api' or 'https://your-server.com/api'
  /// -------------------------------------------------------
  static const String baseUrl = 'http://localhost:3000/api';

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Add authentication token
  /// Store and retrieve auth token from secure storage
  /// -------------------------------------------------------
  static String? _authToken;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

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
  static Future<OrderModel> createOrder(OrderModel order) async {
    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));
    return order;
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
