enum PaymentStatus { pending, approved, failed, refunded }

class TicketModel {
  final String id;
  final String userId;
  final String ticketType;
  final double price;
  final PaymentStatus paymentStatus;
  final String? paymentIdMp;
  final String qrCodeData;
  final bool isValidated;
  final DateTime? validatedAt;
  final DateTime purchaseDate;
  final DateTime updatedAt;

  TicketModel({
    required this.id,
    required this.userId,
    required this.ticketType,
    required this.price,
    required this.paymentStatus,
    this.paymentIdMp,
    required this.qrCodeData,
    this.isValidated = false,
    this.validatedAt,
    required this.purchaseDate,
    required this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ticketType: json['ticket_type'] as String,
      price: (json['price'] as num).toDouble(),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      paymentIdMp: json['payment_id_mp'] as String?,
      qrCodeData: json['qr_code_data'] as String,
      isValidated: json['is_validated'] as bool? ?? false,
      validatedAt: json['validated_at'] != null
          ? (json['validated_at'] is String
              ? DateTime.parse(json['validated_at'])
              : (json['validated_at'] as DateTime))
          : null,
      purchaseDate: json['purchase_date'] is String
          ? DateTime.parse(json['purchase_date'])
          : (json['purchase_date'] as DateTime),
      updatedAt: json['updated_at'] is String
          ? DateTime.parse(json['updated_at'])
          : (json['updated_at'] as DateTime),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'ticket_type': ticketType,
        'price': price,
        'payment_status': paymentStatus.name,
        'payment_id_mp': paymentIdMp,
        'qr_code_data': qrCodeData,
        'is_validated': isValidated,
        'validated_at': validatedAt?.toIso8601String(),
        'purchase_date': purchaseDate.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  TicketModel copyWith({
    String? id,
    String? userId,
    String? ticketType,
    double? price,
    PaymentStatus? paymentStatus,
    String? paymentIdMp,
    String? qrCodeData,
    bool? isValidated,
    DateTime? validatedAt,
    DateTime? purchaseDate,
    DateTime? updatedAt,
  }) =>
      TicketModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        ticketType: ticketType ?? this.ticketType,
        price: price ?? this.price,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        paymentIdMp: paymentIdMp ?? this.paymentIdMp,
        qrCodeData: qrCodeData ?? this.qrCodeData,
        isValidated: isValidated ?? this.isValidated,
        validatedAt: validatedAt ?? this.validatedAt,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
