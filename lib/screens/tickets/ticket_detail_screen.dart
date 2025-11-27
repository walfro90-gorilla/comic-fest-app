import 'package:comic_fest/core/connectivity_service.dart';
import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/ticket_model.dart';
import 'package:comic_fest/services/ticket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketModel ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TicketService _ticketService = TicketService();
  final ConnectivityService _connectivity = ConnectivityService.instance;
  String? _qrCodeData;
  bool _isLoading = true;
  TicketModel? _currentTicket;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    _loadQRCode();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  /// Configura el listener de tiempo real SOLO si hay conexión
  void _setupRealtimeListener() {
    if (!_connectivity.isOnline) {
      debugPrint('📵 Offline mode - Realtime updates disabled');
      return;
    }

    try {
      debugPrint('🔄 Setting up realtime listener for ticket: ${widget.ticket.id}');
      
      _realtimeChannel = SupabaseService.instance.client
          .channel('ticket_updates_${widget.ticket.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'tickets',
            filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: widget.ticket.id),
            callback: (payload) {
              debugPrint('🔔 Realtime update received for ticket');
              _handleRealtimeUpdate(payload.newRecord);
            },
          )
          .subscribe();
      
      debugPrint('✅ Realtime listener subscribed');
    } catch (e) {
      debugPrint('⚠️ Failed to setup realtime listener (offline?): $e');
    }
  }

  /// Maneja actualizaciones en tiempo real
  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    try {
      final updatedTicket = TicketModel.fromJson(data);
      debugPrint('📝 Ticket updated: validated=${updatedTicket.isValidated}');
      
      setState(() {
        _currentTicket = updatedTicket;
      });

      // Mostrar notificación si el ticket fue validado
      if (updatedTicket.isValidated && !(_currentTicket?.isValidated ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tu boleto ha sido validado en la entrada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to parse realtime update: $e');
    }
  }

  Future<void> _loadQRCode() async {
    setState(() => _isLoading = true);
    try {
      final qrData = await _ticketService.getSecureQR(widget.ticket.id);
      setState(() {
        _qrCodeData = qrData;
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
    final ticket = _currentTicket ?? widget.ticket;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Boleto'),
        actions: [
          if (_connectivity.isOnline)
            Icon(Icons.cloud_done, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTicket,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTicketHeader(theme, colorScheme, ticket),
            if (ticket.paymentStatus == PaymentStatus.approved &&
                !ticket.isValidated)
              _buildQRSection(theme, colorScheme, ticket),
            _buildTicketDetails(theme, colorScheme, ticket),
            if (ticket.isValidated) _buildValidatedBanner(theme, colorScheme, ticket),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketHeader(ThemeData theme, ColorScheme colorScheme, TicketModel ticket) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_num,
            size: 64,
            color: colorScheme.onPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Comic Fest 2025',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ciudad Juárez, Chihuahua',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection(ThemeData theme, ColorScheme colorScheme, TicketModel ticket) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      );
    }

    if (_qrCodeData == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo cargar el código QR',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Presenta este código QR en la entrada',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: _qrCodeData!,
            version: QrVersions.auto,
            size: 250,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          const SizedBox(height: 16),
          Text(
            ticket.ticketType,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetails(ThemeData theme, ColorScheme colorScheme, TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalles del Boleto',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            theme,
            colorScheme,
            'Tipo de Boleto',
            ticket.ticketType,
          ),
          _buildDetailRow(
            theme,
            colorScheme,
            'Precio',
            '\$${ticket.price.toStringAsFixed(2)} MXN',
          ),
          _buildDetailRow(
            theme,
            colorScheme,
            'Fecha de Compra',
            DateFormat('dd/MM/yyyy HH:mm').format(ticket.purchaseDate),
          ),
          _buildDetailRow(
            theme,
            colorScheme,
            'Estado del Pago',
            _getStatusText(ticket.paymentStatus),
            valueColor: _getStatusColor(ticket.paymentStatus, colorScheme),
          ),
          if (ticket.isValidated && ticket.validatedAt != null)
            _buildDetailRow(
              theme,
              colorScheme,
              'Validado',
              DateFormat('dd/MM/yyyy HH:mm').format(ticket.validatedAt!),
              valueColor: colorScheme.tertiary,
            ),
          const SizedBox(height: 8),
          Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          _buildDetailRow(
            theme,
            colorScheme,
            'ID del Boleto',
            ticket.id.substring(0, 8).toUpperCase(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidatedBanner(ThemeData theme, ColorScheme colorScheme, TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: colorScheme.tertiary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boleto Validado',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Este boleto ya fue utilizado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        return 'Aprobado';
      case PaymentStatus.pending:
        return 'Pendiente';
      case PaymentStatus.failed:
        return 'Fallido';
      case PaymentStatus.refunded:
        return 'Reembolsado';
    }
  }

  void _shareTicket() {
    if (_qrCodeData != null) {
      Clipboard.setData(ClipboardData(text: _qrCodeData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código QR copiado al portapapeles'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
