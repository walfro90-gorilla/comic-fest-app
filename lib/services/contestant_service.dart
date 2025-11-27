import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/contestant_model.dart';
import 'package:flutter/foundation.dart';

class ContestantService {
  final SupabaseService _supabase = SupabaseService.instance;

  Future<List<ContestantModel>> getContestantsByEvent(String scheduleItemId) async {
    try {
      debugPrint('🔍 Fetching contestants for event ID: $scheduleItemId');
      final userId = _supabase.userId;
      
      // First, get basic contestants
      final response = await _supabase.client
          .from('contestants')
          .select('*')
          .eq('schedule_item_id', scheduleItemId)
          .order('contestant_number');

      debugPrint('📦 Raw response from contestants table: $response');
      debugPrint('📊 Response length: ${(response as List).length}');

      final contestants = <ContestantModel>[];
      
      for (final item in response) {
        debugPrint('👤 Processing contestant: ${item['name']} (ID: ${item['id']})');
        
        // Get vote count for this contestant (sum of points)
        final voteCountResponse = await _supabase.client
            .from('panel_votes')
            .select('points')
            .eq('contestant_id', item['id']);
        
        final voteCount = (voteCountResponse as List).fold<int>(
          0, 
          (sum, vote) => sum + (vote['points'] as int? ?? 1),
        );
        
        // Check if current user has voted
        bool hasVoted = false;
        if (userId != null) {
          final userVote = await _supabase.client
              .from('panel_votes')
              .select('id')
              .eq('contestant_id', item['id'])
              .eq('user_id', userId)
              .maybeSingle();
          
          hasVoted = userVote != null;
        }

        contestants.add(ContestantModel.fromJson({
          ...item,
          'vote_count': voteCount,
          'has_voted': hasVoted,
        }));
      }

      debugPrint('✅ Loaded ${contestants.length} contestants for event: $scheduleItemId');
      return contestants;
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading contestants: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<ContestantModel> createContestant({
    required String scheduleItemId,
    required String name,
    String? description,
    String? imageUrl,
    required int contestantNumber,
  }) async {
    try {
      final response = await _supabase.client
          .from('contestants')
          .insert({
            'schedule_item_id': scheduleItemId,
            'name': name,
            'description': description,
            'image_url': imageUrl,
            'contestant_number': contestantNumber,
          })
          .select()
          .single();

      debugPrint('✅ Contestant created: ${response['id']}');
      return ContestantModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Error creating contestant: $e');
      rethrow;
    }
  }

  Future<void> updateContestant({
    required String contestantId,
    String? name,
    String? description,
    String? imageUrl,
    int? contestantNumber,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (imageUrl != null) updates['image_url'] = imageUrl;
      if (contestantNumber != null) updates['contestant_number'] = contestantNumber;

      await _supabase.client
          .from('contestants')
          .update(updates)
          .eq('id', contestantId);

      debugPrint('✅ Contestant updated: $contestantId');
    } catch (e) {
      debugPrint('❌ Error updating contestant: $e');
      rethrow;
    }
  }

  Future<void> deleteContestant(String contestantId) async {
    try {
      await _supabase.client
          .from('contestants')
          .delete()
          .eq('id', contestantId);

      debugPrint('✅ Contestant deleted: $contestantId');
    } catch (e) {
      debugPrint('❌ Error deleting contestant: $e');
      rethrow;
    }
  }
}
