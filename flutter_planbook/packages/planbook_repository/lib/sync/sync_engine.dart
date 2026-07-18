import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:database_planbook_api/sync/outbox_api.dart';

/// 统一同步引擎，负责排空 Outbox。
///
/// 生命周期由 bootstrap 管理（应用启动时初始化并 start，应用销毁时 dispose）。
/// AppBloc 负责监听前后台切换并触发同步。
class SyncEngine {
  SyncEngine({
    required OutboxApi outboxApi,
    required SupabaseClient? supabase,
    Connectivity? connectivity,
    InternetConnectionChecker? connectionChecker,
  }) : _outboxApi = outboxApi,
       _supabase = supabase,
       _connectivity = connectivity ?? Connectivity(),
       _connectionChecker =
           connectionChecker ?? InternetConnectionChecker.instance;

  final OutboxApi _outboxApi;
  final SupabaseClient? _supabase;
  final Connectivity _connectivity;
  final InternetConnectionChecker _connectionChecker;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  bool _isProcessing = false;

  String? get _userId => _supabase?.auth.currentUser?.id;

  /// 启动监听：网络变化 + 定时兜底
  void start() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any(
        (r) => r == ConnectivityResult.wifi || r == ConnectivityResult.mobile,
      );
      if (hasConnection) {
        _triggerSync();
      }
    });

    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _triggerSync();
    });
  }

  /// 外部手动触发（如用户下拉刷新、登录成功、前后台切换）
  void triggerSync() => _triggerSync();

  void _triggerSync() {
    if (_isProcessing) return;
    if (_userId == null) return;
    unawaited(_processOutbox());
  }

  /// 核心：批量处理 Outbox
  Future<void> _processOutbox() async {
    _isProcessing = true;
    try {
      final hasInternet = await _connectionChecker.hasConnection;
      if (!hasInternet) return;

      final pending = await _outboxApi.getPending(limit: 50);
      if (pending.isEmpty) return;

      for (final item in pending) {
        try {
          await syncSingle(item);
          await _outboxApi.markSynced(item.id);
        } on PostgrestException catch (e) {
          final errorMsg = e.message ?? 'Supabase error';
          debugPrint(
            'SyncEngine: sync failed for ${item.targetTable}/${item.recordId}: $errorMsg',
          );
          final newRetryCount = item.retryCount + 1;
          await _outboxApi.markFailed(
            outboxId: item.id,
            error: errorMsg,
            retryCount: newRetryCount,
          );
          // 4xx 客户端错误标记为死信，不再重试
          if (e.code != null && e.code!.startsWith('4')) {
            await _outboxApi.markSynced(item.id);
            debugPrint('SyncEngine: dead letter ${item.recordId}');
          }
        } on Exception catch (e) {
          debugPrint('SyncEngine: unexpected error: $e');
          await _outboxApi.markFailed(
            outboxId: item.id,
            error: e.toString(),
            retryCount: item.retryCount + 1,
          );
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 单条同步逻辑（@visibleForTesting）
  @visibleForTesting
  Future<void> syncSingle(SyncOutboxData item) async {
    if (_supabase == null) throw Exception('Supabase not initialized');

    final payload = jsonDecode(item.payload) as Map<String, dynamic>;
    payload['user_id'] = _userId;

    final table = _supabase!.from(item.targetTable);

    switch (item.operation) {
      case 'insert':
      case 'update':
        await table.upsert([payload], onConflict: 'id');
      case 'delete':
        await table
            .update({
              'deleted_at': DateTime.now().toIso8601String(),
            })
            .eq('id', item.recordId);
      case 'replace_associations':
        final parentId = payload['parent_id'] as String?;
        final associations = payload['associations'] as List<dynamic>?;
        if (parentId == null) {
          throw Exception('replace_associations missing parent_id');
        }
        final parentColumn = '${item.targetTable.split('_').first}_id';
        await table
            .update({
              'deleted_at': DateTime.now().toIso8601String(),
            })
            .eq(parentColumn, parentId);
        if (associations != null && associations.isNotEmpty) {
          await table.insert(associations.cast<Map<String, dynamic>>());
        }
    }
  }

  /// 停止引擎
  void dispose() {
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
  }
}
