class ContestModel {
  final String id;
  final String name;
  final String category;
  final String? description;
  final DateTime votingStart;
  final DateTime votingEnd;
  final bool isActive;

  ContestModel({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.votingStart,
    required this.votingEnd,
    required this.isActive,
  });

  factory ContestModel.fromJson(Map<String, dynamic> json) {
    return ContestModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      votingStart: DateTime.parse(json['voting_start'] as String),
      votingEnd: DateTime.parse(json['voting_end'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
