class OrderModel {
  final String id;
  final String userId;
  final Map<String, dynamic> items;
  final double totalAmount;
  final String? paymentMethod;
  final String? deliveryMethod;
  final String status;
  final String? paymentIdMp;
  final String? orderNumber;
  final String? orderType;
  final String? buyerName;
  final String? buyerEmail;
  final String? buyerPhone;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    this.paymentMethod,
    this.deliveryMethod,
    this.status = 'pending',
    this.paymentIdMp,
    this.orderNumber,
    this.orderType,
    this.buyerName,
    this.buyerEmail,
    this.buyerPhone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      items: json['items'] as Map<String, dynamic>,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String?,
      deliveryMethod: json['delivery_method'] as String?,
      status: json['status'] as String? ?? 'pending',
      paymentIdMp: json['payment_id_mp'] as String?,
      orderNumber: json['order_number'] as String?,
      orderType: json['order_type'] as String?,
      buyerName: json['buyer_name'] as String?,
      buyerEmail: json['buyer_email'] as String?,
      buyerPhone: json['buyer_phone'] as String?,
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
        'user_id': userId,
        'items': items,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'delivery_method': deliveryMethod,
        'status': status,
        'payment_id_mp': paymentIdMp,
        'order_number': orderNumber,
        'order_type': orderType,
        'buyer_name': buyerName,
        'buyer_email': buyerEmail,
        'buyer_phone': buyerPhone,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  OrderModel copyWith({
    String? id,
    String? userId,
    Map<String, dynamic>? items,
    double? totalAmount,
    String? paymentMethod,
    String? deliveryMethod,
    String? status,
    String? paymentIdMp,
    String? orderNumber,
    String? orderType,
    String? buyerName,
    String? buyerEmail,
    String? buyerPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      OrderModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        items: items ?? this.items,
        totalAmount: totalAmount ?? this.totalAmount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        deliveryMethod: deliveryMethod ?? this.deliveryMethod,
        status: status ?? this.status,
        paymentIdMp: paymentIdMp ?? this.paymentIdMp,
        orderNumber: orderNumber ?? this.orderNumber,
        orderType: orderType ?? this.orderType,
        buyerName: buyerName ?? this.buyerName,
        buyerEmail: buyerEmail ?? this.buyerEmail,
        buyerPhone: buyerPhone ?? this.buyerPhone,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
