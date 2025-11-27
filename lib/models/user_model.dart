enum UserRole { attendee, exhibitor, artist, admin, staff }

class UserModel {
  final String id;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final String? bio;
  final UserRole role;
  final int points;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.username,
    this.email,
    this.avatarUrl,
    this.bio,
    required this.role,
    this.points = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      email: json['email'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.attendee,
      ),
      points: json['points'] as int? ?? 0,
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
        'username': username,
        'avatar_url': avatarUrl,
        'bio': bio,
        'role': role.name,
        'points': points,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? avatarUrl,
    String? bio,
    UserRole? role,
    int? points,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        username: username ?? this.username,
        email: email ?? this.email,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        bio: bio ?? this.bio,
        role: role ?? this.role,
        points: points ?? this.points,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  String get displayName => username ?? email ?? 'Usuario';
}
