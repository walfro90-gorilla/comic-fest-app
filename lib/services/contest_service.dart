import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/contest_model.dart';
import 'package:flutter/foundation.dart';

class ContestService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<ContestModel>> getActiveContests() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      var response = await _supabase.client
          .from('contests')
          .select()
          .eq('is_active', true)
          .lte('voting_start', now)
          .gte('voting_end', now)
          .order('voting_end', ascending: true);

      if ((response as List).isEmpty) {
        debugPrint('⚠️ No currently voting contests found, fetching all active contests...');
        response = await _supabase.client
            .from('contests')
            .select()
            .eq('is_active', true)
            .limit(5);
      }

      return (response as List)
          .map((json) => ContestModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('⚠️ Failed to fetch active contests: $e');
      return [];
    }
  }
}
