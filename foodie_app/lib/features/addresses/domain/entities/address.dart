class Address {
  final String id;
  final String userId;
  final String label;
  final String line1;
  final String? line2;
  final String city;
  final String pincode;
  final double lat;
  final double lng;
  final bool isDefault;
  final DateTime createdAt;

  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.pincode,
    required this.lat,
    required this.lng,
    required this.isDefault,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: (json['user_id'] ?? json['userId']) as String,
      label: json['label'] as String,
      line1: json['line1'] as String,
      line2: json['line2'] as String?,
      city: json['city'] as String,
      pincode: json['pincode'] as String,
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lng'].toString()),
      isDefault: json['is_default'] as bool? ?? json['isDefault'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now()),
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'label': label,
      'line1': line1,
      'line2': line2,
      'city': city,
      'pincode': pincode,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Address copyWith({
    String? id,
    String? userId,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? pincode,
    double? lat,
    double? lng,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Address && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

