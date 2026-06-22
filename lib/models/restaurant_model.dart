/// ============================================================
/// RESTAURANT MODEL - Maps to the `Restaurant` table in MySQL
/// ============================================================
/// MySQL Table: Restaurant
/// Columns expected:
///   - id (INT, PRIMARY KEY, AUTO_INCREMENT)
///   - name (VARCHAR)
///   - description (TEXT)
///   - image_url (VARCHAR)
///   - rating (DECIMAL)
///   - review_count (INT)
///   - delivery_time_min (INT)
///   - delivery_time_max (INT)
///   - delivery_fee (DECIMAL)
///   - price_level (VARCHAR) e.g., '$', '$$', '$$$'
///   - address (VARCHAR)
///   - is_open (TINYINT/BOOLEAN)
///   - open_until (TIME)
///   - created_at (DATETIME)
///
/// Related Tables:
///   - RestaurantCategory (restaurant_id, category_id)
///   - RestaurantTag (restaurant_id, tag_name)
/// ============================================================

class RestaurantModel {
  final int? id;
  final String name;
  final String? description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final int deliveryTimeMin;
  final int deliveryTimeMax;
  final double deliveryFee;
  final String priceLevel;
  final String? address;
  final bool isOpen;
  final String? openUntil;
  final List<String> categories;
  final List<String> tags;

  RestaurantModel({
    this.id,
    required this.name,
    this.description,
    required this.imageUrl,
    required this.rating,
    this.reviewCount = 0,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    required this.deliveryFee,
    this.priceLevel = '\$',
    this.address,
    this.isOpen = true,
    this.openUntil,
    this.categories = const [],
    this.tags = const [],
  });

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Parse JSON from API response
  /// Modify field names to match your backend API
  /// JOIN with RestaurantCategory and Category tables for categories
  /// JOIN with RestaurantTag table for tags
  /// -------------------------------------------------------
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      deliveryTimeMin: json['delivery_time_min'] ?? 0,
      deliveryTimeMax: json['delivery_time_max'] ?? 0,
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      priceLevel: json['price_level'] ?? '\$',
      address: json['address'],
      isOpen: json['is_open'] == 1 || json['is_open'] == true,
      openUntil: json['open_until'],
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'rating': rating,
      'review_count': reviewCount,
      'delivery_time_min': deliveryTimeMin,
      'delivery_time_max': deliveryTimeMax,
      'delivery_fee': deliveryFee,
      'price_level': priceLevel,
      'address': address,
      'is_open': isOpen ? 1 : 0,
      'open_until': openUntil,
      'categories': categories,
      'tags': tags,
    };
  }
}
