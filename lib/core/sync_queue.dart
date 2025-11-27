import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SyncOperation { create, update, delete }

class SyncQueueItem {
  final String id;
  final String tableName;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;
  final String? error;

  SyncQueueItem({
    required this.id,
    required this.tableName,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.error,
  });

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) => SyncQueueItem(
    id: json['id'] as String,
    tableName: json['tableName'] as String,
    operation: SyncOperation.values.firstWhere((e) => e.name == json['operation']),
    data: json['data'] as Map<String, dynamic>,
    createdAt: DateTime.parse(json['createdAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
    error: json['error'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tableName': tableName,
    'operation': operation.name,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'error': error,
  };

  SyncQueueItem copyWith({
    String? id,
    String? tableName,
    SyncOperation? operation,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? error,
  }) =>
      SyncQueueItem(
        id: id ?? this.id,
        tableName: tableName ?? this.tableName,
        operation: operation ?? this.operation,
        data: data ?? this.data,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        error: error ?? this.error,
      );
}

class SyncQueueManager {
  static const String queueKey = 'sync_queue';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> addToQueue({
    required String id,
    required String tableName,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    if (_prefs == null) await init();

    final item = SyncQueueItem(
      id: id,
      tableName: tableName,
      operation: operation,
      data: data,
      createdAt: DateTime.now(),
    );

    final queue = await getPendingItems();
    queue.removeWhere((i) => i.id == id);
    queue.add(item);
    await _saveQueue(queue);
    debugPrint('✅ Added to sync queue: $tableName - ${operation.name}');
  }

  Future<List<SyncQueueItem>> getPendingItems() async {
    if (_prefs == null) await init();
    final queueJson = _prefs!.getString(queueKey);
    if (queueJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(queueJson);
      return decoded.map((json) => SyncQueueItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('⚠️ Failed to parse sync queue: $e');
      return [];
    }
  }

  Future<void> markAsProcessed(String id) async {
    if (_prefs == null) await init();
    final queue = await getPendingItems();
    queue.removeWhere((item) => item.id == id);
    await _saveQueue(queue);
    debugPrint('✅ Removed from sync queue: $id');
  }

  Future<void> incrementRetry(String id, String error) async {
    if (_prefs == null) await init();
    final queue = await getPendingItems();
    final itemIndex = queue.indexWhere((item) => item.id == id);
    if (itemIndex != -1) {
      final updated = queue[itemIndex].copyWith(
        retryCount: queue[itemIndex].retryCount + 1,
        error: error,
      );
      queue[itemIndex] = updated;
      await _saveQueue(queue);
      debugPrint('⚠️ Retry count increased for $id: ${updated.retryCount}');
    }
  }

  Future<void> clearQueue() async {
    if (_prefs == null) await init();
    await _prefs!.remove(queueKey);
    debugPrint('🗑️ Sync queue cleared');
  }

  Future<int> get pendingCount async {
    final queue = await getPendingItems();
    return queue.length;
  }

  Future<void> _saveQueue(List<SyncQueueItem> queue) async {
    final queueJson = queue.map((item) => item.toJson()).toList();
    await _prefs!.setString(queueKey, jsonEncode(queueJson));
  }
}
