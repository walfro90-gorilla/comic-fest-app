class PanelVoteModel {
  final String id;
  final String userId;
  final String scheduleItemId;
  final String? contestantId;
  final int points;
  final DateTime createdAt;
  final bool synced;

  PanelVoteModel({
    required this.id,
    required this.userId,
    required this.scheduleItemId,
    this.contestantId,
    this.points = 1,
    required this.createdAt,
    this.synced = false,
  });

  factory PanelVoteModel.fromJson(Map<String, dynamic> json) {
    return PanelVoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      scheduleItemId: json['schedule_item_id'] as String,
      contestantId: json['contestant_id'] as String?,
      points: json['points'] as int? ?? 1,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : (json['created_at'] as DateTime),
      synced: json['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'schedule_item_id': scheduleItemId,
        if (contestantId != null) 'contestant_id': contestantId,
        'points': points,
        'created_at': createdAt.toIso8601String(),
        'synced': synced,
      };

  PanelVoteModel copyWith({
    String? id,
    String? userId,
    String? scheduleItemId,
    String? contestantId,
    int? points,
    DateTime? createdAt,
    bool? synced,
  }) =>
      PanelVoteModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        scheduleItemId: scheduleItemId ?? this.scheduleItemId,
        contestantId: contestantId ?? this.contestantId,
        points: points ?? this.points,
        createdAt: createdAt ?? this.createdAt,
        synced: synced ?? this.synced,
      );
}
