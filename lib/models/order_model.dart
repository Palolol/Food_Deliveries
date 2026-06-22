/// ============================================================
/// ORDER MODEL - Maps to the `Order` table in MySQL
/// ============================================================
/// MySQL Table: Order
/// Columns expected:
///   - id (INT, PRIMARY KEY, AUTO_INCREMENT)
///   - user_id (INT, FOREIGN KEY -> User.id)
///   - restaurant_id (INT, FOREIGN KEY -> Restaurant.id)
///   - subtotal (DECIMAL)
///   - delivery_fee (DECIMAL)
///   - total (DECIMAL)
///   - promo_code (VARCHAR)
///   - delivery_address (TEXT)
///   - delivery_instructions (TEXT)
///   - payment_method (VARCHAR)
///   - status (VARCHAR) - references OrderStatus table
///   - created_at (DATETIME)
///   - updated_at (DATETIME)
///
/// MySQL Table: OrderItem
/// Columns expected:
///   - id (INT, PRIMARY KEY, AUTO_INCREMENT)
///   - order_id (INT, FOREIGN KEY -> Order.id)
///   - menu_item_id (INT, FOREIGN KEY -> MenuItem.id)
///   - quantity (INT)
///   - price (DECIMAL)
///   - special_instructions (TEXT)
///
/// MySQL Table: OrderStatus
/// Columns expected:
///   - id (INT, PRIMARY KEY, AUTO_INCREMENT)
///   - name (VARCHAR) e.g., 'pending', 'confirmed', 'preparing', etc.
///   - description (TEXT)
/// ============================================================

class OrderModel {
  final int? id;
  final int? userId;
  final int? restaurantId;
  final String? restaurantName;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String? promoCode;
  final String? deliveryAddress;
  final String? deliveryInstructions;
  final String paymentMethod;
  final String status;
  final List<OrderItemModel> items;
  final DateTime? createdAt;

  OrderModel({
    this.id,
    this.userId,
    this.restaurantId,
    this.restaurantName,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.promoCode,
    this.deliveryAddress,
    this.deliveryInstructions,
    this.paymentMethod = 'Cash',
    this.status = 'pending',
    this.items = const [],
    this.createdAt,
  });

  /// TODO: [MySQL INTEGRATION] - Parse from API response
  /// JOIN with OrderItem, MenuItem, Restaurant, OrderStatus tables
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      restaurantId: json['restaurant_id'],
      restaurantName: json['restaurant_name'],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['delivery_fee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      promoCode: json['promo_code'],
      deliveryAddress: json['delivery_address'],
      deliveryInstructions: json['delivery_instructions'],
      paymentMethod: json['payment_method'] ?? 'Cash',
      status: json['status'] ?? 'pending',
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => OrderItemModel.fromJson(item))
                .toList()
          : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'restaurant_id': restaurantId,
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'total': total,
      'promo_code': promoCode,
      'delivery_address': deliveryAddress,
      'delivery_instructions': deliveryInstructions,
      'payment_method': paymentMethod,
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class OrderItemModel {
  final int? id;
  final int? orderId;
  final int? menuItemId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int quantity;
  final double price;
  final String? specialInstructions;

  OrderItemModel({
    this.id,
    this.orderId,
    this.menuItemId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.quantity,
    required this.price,
    this.specialInstructions,
  });

  /// TODO: [MySQL INTEGRATION] - Parse from API response
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      orderId: json['order_id'],
      menuItemId: json['menu_item_id'],
      name: json['name'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      specialInstructions: json['special_instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'quantity': quantity,
      'price': price,
      'special_instructions': specialInstructions,
    };
  }
}
