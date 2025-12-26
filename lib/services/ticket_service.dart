import 'dart:convert';
import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/models/ticket_model.dart';
import 'package:comic_fest/models/ticket_type_model.dart';
import 'package:comic_fest/services/points_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class TicketService {
  static const String keyPrefix = 'ticket_';
  static const String allTicketsKey = 'all_tickets';
  static const String ticketTypesKey = 'ticket_types_cache';
  SharedPreferences? _prefs;
  final SupabaseService _supabase = SupabaseService.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final PointsService _pointsService = PointsService();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Obtener tipos de tickets disponibles para compra
  Future<List<TicketTypeModel>> getAvailableTicketTypes({bool forceRefresh = false}) async {
    if (_prefs == null) await init();

    // Intentar usar caché primero
    if (!forceRefresh) {
      final cached = _prefs?.getString(ticketTypesKey);
      if (cached != null) {
        try {
          final List<dynamic> decoded = jsonDecode(cached);
          final types = decoded.map((json) => TicketTypeModel.fromJson(json)).toList();
          if (types.isNotEmpty) {
            debugPrint('📦 Returning cached ticket types: ${types.length}');
            return types;
          }
        } catch (e) {
          debugPrint('⚠️ Failed to parse cached ticket types: $e');
        }
      }
    }

    try {
      final response = await _supabase.client
          .from('ticket_types')
          .select()
          .order('display_order', ascending: true);

      final types = (response as List)
          .map((json) => TicketTypeModel.fromJson(json))
          .toList();

      // Guardar en caché
      final encoded = jsonEncode(types.map((t) => t.toJson()).toList());
      await _prefs?.setString(ticketTypesKey, encoded);

      debugPrint('✅ Fetched ticket types from Supabase: ${types.length}');
      return types;
    } catch (e) {
      debugPrint('❌ Failed to fetch ticket types: $e');
      return [];
    }
  }

  Future<TicketTypeModel> createTicketType(TicketTypeModel type) async {
    try {
      final response = await _supabase.client
          .from('ticket_types')
          .insert(type.toJson()..remove('id'))
          .select()
          .single();

      final newType = TicketTypeModel.fromJson(response);
      
      // Force refresh cache
      await getAvailableTicketTypes(forceRefresh: true);

      debugPrint('✅ Ticket type created: ${newType.name}');
      return newType;
    } catch (e) {
      debugPrint('❌ Error creating ticket type: $e');
      rethrow;
    }
  }

  Future<void> updateTicketType(TicketTypeModel type) async {
    try {
      final updates = type.toJson();
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.client
          .from('ticket_types')
          .update(updates)
          .eq('id', type.id);

      // Force refresh cache
      await getAvailableTicketTypes(forceRefresh: true);
      
      debugPrint('✅ Ticket type updated: ${type.id}');
    } catch (e) {
      debugPrint('❌ Error updating ticket type: $e');
      rethrow;
    }
  }

  Future<void> deleteTicketType(String typeId) async {
    try {
      // Soft delete
      await _supabase.client
          .from('ticket_types')
          .update({'is_active': false})
          .eq('id', typeId);

      // Force refresh cache
      await getAvailableTicketTypes(forceRefresh: true);
      
      debugPrint('✅ Ticket type deleted (soft): $typeId');
    } catch (e) {
      debugPrint('❌ Error deleting ticket type: $e');
      rethrow;
    }
  }

  /// Obtener un tipo de ticket específico
  Future<TicketTypeModel?> getTicketTypeById(String ticketTypeId) async {
    try {
      final response = await _supabase.client
          .from('ticket_types')
          .select()
          .eq('id', ticketTypeId)
          .single();

      return TicketTypeModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ Failed to get ticket type: $e');
      return null;
    }
  }

  Future<TicketModel> createTicket({
    required String ticketType,
    required double price,
  }) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    final ticketId = const Uuid().v4();
    final qrCode = _generateSecureQR(ticketId, userId);

    final ticket = TicketModel(
      id: ticketId,
      userId: userId,
      ticketType: ticketType,
      price: price,
      paymentStatus: PaymentStatus.approved,
      qrCodeData: qrCode,
      purchaseDate: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _saveTicket(ticket);
    await _secureStorage.write(key: 'qr_$ticketId', value: qrCode);

    try {
      await _supabase.client.from('tickets').insert(ticket.toJson());
      debugPrint('✅ Ticket created on Supabase');
    } catch (e) {
      debugPrint('⚠️ Ticket saved locally, will sync later: $e');
    }

    final earnedPoints = (price * 0.1).round();
    if (earnedPoints > 0) {
      try {
        await _pointsService.earnPoints(
          amount: earnedPoints,
          reason: 'Compra de boleto $ticketType',
        );
        debugPrint('🎁 Earned $earnedPoints points from ticket purchase');
      } catch (e) {
        debugPrint('⚠️ Failed to award points: $e');
      }
    }

    return ticket;
  }

  String _generateSecureQR(String ticketId, String userId) {
    // El QR simplemente contiene el ID del ticket
    // La validación se hace contra Supabase
    return ticketId;
  }

  Future<List<TicketModel>> getUserTickets({bool forceRefresh = false}) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) return [];

    if (!forceRefresh) {
      final cachedTickets = await _getAllTickets();
      final userTickets = cachedTickets.where((t) => t.userId == userId).toList();
      if (userTickets.isNotEmpty) {
        debugPrint('📦 Returning cached tickets: ${userTickets.length}');
        return userTickets;
      }
    }

    try {
      final response = await _supabase.client
          .from('tickets')
          .select()
          .eq('user_id', userId)
          .order('purchase_date', ascending: false);

      final tickets =
          (response as List).map((json) => TicketModel.fromJson(json)).toList();

      for (final ticket in tickets) {
        await _saveTicket(ticket);
        if (ticket.qrCodeData.isNotEmpty) {
          await _secureStorage.write(
            key: 'qr_${ticket.id}',
            value: ticket.qrCodeData,
          );
        }
      }

      debugPrint('✅ Tickets synced from Supabase: ${tickets.length}');
      return tickets;
    } catch (e) {
      debugPrint('⚠️ Using cached tickets: $e');
      final cachedTickets = await _getAllTickets();
      return cachedTickets.where((t) => t.userId == userId).toList();
    }
  }

  Future<String?> getSecureQR(String ticketId) async {
    try {
      return await _secureStorage.read(key: 'qr_$ticketId');
    } catch (e) {
      debugPrint('❌ Failed to read QR: $e');
      return null;
    }
  }

  /// Valida un ticket escaneado contra la base de datos de Supabase
  /// Retorna true solo si:
  /// - El ticket existe en la DB
  /// - El pago está aprobado
  /// - NO ha sido usado previamente
  Future<bool> validateTicket(String qrCodeData) async {
    try {
      debugPrint('🔍 Validating ticket: $qrCodeData');
      
      // El QR contiene el ID del ticket directamente
      final ticketId = qrCodeData.trim();
      
      // Buscar el ticket en Supabase
      final response = await _supabase.client
          .from('tickets')
          .select()
          .eq('id', ticketId)
          .maybeSingle();

      if (response == null) {
        debugPrint('❌ Ticket not found in database');
        return false;
      }

      final ticket = TicketModel.fromJson(response);
      
      debugPrint('📋 Ticket found: ${ticket.ticketType}');
      debugPrint('💳 Payment status: ${ticket.paymentStatus.name}');
      debugPrint('✓ Is validated: ${ticket.isValidated}');
      
      // Validar condiciones
      final isValid = !ticket.isValidated && 
                      ticket.paymentStatus == PaymentStatus.approved;
      
      if (!isValid) {
        if (ticket.isValidated) {
          debugPrint('❌ Ticket already used at: ${ticket.validatedAt}');
        }
        if (ticket.paymentStatus != PaymentStatus.approved) {
          debugPrint('❌ Payment not approved: ${ticket.paymentStatus.name}');
        }
      }
      
      return isValid;
    } catch (e) {
      debugPrint('❌ Ticket validation failed: $e');
      return false;
    }
  }

  /// Marca un ticket como usado en la base de datos
  Future<void> markTicketAsUsed(String ticketId) async {
    try {
      debugPrint('📝 Marking ticket as used: $ticketId');
      
      final now = DateTime.now().toIso8601String();
      
      // Actualizar directamente en Supabase
      await _supabase.client
          .from('tickets')
          .update({
            'is_validated': true,
            'validated_at': now,
            'updated_at': now,
          })
          .eq('id', ticketId);
      
      debugPrint('✅ Ticket marked as used on Supabase');
      
      // También actualizar caché local si existe
      if (_prefs == null) await init();
      final allTickets = await _getAllTickets();
      final ticketIndex = allTickets.indexWhere((t) => t.id == ticketId);
      if (ticketIndex != -1) {
        final ticket = allTickets[ticketIndex];
        final updated = ticket.copyWith(
          isValidated: true,
          validatedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _saveTicket(updated);
        debugPrint('📦 Local cache updated');
      }
    } catch (e) {
      debugPrint('❌ Failed to mark ticket as used: $e');
      throw Exception('Failed to mark ticket as used: $e');
    }
  }

  Future<void> _saveTicket(TicketModel ticket) async {
    final allTickets = await _getAllTickets();
    allTickets.removeWhere((t) => t.id == ticket.id);
    allTickets.add(ticket);
    final ticketsJson = allTickets.map((t) => t.toJson()).toList();
    await _prefs!.setString(allTicketsKey, jsonEncode(ticketsJson));
  }

  Future<List<TicketModel>> _getAllTickets() async {
    final ticketsJson = _prefs?.getString(allTicketsKey);
    if (ticketsJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(ticketsJson);
      return decoded.map((json) => TicketModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to parse tickets: $e');
      return [];
    }
  }
}
