import '../../../../core/utils/food_image_helper.dart';

class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String imageUrl;
  final double rating;
  final int deliveryTimeMin;
  final int deliveryFeePaise;
  final double lat;
  final double lng;
  final bool isOpen;
  final DateTime createdAt;

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTimeMin,
    required this.deliveryFeePaise,
    required this.lat,
    required this.lng,
    required this.isOpen,
    required this.createdAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'] as String;
    final rawCuisine = json['cuisine'] as String;
    final rawImage = json['image_url'] as String?;
    final imageUrl = FoodImageHelper.getRestaurantImage(rawName, rawCuisine, rawImage);

    return Restaurant(
      id: json['id'] as String,
      name: rawName,
      cuisine: rawCuisine,
      imageUrl: imageUrl,
      rating: double.parse(json['rating'].toString()),
      deliveryTimeMin: json['delivery_time_min'] as int,
      deliveryFeePaise: json['delivery_fee_paise'] as int,
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lng'].toString()),
      isOpen: json['is_open'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cuisine': cuisine,
      'image_url': imageUrl,
      'rating': rating,
      'delivery_time_min': deliveryTimeMin,
      'delivery_fee_paise': deliveryFeePaise,
      'lat': lat,
      'lng': lng,
      'is_open': isOpen,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Restaurant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
