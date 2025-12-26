enum TransactionType { earn, spend }

class PointsTransactionModel {
  final String id;
  final String userId;
  final int amount;
  final TransactionType type;
  final String reason;
  final DateTime createdAt;
  final bool synced;

  PointsTransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.reason,
    required this.createdAt,
    this.synced = false,
  });

  factory PointsTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointsTransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: json['points_change'] as int,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.earn,
      ),
      reason: json['reason'] as String,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : (json['created_at'] as DateTime),
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'amount': amount,
        'type': type.name,
        'reason': reason,
        'created_at': createdAt.toIso8601String(),
        'synced': synced,
      };

  PointsTransactionModel copyWith({
    String? id,
    String? userId,
    int? amount,
    TransactionType? type,
    String? reason,
    DateTime? createdAt,
    bool? synced,
  }) =>
      PointsTransactionModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        reason: reason ?? this.reason,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
}
