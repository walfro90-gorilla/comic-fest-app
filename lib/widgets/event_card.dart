import 'package:comic_fest/models/event_model.dart';
import 'package:comic_fest/screens/events/contest_detail_screen.dart';
import 'package:comic_fest/services/event_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventCard extends StatefulWidget {
  final EventModel event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  final EventService _eventService = EventService();
  late EventModel _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  IconData _getCategoryIcon() {
    switch (widget.event.category) {
      case EventCategory.panel:
        return Icons.groups;
      case EventCategory.firma:
        return Icons.edit;
      case EventCategory.torneo:
        return Icons.sports_esports;
      case EventCategory.actividad:
        return Icons.celebration;
      case EventCategory.concurso:
        return Icons.emoji_events;
    }
  }

  Color _getCategoryColor(ColorScheme colorScheme) {
    switch (widget.event.category) {
      case EventCategory.panel:
        return colorScheme.primary;
      case EventCategory.firma:
        return colorScheme.secondary;
      case EventCategory.torneo:
        return colorScheme.tertiary;
      case EventCategory.actividad:
        return Colors.green;
      case EventCategory.concurso:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryColor = _getCategoryColor(colorScheme);

    return Card(
      child: InkWell(
        onTap: () {
          if (_event.category == EventCategory.concurso) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContestDetailScreen(event: _event),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_event.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  _event.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: colorScheme.primaryContainer,
                    child: Icon(
                      _getCategoryIcon(),
                      size: 64,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(),
                              size: 16,
                              color: categoryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _event.category.name.toUpperCase(),
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _event.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _event.isFavorite ? Colors.red : colorScheme.onSurface,
                        ),
                        onPressed: () {
                          _eventService.toggleFavorite(_event.id);
                          setState(() {
                            _event = _event.copyWith(isFavorite: !_event.isFavorite);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _event.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd, h:mm a').format(_event.startTime),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  if (_event.locationId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Location ID: ${_event.locationId}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
