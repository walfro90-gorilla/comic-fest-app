class ComicModel {
  final String id;
  final String userId;
  final String prompt;
  final String? imageUrl;
  final String status;
  final String? modelUsed;
  final DateTime createdAt;

  ComicModel({
    required this.id,
    required this.userId,
    required this.prompt,
    this.imageUrl,
    required this.status,
    this.modelUsed,
    required this.createdAt,
  });

  factory ComicModel.fromJson(Map<String, dynamic> json) {
    return ComicModel(
      id: json['id'],
      userId: json['user_id'],
      prompt: json['prompt'],
      imageUrl: json['image_url'],
      status: json['status'],
      modelUsed: json['model_used'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'prompt': prompt,
      'image_url': imageUrl,
      'status': status,
      'model_used': modelUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
