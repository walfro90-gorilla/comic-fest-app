import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/payment_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final SupabaseService _supabase = SupabaseService.instance;
  List<PaymentModel> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Consulta compleja: Pagos -> Ordenes -> Usuario
      // Supabase no soporta joins profundos directos fácilmente en el cliente sin configurar foreign keys perfectas y permisos.
      // Una estrategia más segura es obtener las órdenes del usuario primero y luego los pagos de esas órdenes.
      
      // 1. Obtener IDs de órdenes del usuario
      final ordersResponse = await _supabase.client
          .from('orders')
          .select('id')
          .eq('user_id', userId);
      
      final orderIds = (ordersResponse as List).map((o) => o['id']).toList();

      if (orderIds.isEmpty) {
        setState(() {
          _payments = [];
          _isLoading = false;
        });
        return;
      }

      // 2. Obtener pagos de esas órdenes
      final paymentsResponse = await _supabase.client
          .from('payments')
          .select()
          .filter('order_id', 'in', orderIds)
          .order('created_at', ascending: false);

      final payments = (paymentsResponse as List)
          .map((json) => PaymentModel.fromJson(json))
          .toList();

      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading payment history: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar historial: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(PaymentStatusEnum status) {
    switch (status) {
      case PaymentStatusEnum.approved:
        return Colors.green;
      case PaymentStatusEnum.pending:
        return Colors.orange;
      case PaymentStatusEnum.rejected:
      case PaymentStatusEnum.cancelled:
      case PaymentStatusEnum.failed:
        return Colors.red;
      case PaymentStatusEnum.refunded:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PaymentStatusEnum status) {
    switch (status) {
      case PaymentStatusEnum.approved:
        return Icons.check_circle;
      case PaymentStatusEnum.pending:
        return Icons.access_time;
      case PaymentStatusEnum.rejected:
      case PaymentStatusEnum.cancelled:
      case PaymentStatusEnum.failed:
        return Icons.error;
      case PaymentStatusEnum.refunded:
        return Icons.replay;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(PaymentStatusEnum status) {
    switch (status) {
      case PaymentStatusEnum.approved:
        return 'Aprobado';
      case PaymentStatusEnum.pending:
        return 'Pendiente';
      case PaymentStatusEnum.rejected:
        return 'Rechazado';
      case PaymentStatusEnum.cancelled:
        return 'Cancelado';
      case PaymentStatusEnum.failed:
        return 'Fallido';
      case PaymentStatusEnum.refunded:
        return 'Reembolsado';
      default:
        return status.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Compras'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes compras registradas',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _payments.length,
                  itemBuilder: (context, index) {
                    final payment = _payments[index];
                    final color = _getStatusColor(payment.status);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.1),
                          child: Icon(_getStatusIcon(payment.status), color: color),
                        ),
                        title: Text(
                          '\$${payment.transactionAmount.toStringAsFixed(2)} ${payment.currency}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(payment.createdAt),
                        ),
                        trailing: Chip(
                          label: Text(
                            _getStatusText(payment.status),
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          backgroundColor: color.withOpacity(0.1),
                          side: BorderSide.none,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow('ID de Pago (MP)', payment.mpPaymentId ?? 'N/A'),
                                _buildDetailRow('ID de Orden', payment.orderId),
                                _buildDetailRow('Método', payment.paymentMethod?.toUpperCase() ?? 'N/A'),
                                if (payment.statusDetail != null)
                                  _buildDetailRow('Detalle Estado', payment.statusDetail!),
                                const SizedBox(height: 8),
                                if (payment.status == PaymentStatusEnum.pending)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Tu pago está siendo revisado. Te notificaremos cuando se apruebe.',
                                            style: TextStyle(fontSize: 12, color: Colors.orange),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
