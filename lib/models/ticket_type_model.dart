class TicketTypeModel {
  final String id;
  final String name;
  final String? description;
  final double price;
  final int stockTotal;
  final int stockAvailable;
  final List<String> benefits;
  final bool isEarlyBird;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketTypeModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stockTotal,
    required this.stockAvailable,
    this.benefits = const [],
    this.isEarlyBird = false,
    this.isActive = true,
    this.displayOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAvailable => isActive && stockAvailable > 0;
  
  bool get isLowStock => stockAvailable > 0 && stockAvailable <= 10;
  
  int get percentageSold => stockTotal > 0 
      ? (((stockTotal - stockAvailable) / stockTotal) * 100).round() 
      : 0;

  factory TicketTypeModel.fromJson(Map<String, dynamic> json) {
    return TicketTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      stockTotal: json['stock_total'] as int? ?? 0,
      stockAvailable: json['stock_available'] as int? ?? 0,
      benefits: json['benefits'] != null 
          ? List<String>.from(json['benefits'] as List)
          : [],
      isEarlyBird: json['is_early_bird'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
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
        'stock_total': stockTotal,
        'stock_available': stockAvailable,
        'benefits': benefits,
        'is_early_bird': isEarlyBird,
        'is_active': isActive,
        'display_order': displayOrder,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  TicketTypeModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    int? stockTotal,
    int? stockAvailable,
    List<String>? benefits,
    bool? isEarlyBird,
    bool? isActive,
    int? displayOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TicketTypeModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        stockTotal: stockTotal ?? this.stockTotal,
        stockAvailable: stockAvailable ?? this.stockAvailable,
        benefits: benefits ?? this.benefits,
        isEarlyBird: isEarlyBird ?? this.isEarlyBird,
        isActive: isActive ?? this.isActive,
        displayOrder: displayOrder ?? this.displayOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
