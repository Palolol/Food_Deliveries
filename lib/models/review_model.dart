/// ============================================================
/// REVIEW MODEL - Maps to the `Review` table in MySQL
/// ============================================================
/// MySQL Table: Review
/// Columns expected:
///   - id (INT, PRIMARY KEY, AUTO_INCREMENT)
///   - user_id (INT, FOREIGN KEY -> User.id)
///   - restaurant_id (INT, FOREIGN KEY -> Restaurant.id)
///   - rating (DECIMAL)
///   - comment (TEXT)
///   - created_at (DATETIME)
///
/// MySQL Table: ReviewHelpful
/// Columns expected:
///   - id (INT, PRIMARY KEY, AUTO_INCREMENT)
///   - review_id (INT, FOREIGN KEY -> Review.id)
///   - user_id (INT, FOREIGN KEY -> User.id)
///   - created_at (DATETIME)
/// ============================================================

class ReviewModel {
  final int? id;
  final int? userId;
  final int? restaurantId;
  final double rating;
  final String? comment;
  final int helpfulCount;
  final DateTime? createdAt;

  ReviewModel({
    this.id,
    this.userId,
    this.restaurantId,
    required this.rating,
    this.comment,
    this.helpfulCount = 0,
    this.createdAt,
  });

  /// TODO: [MySQL INTEGRATION] - Parse from API response
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      userId: json['user_id'],
      restaurantId: json['restaurant_id'],
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      helpfulCount: json['helpful_count'] ?? 0,
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
      'rating': rating,
      'comment': comment,
    };
  }
}
