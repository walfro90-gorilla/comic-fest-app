enum EventCategory { panel, firma, torneo, actividad, concurso }

class EventModel {
  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final DateTime startTime;
  final DateTime endTime;
  final String? locationId;
  final String? artistId;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final int voteCount;
  final bool hasVoted;

  EventModel({
    required this.id,
    required this.title,
    this.description = '',
    this.category = EventCategory.actividad,
    required this.startTime,
    required this.endTime,
    this.locationId,
    this.artistId,
    this.isActive = true,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.voteCount = 0,
    this.hasVoted = false,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    EventCategory? category;
    if (json['category'] != null) {
      category = EventCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => EventCategory.actividad,
      );
    }

    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: category ?? EventCategory.actividad,
      startTime: (json['start_time'] is String
          ? DateTime.parse(json['start_time'])
          : (json['start_time'] as DateTime)).toLocal(),
      endTime: (json['end_time'] is String
          ? DateTime.parse(json['end_time'])
          : (json['end_time'] as DateTime)).toLocal(),
      locationId: json['location_id'] as String?,
      artistId: json['artist_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? (json['created_at'] is String
              ? DateTime.parse(json['created_at'])
              : (json['created_at'] as DateTime))
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] is String
              ? DateTime.parse(json['updated_at'])
              : (json['updated_at'] as DateTime))
          : DateTime.now(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      voteCount: json['vote_count'] as int? ?? 0,
      hasVoted: json['has_voted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.name,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'location_id': locationId,
        'artist_id': artistId,
        'is_active': isActive,
        'image_url': imageUrl,
        'updated_at': updatedAt.toIso8601String(),
      };

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    EventCategory? category,
    DateTime? startTime,
    DateTime? endTime,
    String? locationId,
    String? artistId,
    bool? isActive,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    int? voteCount,
    bool? hasVoted,
  }) =>
      EventModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        locationId: locationId ?? this.locationId,
        artistId: artistId ?? this.artistId,
        isActive: isActive ?? this.isActive,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isFavorite: isFavorite ?? this.isFavorite,
        voteCount: voteCount ?? this.voteCount,
        hasVoted: hasVoted ?? this.hasVoted,
      );
}
