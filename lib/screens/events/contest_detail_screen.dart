import 'package:comic_fest/core/connectivity_service.dart';
import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/contestant_model.dart';
import 'package:comic_fest/models/event_model.dart';
import 'package:comic_fest/services/contestant_service.dart';
import 'package:comic_fest/services/voting_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContestDetailScreen extends StatefulWidget {
  final EventModel event;

  const ContestDetailScreen({super.key, required this.event});

  @override
  State<ContestDetailScreen> createState() => _ContestDetailScreenState();
}

class _ContestDetailScreenState extends State<ContestDetailScreen> {
  final ContestantService _contestantService = ContestantService();
  final VotingService _votingService = VotingService();
  final ConnectivityService _connectivity = ConnectivityService.instance;
  final SupabaseService _supabase = SupabaseService.instance;
  List<ContestantModel> _contestants = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _hasVoted = false;
  final Map<String, int> _pointsDistribution = {};
  RealtimeChannel? _votesChannel;

  static const int maxTotalPoints = 6;
  static const int maxPointsPerContestant = 6;

  @override
  void initState() {
    super.initState();
    _loadContestants();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _votesChannel?.unsubscribe();
    super.dispose();
  }

  void _setupRealtimeListener() {
    if (!_connectivity.isOnline) return;

    _votesChannel = _supabase.client
        .channel('contest_votes_${widget.event.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'panel_votes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'schedule_item_id',
            value: widget.event.id,
          ),
          callback: (payload) {
            debugPrint('🔄 Vote update received: ${payload.eventType}');
            _loadContestants();
          },
        )
        .subscribe();

    debugPrint('👂 Listening for vote updates on event: ${widget.event.id}');
  }

  Future<void> _loadContestants() async {
    setState(() => _isLoading = true);
    try {
      final contestants = await _contestantService.getContestantsByEvent(widget.event.id);
      final hasVoted = await _votingService.hasUserVoted(widget.event.id);
      final userVotes = await _votingService.getUserVotesByEvent(widget.event.id);
      
      setState(() {
        _contestants = contestants;
        _hasVoted = hasVoted;
        _isLoading = false;
        for (var contestant in contestants) {
          _pointsDistribution[contestant.id] = userVotes[contestant.id] ?? 0;
        }
      });
      
      debugPrint('🗳️ Loaded contest: hasVoted=$hasVoted, userVotes=$userVotes');
    } catch (e) {
      debugPrint('❌ Error loading contestants: $e');
      setState(() => _isLoading = false);
    }
  }

  int get _totalPointsUsed => _pointsDistribution.values.fold<int>(0, (sum, points) => sum + points);
  int get _pointsRemaining => maxTotalPoints - _totalPointsUsed;

  void _incrementPoints(String contestantId) {
    if (_hasVoted) return;
    final currentPoints = _pointsDistribution[contestantId] ?? 0;
    if (_totalPointsUsed < maxTotalPoints && currentPoints < maxPointsPerContestant) {
      setState(() => _pointsDistribution[contestantId] = currentPoints + 1);
    }
  }

  void _decrementPoints(String contestantId) {
    if (_hasVoted) return;
    final currentPoints = _pointsDistribution[contestantId] ?? 0;
    if (currentPoints > 0) {
      setState(() => _pointsDistribution[contestantId] = currentPoints - 1);
    }
  }

  Future<void> _submitVotes() async {
    if (_totalPointsUsed != maxTotalPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes distribuir exactamente $maxTotalPoints puntos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _votingService.submitContestVotes(widget.event.id, _pointsDistribution);
      await _loadContestants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ¡Votos enviados! +5 puntos ganados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al votar: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadContestants,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.event.imageUrl != null)
                      Image.network(
                        widget.event.imageUrl!,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 240,
                          color: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.groups,
                            size: 80,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups,
                                  size: 16,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'CONCURSO',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.event.title,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('MMM dd, h:mm a').format(widget.event.startTime),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          if (widget.event.description.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              widget.event.description,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (!_hasVoted) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _pointsRemaining == 0
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _pointsRemaining == 0
                                      ? Colors.green
                                      : colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Puntos disponibles',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Distribuye exactamente $maxTotalPoints puntos',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _pointsRemaining == 0
                                          ? Colors.green
                                          : colorScheme.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$_pointsRemaining / $maxTotalPoints',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            children: [
                              Text(
                                'Concursantes',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_contestants.length} participantes',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_contestants.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No hay concursantes registrados',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _contestants.length,
                              itemBuilder: (context, index) {
                                final contestant = _contestants[index];
                                return ContestantCard(
                                  contestant: contestant,
                                  points: _pointsDistribution[contestant.id] ?? 0,
                                  hasVoted: _hasVoted,
                                  onIncrement: () => _incrementPoints(contestant.id),
                                  onDecrement: () => _decrementPoints(contestant.id),
                                );
                              },
                            ),
                            if (!_hasVoted) ...[
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _totalPointsUsed == maxTotalPoints && !_isSubmitting
                                      ? _submitVotes
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Enviar Votos',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class ContestantCard extends StatelessWidget {
  final ContestantModel contestant;
  final int points;
  final bool hasVoted;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const ContestantCard({
    super.key,
    required this.contestant,
    required this.points,
    required this.hasVoted,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#${contestant.contestantNumber}',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contestant.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (contestant.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          contestant.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.how_to_vote,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${contestant.voteCount} votos',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!hasVoted) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: points > 0 ? onDecrement : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    iconSize: 32,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: points > 0
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$points',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: points > 0
                            ? Colors.white
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: onIncrement,
                    icon: const Icon(Icons.add_circle_outline),
                    iconSize: 32,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ] else if (points > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Le diste $points ${points == 1 ? 'punto' : 'puntos'}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.star,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
