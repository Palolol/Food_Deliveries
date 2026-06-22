/// ============================================================
/// MENU ITEM MODEL - Maps to the `MenuItem` table in MySQL
/// ============================================================
/// MySQL Table: MenuItem
/// Columns expected:
///   - id (INT, PRIMARY KEY, AUTO_INCREMENT)
///   - restaurant_id (INT, FOREIGN KEY -> Restaurant.id)
///   - name (VARCHAR)
///   - description (TEXT)
///   - price (DECIMAL)
///   - image_url (VARCHAR)
///   - category (VARCHAR) e.g., 'Promotions', 'Individual Meals'
///   - is_available (TINYINT/BOOLEAN)
///   - created_at (DATETIME)
/// ============================================================

class MenuItemModel {
  final int? id;
  final int? restaurantId;
  final String name;
  final String? description;
  final double price;
  final String imageUrl;
  final String? category;
  final bool isAvailable;
  final bool isPromotion;

  MenuItemModel({
    this.id,
    this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    required this.imageUrl,
    this.category,
    this.isAvailable = true,
    this.isPromotion = false,
  });

  /// TODO: [MySQL INTEGRATION] - Parse from API response
  /// JOIN with Restaurant table to get restaurant details
  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      category: json['category'],
      isAvailable: json['is_available'] == 1 || json['is_available'] == true,
      isPromotion: json['is_promotion'] == 1 || json['is_promotion'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'is_available': isAvailable ? 1 : 0,
      'is_promotion': isPromotion ? 1 : 0,
    };
  }
}
