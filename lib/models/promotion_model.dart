class PromotionModel {
  final String id;
  final String exhibitorId;
  final String title;
  final String description;
  final int? discountPercent;
  final DateTime validUntil;
  final bool isFlash;
  final String? exhibitorName; // Joined from exhibitor_details

  PromotionModel({
    required this.id,
    required this.exhibitorId,
    required this.title,
    required this.description,
    this.discountPercent,
    required this.validUntil,
    required this.isFlash,
    this.exhibitorName,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'] as String,
      exhibitorId: json['exhibitor_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      discountPercent: json['discount_percent'] as int?,
      validUntil: DateTime.parse(json['valid_until'] as String),
      isFlash: json['is_flash'] as bool? ?? false,
      exhibitorName: json['exhibitor_details'] != null 
          ? json['exhibitor_details']['company_name'] as String? 
          : null,
    );
  }
}
