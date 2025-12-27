class OrderModel {
  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final List<dynamic> items; // JSONB
  final String orderType;
  final DateTime createdAt;
  final String? orderNumber;
  final String? buyerName;
  final String? buyerEmail;
  final String? buyerPhone;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.items,
    required this.orderType,
    required this.createdAt,
    this.orderNumber,
    this.buyerName,
    this.buyerEmail,
    this.buyerPhone,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      status: json['status'] as String,
      paymentMethod: json['payment_method'] as String? ?? 'unknown',
      items: json['items'] is List ? json['items'] as List : [],
      orderType: json['order_type'] as String? ?? 'product',
      createdAt: DateTime.parse(json['created_at'] as String),
      orderNumber: json['order_number'] as String?,
      buyerName: json['buyer_name'] as String?,
      buyerEmail: json['buyer_email'] as String?,
      buyerPhone: json['buyer_phone'] as String?,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'total_amount': totalAmount,
      'status': status,
      'payment_method': paymentMethod,
      'items': items,
      'order_type': orderType,
      'created_at': createdAt.toIso8601String(),
      'order_number': orderNumber,
      'buyer_name': buyerName,
      'buyer_email': buyerEmail,
      'buyer_phone': buyerPhone,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
