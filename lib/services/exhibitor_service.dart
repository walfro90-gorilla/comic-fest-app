import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/exhibitor_model.dart';
import 'package:flutter/foundation.dart';

class ExhibitorService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<ExhibitorModel>> getFeaturedExhibitors() async {
    try {
      var response = await _supabase.client
          .from('exhibitor_details')
          .select('*, profiles(avatar_url)')
          .eq('is_featured', true)
          .limit(10);

      if ((response as List).isEmpty) {
        debugPrint('⚠️ No featured exhibitors found, fetching random exhibitors...');
        response = await _supabase.client
            .from('exhibitor_details')
            .select('*, profiles(avatar_url)')
            .limit(10);
      }

      return (response as List)
          .map((json) => ExhibitorModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Failed to fetch featured exhibitors: $e');
      return [];
    }
  }
}
