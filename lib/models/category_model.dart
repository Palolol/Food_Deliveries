/// ============================================================
/// CATEGORY MODEL - Maps to the `Category` table in MySQL
/// ============================================================
/// MySQL Table: Category
/// Columns expected:
///   - id (INT, PRIMARY KEY, AUTO_INCREMENT)
///   - name (VARCHAR)
///   - icon_url (VARCHAR)
///   - created_at (DATETIME)
/// ============================================================

class CategoryModel {
  final int? id;
  final String name;
  final String? iconUrl;
  final IconType iconType;

  CategoryModel({
    this.id,
    required this.name,
    this.iconUrl,
    this.iconType = IconType.burger,
  });

  /// TODO: [MySQL INTEGRATION] - Parse from API response
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      iconUrl: json['icon_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'icon_url': iconUrl};
  }
}

enum IconType { burger, pizza, soup, coffee, dessert, salad }
