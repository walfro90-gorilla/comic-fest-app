class OrderModel {
  final String id;
  final String userId;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final List<dynamic> items; // JSONB
  final String orderType;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.items,
    required this.orderType,
    required this.createdAt,
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
    );
  }
}
