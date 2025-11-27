import 'dart:convert';
import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/event_model.dart';
import 'package:comic_fest/services/voting_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EventService {
  static const String allEventsKey = 'all_events';
  SharedPreferences? _prefs;
  final SupabaseService _supabase = SupabaseService.instance;
  final VotingService _votingService = VotingService();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<EventModel>> getEvents({bool forceRefresh = false}) async {
    if (_prefs == null) await init();

    final cachedEvents = await _getAllEvents();
    if (!forceRefresh && cachedEvents.isNotEmpty) {
      debugPrint('📦 Returning cached events: ${cachedEvents.length}');
      return cachedEvents;
    }

    try {
      final response = await _supabase.client
          .from('schedule_items')
          .select()
          .eq('is_active', true)
          .order('start_time', ascending: true);

      final events = (response as List)
          .map((json) => EventModel.fromJson(json))
          .toList();

      final eventsWithVotes = await _enrichWithVoteData(events);

      final eventsJson = eventsWithVotes.map((e) => e.toJson()).toList();
      await _prefs!.setString(allEventsKey, jsonEncode(eventsJson));

      debugPrint('✅ Events synced from Supabase: ${events.length}');
      return eventsWithVotes;
    } catch (e) {
      debugPrint('⚠️ Using cached events: $e');
      return cachedEvents;
    }
  }

  Future<List<EventModel>> getFavoriteEvents() async {
    if (_prefs == null) await init();
    final allEvents = await _getAllEvents();
    return allEvents.where((event) => event.isFavorite).toList();
  }

  Future<void> toggleFavorite(String eventId) async {
    if (_prefs == null) await init();

    final allEvents = await _getAllEvents();
    final eventIndex = allEvents.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;

    final event = allEvents[eventIndex];
    final updated = event.copyWith(isFavorite: !event.isFavorite);
    allEvents[eventIndex] = updated;
    
    final eventsJson = allEvents.map((e) => e.toJson()).toList();
    await _prefs!.setString(allEventsKey, jsonEncode(eventsJson));
    debugPrint('⭐ Event ${updated.isFavorite ? 'favorited' : 'unfavorited'}');
  }

  Future<List<EventModel>> getEventsByCategory(EventCategory category) async {
    if (_prefs == null) await init();
    final allEvents = await _getAllEvents();
    return allEvents.where((event) => event.category == category).toList();
  }

  Future<List<EventModel>> getUpcomingEvents() async {
    if (_prefs == null) await init();
    final now = DateTime.now();
    final allEvents = await _getAllEvents();
    return allEvents
        .where((event) => event.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<List<EventModel>> _getAllEvents() async {
    final eventsJson = _prefs?.getString(allEventsKey);
    if (eventsJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(eventsJson);
      return decoded.map((json) => EventModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to parse events: $e');
      return [];
    }
  }

  Future<List<EventModel>> _enrichWithVoteData(List<EventModel> events) async {
    final eventIds = events.map((e) => e.id).toList();
    final voteCounts = await _votingService.getVoteCounts(eventIds);

    return Future.wait(events.map((event) async {
      final voteCount = voteCounts[event.id] ?? 0;
      final hasVoted = await _votingService.hasUserVoted(event.id);
      return event.copyWith(voteCount: voteCount, hasVoted: hasVoted);
    }));
  }
}
