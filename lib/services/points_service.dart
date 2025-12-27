import 'dart:convert';
import 'package:comic_fest/core/supabase_service.dart';
import 'package:comic_fest/core/sync_queue.dart';
import 'package:comic_fest/models/points_transaction_model.dart';
import 'package:comic_fest/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:comic_fest/models/order_model.dart'; // Import OrderModel
import 'package:comic_fest/models/product_model.dart';
import 'package:uuid/uuid.dart';

class PointsService {
  static const String allTransactionsKey = 'all_transactions';
  SharedPreferences? _prefs;
  final SupabaseService _supabase = SupabaseService.instance;
  final SyncQueueManager _syncQueue = SyncQueueManager();
  final UserService _userService = UserService();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _syncQueue.init();
  }

  Future<void> earnPoints({
    required int amount,
    required String reason,
  }) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    final transaction = PointsTransactionModel(
      id: const Uuid().v4(),
      userId: userId,
      amount: amount,
      type: TransactionType.earn,
      reason: reason,
      createdAt: DateTime.now(),
      synced: false,
    );

    await _saveTransaction(transaction);
    await _userService.updatePoints(amount);

    await _syncQueue.addToQueue(
      id: transaction.id,
      tableName: 'points_log',
      operation: SyncOperation.create,
      data: {
        'user_id': userId,
        'points_change': amount,
        'reason': reason,
        'type': 'earn',
      },
    );

    debugPrint('✅ Earned $amount points: $reason');
  }

  Future<void> spendPoints({
    required int amount,
    required String reason,
  }) async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    final currentUser = await _userService.getCurrentUser();
    if (currentUser == null || currentUser.points < amount) {
      throw Exception('Insufficient points');
    }

    final transaction = PointsTransactionModel(
      id: const Uuid().v4(),
      userId: userId,
      amount: amount,
      type: TransactionType.spend,
      reason: reason,
      createdAt: DateTime.now(),
      synced: false,
    );

    await _saveTransaction(transaction);
    await _userService.updatePoints(-amount);

    await _syncQueue.addToQueue(
      id: transaction.id,
      tableName: 'points_log',
      operation: SyncOperation.create,
      data: {
        'user_id': userId,
        'points_change': -amount,
        'reason': reason,
        'type': 'spend',
      },
    );

    debugPrint('✅ Spent $amount points: $reason');
  }

  /// Fetches available rewards (products with points_price > 0)
  Future<List<ProductModel>> fetchRewards() async {
    try {
      final response = await _supabase.client
          .from('products')
          .select()
          .gt('points_price', 0)
          .gt('stock', 0)
          .eq('is_active', true)
          .order('points_price', ascending: true);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching rewards: $e');
      return [];
    }
  }

  /// Redeems a reward using the secure SQL function
  Future<Map<String, dynamic>> redeemReward(String productId) async {
    if (_prefs == null) await init();
    final userId = _supabase.userId;
    if (userId == null) throw Exception('No authenticated user');

    try {
      // Call the secure stored procedure 'redeem_reward'
      final response = await _supabase.client.rpc(
        'redeem_reward',
        params: {
          'p_user_id': userId,
          'p_product_id': productId,
        },
      );

      // Force update user points locally to reflect change immediately
      if (response['success'] == true) {
        final newPoints = response['new_points'] as int;
        await _userService.fetchUserProfile(); // Refresh full profile to be safe
      }

      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error redeeming reward: $e');
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }


      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  /// Fetches user's redemption history (orders)
  Future<List<OrderModel>> fetchMyOrders() async {
    final userId = _supabase.userId;
    if (userId == null) return [];

    try {
      final response = await _supabase.client
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error fetching orders: $e');
      return [];
    }
  }

  Future<List<PointsTransactionModel>> getTransactionHistory() async {
    if (_prefs == null) await init();

    final userId = _supabase.userId;
    if (userId == null) return [];

    final allTransactions = await _getAllTransactions();
    final localTransactions = allTransactions
        .where((t) => t.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    try {
      final response = await _supabase.client
          .from('points_log')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final remoteTransactions = (response as List).map((json) {
        return PointsTransactionModel(
          id: json['id'] as String,
          userId: json['user_id'] as String,
          amount: (json['points_change'] as int).abs(),
          type: json['type'] == 'earn' || (json['points_change'] as int) > 0
              ? TransactionType.earn
              : TransactionType.spend,
          reason: json['reason'] as String,
          createdAt: json['created_at'] is String
              ? DateTime.parse(json['created_at'])
              : (json['created_at'] as DateTime),
          synced: true,
        );
      }).toList();

      for (final transaction in remoteTransactions) {
        await _saveTransaction(transaction);
      }

      debugPrint('✅ Transactions synced from Supabase');
      return remoteTransactions;
    } catch (e) {
      debugPrint('⚠️ Using cached transactions: $e');
      return localTransactions;
    }
  }

  Future<void> syncPendingTransactions() async {
    if (_prefs == null) await init();

    final pendingItems = await _syncQueue.getPendingItems();
    final pointsTransactions = pendingItems
        .where((item) => item.tableName == 'points_log')
        .toList();

    for (final item in pointsTransactions) {
      try {
        await _supabase.client
            .from('points_log')
            .insert(item.data);

        final allTransactions = await _getAllTransactions();
        final transactionIndex = allTransactions.indexWhere((t) => t.id == item.id);
        if (transactionIndex != -1) {
          allTransactions[transactionIndex] = allTransactions[transactionIndex].copyWith(synced: true);
          final transactionsJson = allTransactions.map((t) => t.toJson()).toList();
          await _prefs!.setString(allTransactionsKey, jsonEncode(transactionsJson));
        }

        await _syncQueue.markAsProcessed(item.id);
        debugPrint('✅ Synced transaction: ${item.id}');
      } catch (e) {
        await _syncQueue.incrementRetry(item.id, e.toString());
        debugPrint('❌ Failed to sync transaction: $e');
      }
    }
  }

  Future<void> _saveTransaction(PointsTransactionModel transaction) async {
    final allTransactions = await _getAllTransactions();
    allTransactions.removeWhere((t) => t.id == transaction.id);
    allTransactions.add(transaction);
    final transactionsJson = allTransactions.map((t) => t.toJson()).toList();
    await _prefs!.setString(allTransactionsKey, jsonEncode(transactionsJson));
  }

  Future<List<PointsTransactionModel>> _getAllTransactions() async {
    final transactionsJson = _prefs?.getString(allTransactionsKey);
    if (transactionsJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(transactionsJson);
      return decoded.map((json) => PointsTransactionModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to parse transactions: $e');
      return [];
    }
  }
}
