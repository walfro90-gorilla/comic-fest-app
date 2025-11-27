import 'dart:convert';
import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/core/sync_queue.dart';
import 'package:comic_fest/models/panel_vote_model.dart';
import 'package:comic_fest/services/points_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class VotingService {
  static const String allVotesKey = 'all_panel_votes';
  static const String votesCountKey = 'votes_count_';
  SharedPreferences? _prefs;
  final SupabaseService _supabase = SupabaseService.instance;
  final SyncQueueManager _syncQueue = SyncQueueManager();
  final PointsService _pointsService = PointsService();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _syncQueue.init();
  }

  Future<bool> hasUserVoted(String scheduleItemId, {String? contestantId}) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) return false;

    final allVotes = await _getAllVotes();
    if (contestantId != null) {
      return allVotes.any(
        (vote) => vote.userId == userId && vote.contestantId == contestantId,
      );
    }
    return allVotes.any(
      (vote) => vote.userId == userId && vote.scheduleItemId == scheduleItemId,
    );
  }

  Future<void> voteForPanel(String scheduleItemId) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    if (await hasUserVoted(scheduleItemId)) {
      throw Exception('Ya has votado por este panel');
    }

    final vote = PanelVoteModel(
      id: const Uuid().v4(),
      userId: userId,
      scheduleItemId: scheduleItemId,
      createdAt: DateTime.now(),
      synced: false,
    );

    await _saveVote(vote);
    await _incrementVoteCount(scheduleItemId);

    await _syncQueue.addToQueue(
      id: vote.id,
      tableName: 'panel_votes',
      operation: SyncOperation.create,
      data: {
        'user_id': userId,
        'schedule_item_id': scheduleItemId,
      },
    );

    try {
      await _pointsService.earnPoints(
        amount: 5,
        reason: 'Votación en panel',
      );
      debugPrint('🎁 Earned 5 points for voting');
    } catch (e) {
      debugPrint('⚠️ Failed to award points: $e');
    }

    debugPrint('✅ Voted for panel: $scheduleItemId');
  }

  Future<void> voteForContestant(String scheduleItemId, String contestantId, {int points = 1}) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    if (await hasUserVoted(scheduleItemId, contestantId: contestantId)) {
      throw Exception('Ya has votado por este concursante');
    }

    final vote = PanelVoteModel(
      id: const Uuid().v4(),
      userId: userId,
      scheduleItemId: scheduleItemId,
      contestantId: contestantId,
      points: points,
      createdAt: DateTime.now(),
      synced: false,
    );

    await _saveVote(vote);
    await _incrementVoteCount(contestantId, by: points);

    await _syncQueue.addToQueue(
      id: vote.id,
      tableName: 'panel_votes',
      operation: SyncOperation.create,
      data: {
        'user_id': userId,
        'schedule_item_id': scheduleItemId,
        'contestant_id': contestantId,
        'points': points,
      },
    );

    try {
      await _pointsService.earnPoints(
        amount: 5,
        reason: 'Votación en concurso',
      );
      debugPrint('🎁 Earned 5 points for voting');
    } catch (e) {
      debugPrint('⚠️ Failed to award points: $e');
    }

    debugPrint('✅ Voted for contestant: $contestantId with $points points');
  }

  Future<void> submitContestVotes(String scheduleItemId, Map<String, int> contestantPoints) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    if (await hasUserVoted(scheduleItemId)) {
      throw Exception('Ya has votado en este concurso');
    }

    final totalPoints = contestantPoints.values.fold<int>(0, (sum, points) => sum + points);
    if (totalPoints != 6) {
      throw Exception('Debes distribuir exactamente 6 puntos');
    }

    final List<PanelVoteModel> votes = [];
    for (final entry in contestantPoints.entries) {
      if (entry.value > 0) {
        final vote = PanelVoteModel(
          id: const Uuid().v4(),
          userId: userId,
          scheduleItemId: scheduleItemId,
          contestantId: entry.key,
          points: entry.value,
          createdAt: DateTime.now(),
          synced: false,
        );
        votes.add(vote);
        await _saveVote(vote);
        await _incrementVoteCount(entry.key, by: entry.value);

        await _syncQueue.addToQueue(
          id: vote.id,
          tableName: 'panel_votes',
          operation: SyncOperation.create,
          data: {
            'user_id': userId,
            'schedule_item_id': scheduleItemId,
            'contestant_id': entry.key,
            'points': entry.value,
          },
        );
      }
    }

    try {
      await _pointsService.earnPoints(
        amount: 5,
        reason: 'Votación en concurso',
      );
      debugPrint('🎁 Earned 5 points for voting in contest');
    } catch (e) {
      debugPrint('⚠️ Failed to award points: $e');
    }

    debugPrint('✅ Submitted ${votes.length} votes for contest: $scheduleItemId');
  }

  Future<int> getVoteCount(String scheduleItemId) async {
    if (_prefs == null) await init();

    final cachedCount = _prefs?.getInt('$votesCountKey$scheduleItemId') ?? 0;

    try {
      final response = await _supabase.client
          .from('panel_votes')
          .select('id')
          .eq('schedule_item_id', scheduleItemId);

      final count = (response as List).length;
      await _prefs?.setInt('$votesCountKey$scheduleItemId', count);
      return count;
    } catch (e) {
      debugPrint('⚠️ Using cached vote count: $e');
      return cachedCount;
    }
  }

  Future<Map<String, int>> getVoteCounts(List<String> scheduleItemIds) async {
    if (_prefs == null) await init();

    final Map<String, int> counts = {};

    for (final id in scheduleItemIds) {
      counts[id] = await getVoteCount(id);
    }

    return counts;
  }

  Future<Map<String, int>> getUserVotesByEvent(String scheduleItemId) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) return {};

    final allVotes = await _getAllVotes();
    final userVotesForEvent = allVotes.where(
      (vote) => vote.userId == userId && vote.scheduleItemId == scheduleItemId,
    );

    final Map<String, int> contestantPoints = {};
    for (final vote in userVotesForEvent) {
      if (vote.contestantId != null) {
        contestantPoints[vote.contestantId!] = vote.points ?? 1;
      }
    }

    debugPrint('📊 Loaded ${contestantPoints.length} votes for user $userId in event $scheduleItemId');
    return contestantPoints;
  }

  Future<void> syncPendingVotes() async {
    if (_prefs == null) await init();

    final pendingItems = await _syncQueue.getPendingItems();
    final voteItems = pendingItems
        .where((item) => item.tableName == 'panel_votes')
        .toList();

    for (final item in voteItems) {
      try {
        await _supabase.client.from('panel_votes').insert(item.data);

        final allVotes = await _getAllVotes();
        final voteIndex = allVotes.indexWhere((v) => v.id == item.id);
        if (voteIndex != -1) {
          allVotes[voteIndex] = allVotes[voteIndex].copyWith(synced: true);
          final votesJson = allVotes.map((v) => v.toJson()).toList();
          await _prefs!.setString(allVotesKey, jsonEncode(votesJson));
        }

        await _syncQueue.markAsProcessed(item.id);
        debugPrint('✅ Synced vote: ${item.id}');
      } catch (e) {
        await _syncQueue.incrementRetry(item.id, e.toString());
        debugPrint('❌ Failed to sync vote: $e');
      }
    }
  }

  Future<void> _saveVote(PanelVoteModel vote) async {
    final allVotes = await _getAllVotes();
    allVotes.removeWhere((v) => v.id == vote.id);
    allVotes.add(vote);
    final votesJson = allVotes.map((v) => v.toJson()).toList();
    await _prefs!.setString(allVotesKey, jsonEncode(votesJson));
  }

  Future<void> _incrementVoteCount(String scheduleItemId, {int by = 1}) async {
    final currentCount = _prefs?.getInt('$votesCountKey$scheduleItemId') ?? 0;
    await _prefs?.setInt('$votesCountKey$scheduleItemId', currentCount + by);
  }

  Future<List<PanelVoteModel>> _getAllVotes() async {
    final votesJson = _prefs?.getString(allVotesKey);
    if (votesJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(votesJson);
      return decoded.map((json) => PanelVoteModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to parse votes: $e');
      return [];
    }
  }
}
