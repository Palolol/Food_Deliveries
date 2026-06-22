// review.dart — UI-facing Review model used by ReviewsScreen.
// Bridges ReviewModel (the DB/API model in review_model.dart) with the
// display-oriented fields the screen needs.

class Review {
  final String id;
  final String authorName;
  final double rating;
  final String text;
  final DateTime createdAt;
  int helpfulCount;
  bool isHelpful;

  Review({
    required this.id,
    required this.authorName,
    required this.rating,
    required this.text,
    required this.createdAt,
    this.helpfulCount = 0,
    this.isHelpful = false,
  });

  // ── Computed helpers ──────────────────────────────────────────────────────

  String get authorInitial =>
      authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()} yr ago';
    if (diff.inDays >= 30)  return '${(diff.inDays / 30).floor()} mo ago';
    if (diff.inDays >= 1)   return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    if (diff.inHours >= 1)  return '${diff.inHours} hr ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes} min ago';
    return 'Just now';
  }

  // ── Factory constructors ──────────────────────────────────────────────────

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      authorName: json['user_name']?.toString() ??
          json['author_name']?.toString() ??
          'Anonymous',
      rating: (json['rating'] ?? 0).toDouble(),
      text: json['comment']?.toString() ??
          json['text']?.toString() ??
          '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      helpfulCount: json['helpful_count'] as int? ?? 0,
    );
  }

  // ── Sample data for fallback / development ────────────────────────────────

  static List<Review> get sampleData => [
    Review(
      id: '1',
      authorName: 'Sarah M.',
      rating: 5,
      text: 'Absolutely amazing food! Arrived hot and fresh. Will definitely order again.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      helpfulCount: 12,
    ),
    Review(
      id: '2',
      authorName: 'James K.',
      rating: 4,
      text: 'Great flavors and generous portions. Delivery was a bit slow but food was worth the wait.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      helpfulCount: 7,
    ),
    Review(
      id: '3',
      authorName: 'Emily R.',
      rating: 5,
      text: 'Best burger I\'ve had in years! Perfectly cooked and seasoned.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      helpfulCount: 24,
    ),
    Review(
      id: '4',
      authorName: 'Michael T.',
      rating: 3,
      text: 'Food was decent but packaging could be improved. Some fries were soggy.',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      helpfulCount: 3,
    ),
    Review(
      id: '5',
      authorName: 'Lisa C.',
      rating: 5,
      text: 'Super fast delivery and everything was fresh! Highly recommend the special sauce.',
      createdAt: DateTime.now().subtract(const Duration(days: 21)),
      helpfulCount: 18,
    ),
  ];
}
