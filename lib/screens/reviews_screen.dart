import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/review.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReviewsScreen
// ─────────────────────────────────────────────────────────────────────────────

class ReviewsScreen extends StatefulWidget {
  final String restaurantName;
  final String restaurantId;
  final List<Review>? reviews;

  const ReviewsScreen({
    super.key,
    required this.restaurantName,
    this.restaurantId = '1',
    this.reviews,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<Review> _reviews;

  final _api = ApiService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reviews = widget.reviews ?? [];
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final data = await _api.getReviews(int.tryParse(widget.restaurantId) ?? 1);
      if (mounted) {
        setState(() {
          _reviews = data.map(Review.fromJson).toList();
        });
      }
    } catch (_) {
      // API unavailable, keep existing reviews
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold(0.0, (s, r) => s + r.rating) / _reviews.length;
  }

  void _addReview(Review r) =>
      setState(() => _reviews = [r, ..._reviews]);

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reviews & Ratings'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Reviews'),
            Tab(text: 'Write Review'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReviewsTab(
            reviews: _reviews,
            avgRating: _avgRating,
            onWriteReview: () => _tabController.animateTo(1),
          ),
          _WriteReviewTab(
            onSubmit: (review) {
              _addReview(review);
              _tabController.animateTo(0);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Review submitted!', style: GoogleFonts.poppins()),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReviewsTab
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  final List<Review> reviews;
  final double avgRating;
  final VoidCallback onWriteReview;

  const _ReviewsTab({
    required this.reviews,
    required this.avgRating,
    required this.onWriteReview,
  });

  // Count how many reviews per star level
  Map<int, int> get _starCounts {
    final map = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      final key = r.rating.round();
      if (map.containsKey(key)) map[key] = map[key]! + 1;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rating summary
        _RatingSummary(
          avgRating: avgRating,
          reviewCount: reviews.length,
          starCounts: _starCounts,
        ),
        const SizedBox(height: 16),

        // Write a Review button
        ElevatedButton.icon(
          onPressed: onWriteReview,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Write a Review'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),

        // Review cards
        if (reviews.isEmpty)
          Center(
            child: Column(children: [
              const SizedBox(height: 40),
              Icon(Icons.rate_review_outlined,
                  size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('No reviews yet',
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: AppColors.textSecondary)),
              Text('Be the first to review!',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.textHint)),
            ]),
          )
        else
          ...reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

// ── Rating Summary ────────────────────────────────────────────────────────────

class _RatingSummary extends StatelessWidget {
  final double avgRating;
  final int reviewCount;
  final Map<int, int> starCounts;

  const _RatingSummary({
    required this.avgRating,
    required this.reviewCount,
    required this.starCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Left: big number + stars
          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              avgRating.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            _StarRow(rating: avgRating, size: 22),
            const SizedBox(height: 4),
            Text(
              '$reviewCount review${reviewCount == 1 ? '' : 's'}',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ]),

          const SizedBox(width: 20),

          // Right: bar chart
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = starCounts[star] ?? 0;
                final ratio =
                    reviewCount > 0 ? count / reviewCount : 0.0;
                return _RatingBar(star: star, ratio: ratio, count: count);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final int star;
  final double ratio;
  final int count;

  const _RatingBar(
      {required this.star, required this.ratio, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Color(0xFFFFB300)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFFB300)),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 16,
            child: Text('$count',
                textAlign: TextAlign.right,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

// ── Review Card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatefulWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header: avatar, name, date, stars
        Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary,
              child: Text(r.authorInitial,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
            const SizedBox(width: 12),

            // Name + date
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.authorName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(r.timeAgo,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ]),
            ),

            // Stars
            _StarRow(rating: r.rating, size: 16),
          ],
        ),
        const SizedBox(height: 10),

        // Review text
        Text(r.text,
            style: GoogleFonts.poppins(fontSize: 13, height: 1.5)),
        const SizedBox(height: 12),

        // Helpful button
        GestureDetector(
          onTap: () {
            setState(() {
              if (r.isHelpful) {
                r.helpfulCount--;
                r.isHelpful = false;
              } else {
                r.helpfulCount++;
                r.isHelpful = true;
              }
            });
          },
          child: Row(
            children: [
              Icon(
                r.isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 16,
                color: r.isHelpful
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Helpful (${r.helpfulCount})',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: r.isHelpful
                        ? AppColors.primary
                        : AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WriteReviewTab
// ─────────────────────────────────────────────────────────────────────────────

class _WriteReviewTab extends StatefulWidget {
  final ValueChanged<Review> onSubmit;
  const _WriteReviewTab({required this.onSubmit});

  @override
  State<_WriteReviewTab> createState() => _WriteReviewTabState();
}

class _WriteReviewTabState extends State<_WriteReviewTab> {
  int _selectedRating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  static const int _maxChars = 500;

  static const _labels = [
    '',
    'Terrible',
    'Poor',
    'Good',
    'Very Good',
    'Excellent',
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a rating', style: GoogleFonts.poppins()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final review = Review(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'You',
      rating: _selectedRating.toDouble(),
      text: _reviewController.text.trim().isEmpty
          ? 'No written review.'
          : _reviewController.text.trim(),
      createdAt: DateTime.now(),
    );

    widget.onSubmit(review);

    setState(() {
      _selectedRating = 0;
      _reviewController.clear();
      _isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Rate section
        Text('Rate your experience',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Tap a star to rate',
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),

        // Star row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final starIndex = i + 1;
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  starIndex <= _selectedRating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 44,
                  color: starIndex <= _selectedRating
                      ? const Color(0xFFFFB300)
                      : Colors.grey[350],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Rating label
        Center(
          child: Text(
            _selectedRating == 0 ? 'Tap to rate' : _labels[_selectedRating],
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _selectedRating == 0
                  ? AppColors.textHint
                  : const Color(0xFFFFB300),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Review text section
        Text('Write your review',
            style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        TextField(
          controller: _reviewController,
          maxLines: 6,
          maxLength: _maxChars,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Share your experience...',
            counterText: '${_reviewController.text.length}/$_maxChars',
            counterStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        const SizedBox(height: 24),

        // Submit button
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text('Submit Review',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared: _StarRow
// ─────────────────────────────────────────────────────────────────────────────

class _StarRow extends StatelessWidget {
  final double rating;
  final double size;
  const _StarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1) <= rating;
        final half = !filled && (i + 0.5) < rating;
        return Icon(
          filled
              ? Icons.star_rounded
              : half
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: size,
          color: const Color(0xFFFFB300),
        );
      }),
    );
  }
}
