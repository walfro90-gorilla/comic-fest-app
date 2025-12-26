class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final int? pointsPrice;
  final String imageUrl;
  final int stock;
  final bool isExclusive;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.pointsPrice,
    required this.imageUrl,
    required this.stock,
    this.isExclusive = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      pointsPrice: json['points_price'] as int?,
      imageUrl: json['image_url'] as String,
      stock: json['stock'] as int,
      isExclusive: json['is_exclusive'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : (json['created_at'] as DateTime),
      updatedAt: json['updated_at'] is String
          ? DateTime.parse(json['updated_at'])
          : (json['updated_at'] as DateTime),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'points_price': pointsPrice,
        'image_url': imageUrl,
        'stock': stock,
        'is_exclusive': isExclusive,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? pointsPrice,
    String? imageUrl,
    int? stock,
    bool? isExclusive,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      ProductModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        pointsPrice: pointsPrice ?? this.pointsPrice,
        imageUrl: imageUrl ?? this.imageUrl,
        stock: stock ?? this.stock,
        isExclusive: isExclusive ?? this.isExclusive,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
