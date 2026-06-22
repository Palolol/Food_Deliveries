/// ============================================================
/// USER MODEL - Maps to the `User` table in MySQL database
/// ============================================================
/// MySQL Table: User
/// Columns expected:
///   - id (INT, PRIMARY KEY, AUTO_INCREMENT)
///   - name (VARCHAR)
///   - email (VARCHAR)
///   - phone (VARCHAR)
///   - avatar_url (VARCHAR)
///   - bio (TEXT)
///   - address (VARCHAR)
///   - is_premium (TINYINT/BOOLEAN)
///   - points (INT)
///   - created_at (DATETIME)
///   - updated_at (DATETIME)
/// ============================================================

class UserModel {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? bio;
  final String? address;
  final bool isPremium;
  final int points;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.bio,
    this.address,
    this.isPremium = false,
    this.points = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Parse JSON from API response
  /// Modify this factory to match your API response structure
  /// -------------------------------------------------------
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      address: json['address'],
      isPremium: json['is_premium'] == 1 || json['is_premium'] == true,
      points: json['points'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  /// -------------------------------------------------------
  /// TODO: [MySQL INTEGRATION] - Convert to JSON for API requests
  /// Modify this method to match your API request structure
  /// -------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'bio': bio,
      'address': address,
      'is_premium': isPremium ? 1 : 0,
      'points': points,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? address,
    bool? isPremium,
    int? points,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      isPremium: isPremium ?? this.isPremium,
      points: points ?? this.points,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
