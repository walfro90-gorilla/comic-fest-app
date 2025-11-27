enum PaymentStatusEnum { pending, approved, rejected, refunded, cancelled }

class PaymentModel {
  final String id;
  final String orderId;
  final String? mpPaymentId;
  final String? mpPreferenceId;
  final PaymentStatusEnum status;
  final String? paymentMethod;
  final String? paymentMethodType;
  final double transactionAmount;
  final String currency;
  final String? statusDetail;
  final String? externalReference;
  final Map<String, dynamic>? webhookData;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    this.mpPaymentId,
    this.mpPreferenceId,
    required this.status,
    this.paymentMethod,
    this.paymentMethodType,
    required this.transactionAmount,
    this.currency = 'MXN',
    this.statusDetail,
    this.externalReference,
    this.webhookData,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isApproved => status == PaymentStatusEnum.approved;
  bool get isPending => status == PaymentStatusEnum.pending;
  bool get isRejected => status == PaymentStatusEnum.rejected;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      mpPaymentId: json['mp_payment_id'] as String?,
      mpPreferenceId: json['mp_preference_id'] as String?,
      status: PaymentStatusEnum.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatusEnum.pending,
      ),
      paymentMethod: json['payment_method'] as String?,
      paymentMethodType: json['payment_method_type'] as String?,
      transactionAmount: (json['transaction_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'MXN',
      statusDetail: json['status_detail'] as String?,
      externalReference: json['external_reference'] as String?,
      webhookData: json['webhook_data'] as Map<String, dynamic>?,
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
        'order_id': orderId,
        'mp_payment_id': mpPaymentId,
        'mp_preference_id': mpPreferenceId,
        'status': status.name,
        'payment_method': paymentMethod,
        'payment_method_type': paymentMethodType,
        'transaction_amount': transactionAmount,
        'currency': currency,
        'status_detail': statusDetail,
        'external_reference': externalReference,
        'webhook_data': webhookData,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? mpPaymentId,
    String? mpPreferenceId,
    PaymentStatusEnum? status,
    String? paymentMethod,
    String? paymentMethodType,
    double? transactionAmount,
    String? currency,
    String? statusDetail,
    String? externalReference,
    Map<String, dynamic>? webhookData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PaymentModel(
        id: id ?? this.id,
        orderId: orderId ?? this.orderId,
        mpPaymentId: mpPaymentId ?? this.mpPaymentId,
        mpPreferenceId: mpPreferenceId ?? this.mpPreferenceId,
        status: status ?? this.status,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentMethodType: paymentMethodType ?? this.paymentMethodType,
        transactionAmount: transactionAmount ?? this.transactionAmount,
        currency: currency ?? this.currency,
        statusDetail: statusDetail ?? this.statusDetail,
        externalReference: externalReference ?? this.externalReference,
        webhookData: webhookData ?? this.webhookData,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
