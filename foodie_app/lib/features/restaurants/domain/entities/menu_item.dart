import '../../../../core/utils/food_image_helper.dart';

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final int pricePaise;
  final String imageUrl;
  final bool isVeg;
  final String category;
  final bool isAvailable;
  final DateTime createdAt;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.pricePaise,
    required this.imageUrl,
    required this.isVeg,
    required this.category,
    required this.isAvailable,
    required this.createdAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String;
    final rawCategory = json['category'] as String;
    final rawImage = json['image_url'] as String?;
    final imageUrl = FoodImageHelper.getItemImage(rawName, rawCategory, rawImage);

    return MenuItem(
      id: json['id'] as String,
      restaurantId: json['restaurant_id'] as String,
      name: rawName,
      description: json['description'] as String? ?? '',
      pricePaise: json['price_paise'] as int,
      imageUrl: imageUrl,
      isVeg: json['is_veg'] as bool,
      category: rawCategory,
      isAvailable: json['is_available'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      'price_paise': pricePaise,
      'image_url': imageUrl,
      'is_veg': isVeg,
      'category': category,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
