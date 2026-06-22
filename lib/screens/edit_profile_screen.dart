import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// ============================================================
/// EDIT PROFILE SCREEN
/// ============================================================
/// This screen allows users to edit their personal information.
/// All fields map to columns in the MySQL `User` table.
///
/// MySQL Table: User
/// Editable columns:
///   - name (VARCHAR)
///   - email (VARCHAR)
///   - phone (VARCHAR)
///   - bio (TEXT)
///   - address (VARCHAR)
///   - avatar_url (VARCHAR) - updated via file upload
/// ============================================================

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _addressController;
  bool _isSaving = false;
  bool _hasChanges = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();

    /// -------------------------------------------------------
    /// Initialize controllers with data from MySQL User table
    /// These values came from: SELECT * FROM User WHERE id = ?
    /// -------------------------------------------------------
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _avatarUrl = widget.user.avatarUrl;

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Save profile changes to database
  /// Calls ApiService.updateUserProfile() which sends PUT request
  /// Backend executes: UPDATE User SET name=?, email=?, phone=?,
  ///                   bio=?, address=? WHERE id=?
  /// -------------------------------------------------------
  Future<void> _saveProfile() async {
    if (!_hasChanges) return;

    setState(() => _isSaving = true);

    try {
      final updatedUser = widget.user.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        address: _addressController.text.trim(),
        avatarUrl: _avatarUrl,
      );

      /// -------------------------------------------------------
      /// TODO: [MySQL INTEGRATION] - API call to update user
      /// This sends a PUT/PATCH request to your backend:
      /// PUT /api/users/{userId}
      /// Body: { name, email, phone, bio, address }
      /// Backend SQL: UPDATE User SET ... WHERE id = ?
      /// -------------------------------------------------------
      final savedUser = await ApiService.updateUserProfile(updatedUser);

      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, savedUser);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Handle avatar change
  /// 1. Pick image using image_picker package
  /// 2. Upload to server via ApiService.uploadAvatar()
  /// 3. Backend saves file and returns URL
  /// 4. Backend updates User.avatar_url in MySQL
  /// -------------------------------------------------------
  Future<void> _changeAvatar() async {
    // TODO: Implement image picker
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   final avatarUrl = await ApiService.uploadAvatar(widget.user.id!, image);
    //   setState(() {
    //     _avatarUrl = avatarUrl;
    //     _hasChanges = true;
    //   });
    // }

    // For now, show a bottom sheet with options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Profile Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                // TODO: [MySQL INTEGRATION] - Capture and upload photo
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF2E7D32),
                child: Icon(Icons.photo_library, color: Colors.white),
              ),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                // TODO: [MySQL INTEGRATION] - Pick from gallery and upload
              },
            ),
            if (_avatarUrl != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _avatarUrl = null;
                    _hasChanges = true;
                  });
                  // TODO: [MySQL INTEGRATION] - Delete avatar
                  // UPDATE User SET avatar_url = NULL WHERE id = ?
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_hasChanges) {
              _showDiscardDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _hasChanges && !_isSaving ? _saveProfile : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: _hasChanges ? const Color(0xFF2E7D32) : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar Section
                  _buildAvatarSection(),
                  const SizedBox(height: 30),

                  // Editable Fields
                  /// -------------------------------------------------------
                  /// Each field maps to a column in MySQL User table
                  /// -------------------------------------------------------

                  /// MySQL Column: User.name (VARCHAR)
                  _buildEditField(
                    label: 'Full Name',
                    controller: _nameController,
                    icon: Icons.person_outline,
                    hint: 'Enter your full name',
                  ),

                  /// MySQL Column: User.email (VARCHAR)
                  _buildEditField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: 'Enter your email address',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  /// MySQL Column: User.phone (VARCHAR)
                  _buildEditField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hint: 'Enter your phone number',
                    keyboardType: TextInputType.phone,
                  ),

                  /// MySQL Column: User.bio (TEXT)
                  _buildEditField(
                    label: 'Bio',
                    controller: _bioController,
                    icon: Icons.info_outline,
                    hint: 'Tell us about yourself',
                    maxLines: 3,
                  ),

                  /// MySQL Column: User.address (VARCHAR)
                  _buildEditField(
                    label: 'Address',
                    controller: _addressController,
                    icon: Icons.location_on_outlined,
                    hint: 'Enter your address',
                    maxLines: 2,
                  ),

                  const SizedBox(height: 20),

                  // Delete Account Button
                  _buildDeleteAccountButton(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.grey[200],

            /// -------------------------------------------------------
            /// TODO: [MySQL INTEGRATION] - Display user avatar from URL
            /// MySQL Column: User.avatar_url
            /// backgroundImage: _avatarUrl != null
            ///     ? NetworkImage(_avatarUrl!)
            ///     : null,
            /// -------------------------------------------------------
            child: _avatarUrl == null
                ? Icon(Icons.person, size: 55, color: Colors.grey[400])
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _changeAvatar,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: Colors.grey[500], size: 22),
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          /// -------------------------------------------------------
          /// TODO: [MySQL INTEGRATION] - Delete user account
          /// Endpoint: DELETE /api/users/{userId}
          /// MySQL Query: DELETE FROM User WHERE id = ?
          /// Also cascade delete related records:
          ///   - DELETE FROM `Order` WHERE user_id = ?
          ///   - DELETE FROM Review WHERE user_id = ?
          ///   - DELETE FROM ReviewHelpful WHERE user_id = ?
          /// -------------------------------------------------------
          _showDeleteAccountDialog();
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'Delete Account',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to go back?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data, orders, and reviews will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              /// TODO: [MySQL INTEGRATION] - Call delete account API
              /// DELETE /api/users/{userId}
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
