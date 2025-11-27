class ContestantModel {
  final String id;
  final String scheduleItemId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int contestantNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int voteCount;
  final bool hasVoted;

  ContestantModel({
    required this.id,
    required this.scheduleItemId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.contestantNumber,
    required this.createdAt,
    required this.updatedAt,
    this.voteCount = 0,
    this.hasVoted = false,
  });

  factory ContestantModel.fromJson(Map<String, dynamic> json) {
    return ContestantModel(
      id: json['id'] as String,
      scheduleItemId: json['schedule_item_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      contestantNumber: json['contestant_number'] as int,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : (json['created_at'] as DateTime),
      updatedAt: json['updated_at'] is String
          ? DateTime.parse(json['updated_at'])
          : (json['updated_at'] as DateTime),
      voteCount: json['vote_count'] as int? ?? 0,
      hasVoted: json['has_voted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'schedule_item_id': scheduleItemId,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'contestant_number': contestantNumber,
        'updated_at': updatedAt.toIso8601String(),
      };

  ContestantModel copyWith({
    String? id,
    String? scheduleItemId,
    String? name,
    String? description,
    String? imageUrl,
    int? contestantNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? voteCount,
    bool? hasVoted,
  }) =>
      ContestantModel(
        id: id ?? this.id,
        scheduleItemId: scheduleItemId ?? this.scheduleItemId,
        name: name ?? this.name,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        contestantNumber: contestantNumber ?? this.contestantNumber,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        voteCount: voteCount ?? this.voteCount,
        hasVoted: hasVoted ?? this.hasVoted,
      );
}
