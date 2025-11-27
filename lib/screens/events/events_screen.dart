import 'package:comic_fest/models/event_model.dart';
import 'package:comic_fest/services/event_service.dart';
import 'package:comic_fest/widgets/event_card.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  final EventService _eventService = EventService();
  late TabController _tabController;
  List<EventModel> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);

    try {
      final events = await _eventService.getEvents();
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<EventModel> _getFilteredEvents(int tabIndex) {
    if (tabIndex == 0) return _allEvents;
    if (tabIndex == 1) {
      return _allEvents.where((e) => e.isFavorite).toList();
    }

    final category = EventCategory.values[tabIndex - 2];
    return _allEvents.where((e) => e.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda del Evento'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: colorScheme.onPrimary,
          labelColor: colorScheme.onPrimary,
          unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.6),
          labelPadding: const EdgeInsets.symmetric(horizontal: 20),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Favoritos'),
            Tab(text: 'Paneles'),
            Tab(text: 'Firmas'),
            Tab(text: 'Torneos'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEvents,
              child: TabBarView(
                controller: _tabController,
                children: List.generate(5, (index) {
                  final events = _getFilteredEvents(index);
                  return _buildEventsList(events, theme, colorScheme);
                }),
              ),
            ),
    );
  }

  Widget _buildEventsList(
    List<EventModel> events,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (events.isEmpty) {
      return Center(
        child: Text(
          'No hay eventos en esta categoría',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: events.length,
      itemBuilder: (context, index) => EventCard(event: events[index]),
    );
  }
}
