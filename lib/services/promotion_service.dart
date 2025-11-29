import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/promotion_model.dart';
import 'package:flutter/foundation.dart';

class PromotionService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<PromotionModel>> getActiveFlashPromotions() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      var response = await _supabase.client
          .from('promotions')
          .select('*, exhibitor_details(company_name)')
          .eq('is_active', true)
          .eq('is_flash', true)
          .gt('valid_until', now)
          .order('valid_until', ascending: true)
          .limit(5);

      if ((response as List).isEmpty) {
        debugPrint('⚠️ No flash promotions found, fetching active promotions...');
        response = await _supabase.client
            .from('promotions')
            .select('*, exhibitor_details(company_name)')
            .eq('is_active', true)
            .gt('valid_until', now)
            .order('valid_until', ascending: true)
            .limit(5);
      }

      return (response as List)
          .map((json) => PromotionModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Failed to fetch flash promotions: $e');
      return [];
    }
  }
}
