import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Load user profile from API
  /// Calls ApiService.getUserProfile() which queries:
  /// SELECT * FROM User WHERE id = ?
  /// Replace hardcoded userId (1) with actual logged-in user ID
  /// from authentication state/token
  /// -------------------------------------------------------
  Future<void> _loadUserProfile() async {
    try {
      /// TODO: Replace with actual user ID from auth state
      final user = await ApiService.getUserProfile(1);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // TODO: Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Profile Card
              _buildProfileCard(),

              // Join Premium Banner
              _buildPremiumBanner(),

              // Pack Cards
              _buildPackCards(),

              // Advantages Section
              _buildSectionTitle('Advantages'),
              _buildListItem(
                'Point',
                trailing: Text(
                  '${_user?.points ?? 0} Point >',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
              _buildListItem('Subscription'),
              _buildListItem('Reward'),
              _buildListItem('Challenges'),

              // General Section
              _buildSectionTitle('General'),
              _buildListItem('Favourites'),
              _buildListItem('Payment Methods'),
              _buildListItem('Settings'),
              _buildListItem('Privacy Settings'),
              _buildListItem('Languages'),
              _buildListItem('Saved Orders'),

              // Support Section
              _buildSectionTitle('Support'),
              _buildListItem('Help Center'),
              _buildListItem('Give us feedback'),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[200],

            /// -------------------------------------------------------
            /// TODO: [MySQL INTEGRATION] - Load user avatar
            /// If _user.avatarUrl is not null, use NetworkImage
            /// backgroundImage: _user?.avatarUrl != null
            ///     ? NetworkImage(_user!.avatarUrl!)
            ///     : null,
            /// -------------------------------------------------------
            child: _user?.avatarUrl == null
                ? Icon(Icons.person_outline, size: 30, color: Colors.grey[600])
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _user?.name ?? 'User',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Edit Button
          GestureDetector(
            onTap: () async {
              if (_user != null) {
                final updatedUser = await Navigator.push<UserModel>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: _user!),
                  ),
                );
                if (updatedUser != null) {
                  setState(() => _user = updatedUser);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Edit',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Text(
            'Join Step-Out Premium',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPackCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.family_restroom,
                    color: Colors.amber[800],
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family Pack',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'best experience for you and family.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business_center,
                    color: Colors.grey[800],
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Pack',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Get the best starter business pack.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildListItem(String title, {Widget? trailing}) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to respective screen
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 15)),
            trailing ??
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 22),
          ],
        ),
      ),
    );
  }
}
