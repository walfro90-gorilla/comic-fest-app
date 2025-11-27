class ExhibitorModel {
  final String profileId;
  final String companyName;
  final String? boothId;
  final bool isFeatured;
  final String? websiteUrl;
  final String? avatarUrl;

  ExhibitorModel({
    required this.profileId,
    required this.companyName,
    this.boothId,
    required this.isFeatured,
    this.websiteUrl,
    this.avatarUrl,
  });

  factory ExhibitorModel.fromJson(Map<String, dynamic> json) {
    return ExhibitorModel(
      profileId: json['profile_id'] as String,
      companyName: json['company_name'] as String,
      boothId: json['booth_id'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      websiteUrl: json['website_url'] as String?,
      avatarUrl: json['profiles'] != null ? json['profiles']['avatar_url'] as String? : null,
    );
  }
}
