import 'package:flutter/material.dart';
import '../models/restaurant_model.dart';
import '../services/api_service.dart';
import 'restaurant_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<RestaurantModel> _results = [];
  bool _isLoading = false;
  String _searchQuery = 'Burgers';
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'Filters',
    'Rating 4.5+',
    'Price: \$\$',
    'Delivery',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.text = _searchQuery;
    _performSearch();
  }

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Search restaurants via API
  /// Calls ApiService.searchRestaurants() which queries:
  /// SELECT r.* FROM Restaurant r
  /// LEFT JOIN RestaurantCategory rc ON r.id = rc.restaurant_id
  /// LEFT JOIN Category c ON rc.category_id = c.id
  /// WHERE r.name LIKE '%query%' OR c.name LIKE '%query%'
  /// -------------------------------------------------------
  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    try {
      final results = await ApiService.searchRestaurants(_searchQuery);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            _buildSearchField(),
            _buildFilterChips(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '32 Results for "$_searchQuery"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _results.length,
                      itemBuilder: (context, index) =>
                          _buildSearchResultCard(_results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'STEP-OUT',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search restaurants...',
              ),
              onSubmitted: (value) {
                setState(() => _searchQuery = value);
                _performSearch();
              },
            ),
          ),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _results = [];
              });
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: index == 0
                      ? const Color(0xFF2E7D32)
                      : (isSelected
                            ? const Color(0xFF2E7D32)
                            : Colors.grey[200]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (index == 0)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.tune, color: Colors.white, size: 16),
                      ),
                    Text(
                      _filters[index],
                      style: TextStyle(
                        color: index == 0 || isSelected
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResultCard(RestaurantModel restaurant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[300],
                    // TODO: [MySQL INTEGRATION] - Load image from URL
                    // child: Image.network(restaurant.imageUrl, fit: BoxFit.cover),
                    child: const Icon(
                      Icons.restaurant,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Tag badge
                if (restaurant.tags.isNotEmpty)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        restaurant.tags.first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                // Rating badge
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${restaurant.rating}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.categories.join(' • '),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      Text(
                        ' ${restaurant.deliveryTimeMin}-${restaurant.deliveryTimeMax} min',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.delivery_dining,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      Text(
                        restaurant.deliveryFee == 0
                            ? ' Free'
                            : ' \$${restaurant.deliveryFee.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      if (restaurant.priceLevel.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Text(
                          restaurant.priceLevel,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
