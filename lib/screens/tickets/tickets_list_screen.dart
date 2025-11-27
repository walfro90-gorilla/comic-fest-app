import 'package:comic_fest/models/ticket_model.dart';
import 'package:comic_fest/screens/tickets/ticket_detail_screen.dart';
import 'package:comic_fest/services/ticket_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  final TicketService _ticketService = TicketService();
  List<TicketModel> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await _ticketService.getUserTickets(forceRefresh: true);
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Boletos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              Navigator.of(context).pushNamed('/buy-tickets');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? _buildEmptyState(theme, colorScheme)
              : RefreshIndicator(
                  onRefresh: _loadTickets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      return _buildTicketCard(ticket, theme, colorScheme);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_num_outlined,
            size: 80,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No tienes boletos',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Compra tu boleto para Comic Fest!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/buy-tickets');
            },
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Comprar Boletos'),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(
    TicketModel ticket,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final statusColor = _getStatusColor(ticket.paymentStatus, colorScheme);
    final statusText = _getStatusText(ticket.paymentStatus);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticket: ticket),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.confirmation_num,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.ticketType,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${ticket.price.toStringAsFixed(2)} MXN',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Comprado: ${DateFormat('dd/MM/yyyy').format(ticket.purchaseDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              if (ticket.isValidated && ticket.validatedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Validado: ${DateFormat('dd/MM/yyyy HH:mm').format(ticket.validatedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentStatus status, ColorScheme colorScheme) {
    switch (status) {
      case PaymentStatus.approved:
        return colorScheme.tertiary;
      case PaymentStatus.pending:
        return colorScheme.secondary;
      case PaymentStatus.failed:
        return colorScheme.error;
      case PaymentStatus.refunded:
        return colorScheme.onSurface.withValues(alpha: 0.5);
    }
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.approved:
        return 'APROBADO';
      case PaymentStatus.pending:
        return 'PENDIENTE';
      case PaymentStatus.failed:
        return 'FALLIDO';
      case PaymentStatus.refunded:
        return 'REEMBOLSADO';
    }
  }
}
