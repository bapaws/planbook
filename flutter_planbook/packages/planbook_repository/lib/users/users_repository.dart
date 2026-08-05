import 'dart:async';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:planbook_api/planbook_api.dart' as api;
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/planbook_core.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const kUserId = '__supabase_user_id__';

class UsersRepository {
  /// {@macro planbook_repository}
  UsersRepository._({
    required api.AppDatabase db,
    required SharedPreferences sp,
  }) : _db = db,
       _sp = sp;

  SupabaseClient? get _supabase => AppSupabase.client;
  final api.AppDatabase _db;
  final SharedPreferences _sp;

  static late UsersRepository? _instance;
  static UsersRepository get instance => _instance!;

  Session? get session => _supabase?.auth.currentSession;

  bool get isExpired => session?.isExpired ?? true;

  /// 是否已安装微信。
  Future<bool> isWeChatInstalled() async {
    return AppSupabase.instance.isWeChatInstalled();
  }

  api.UserEntity? get user {
    final user = _supabase?.auth.currentUser;
    if (user == null) return null;
    return api.UserEntity(
      user: user,
      profile: userProfile,
    );
  }

  /// Receive a notification every time an auth event happens.
  Stream<AuthState?> get onAuthStateChange =>
      AppSupabase.instance.onAuthStateChange;

  late final _onUserProfileChangeController =
      BehaviorSubject<UserProfileEntity?>();
  Stream<UserProfileEntity?> get onUserProfileChange =>
      _onUserProfileChangeController.stream;
  UserProfileEntity? get userProfile => _onUserProfileChangeController.hasValue
      ? _onUserProfileChangeController.value
      : null;

  // ---- entitlements 行内存缓存 ----
  // splash / 活动页 / isPremium 判定等路径会反复读 entitlement，
  // 每次都走 PostgREST 会拖慢启动并在弱网下抖动，故加短 TTL 缓存。
  // TTL 取 2 分钟：足够覆盖一次页面访问内的多次判定；同时支付/恢复链路
  // 都会走 getUserProfile(force: true) 强制刷新，退款/过期最坏 2 分钟自愈。
  static const _entitlementCacheTtl = Duration(minutes: 2);

  /// 缓存的行；null 表示「查过但该用户没有 entitlement 行」
  ({String? productId, DateTime? expiresAt, String? provider})?
  _entitlementCache;

  /// 缓存归属的用户 id：切换账号后旧缓存不得串用
  String? _entitlementCacheUserId;
  DateTime? _entitlementCacheAt;

  /// 是否已完成过一次查询（区分「没查过」与「查了但没行」）
  bool _entitlementCacheLoaded = false;

  Stream<UserEntity?> get onUserEntityChange {
    return CombineLatestStream.combine2(
      onAuthStateChange.map(
        (authState) => authState?.session?.user,
      ),
      _onUserProfileChangeController.stream,
      (User? user, UserProfileEntity? profile) =>
          user == null ? null : UserEntity(user: user, profile: profile),
    );
  }

  bool get isFirstLaunch => userProfile?.lastLaunchAppAt == null;

  static const kUserProfile = '__user_profile_cache__';

  static Future<void> initialize({
    required api.AppDatabase db,
    required SharedPreferences sp,
  }) async {
    _instance = UsersRepository._(
      db: db,
      sp: sp,
    );
    await _instance!.getUserProfile();
    // 同步当前 Supabase 用户 id 到 widget 共享存储。
    // 登录 / 注销链路本身已经在每次状态变更时写入这里，但冷启动时
    // session 可能是从磁盘恢复的（不会走 signIn 系列方法），此时 widget
    // 端拿到的 id 可能是上次会话遗留的或为空——这里做一次权威同步。
    await _instance!._syncCurrentUserIdToWidget();
  }

  /// 把 [_supabase?.auth.currentUser?.id] 写到 widget 共享存储；
  /// 用户已注销时清掉对应键。
  Future<void> _syncCurrentUserIdToWidget() async {
    final id = _supabase?.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      await AppHomeWidget.removeWidgetData(kUserId);
    } else {
      await AppHomeWidget.saveWidgetData(kUserId, id);
    }
  }

  Future<AuthResponse?> signUp({
    required String name,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    late final AuthResponse? response;
    if (EmailValidator.validate(name)) {
      response = await AppSupabase.instance.signUp(
        email: name,
        password: password,
        data: data,
      );
    } else {
      response = await AppSupabase.instance.signUp(
        phone: name,
        password: password,
        data: data,
      );
    }
    if (response?.user != null) {
      await AppHomeWidget.saveWidgetData(
        kUserId,
        response!.user!.id,
      );
    }
    return response;
  }

  Future<AuthResponse?> signInWithPassword({
    required String password,
    String? email,
    String? phone,
    String? captchaToken,
  }) async {
    final response = await AppSupabase.instance.signInWithPassword(
      email: email,
      phone: phone,
      password: password,
      captchaToken: captchaToken,
    );
    if (response?.user != null) {
      await AppHomeWidget.saveWidgetData(
        kUserId,
        response!.user!.id,
      );
      await getUserProfile();
    }
    return response;
  }

  Future<void> signInWithOtp({
    String? email,
    String? phone,
    String? emailRedirectTo,
    bool? shouldCreateUser,
    Map<String, dynamic>? data,
    String? captchaToken,
  }) async {
    await AppSupabase.instance.signInWithOtp(
      email: email,
      phone: phone,
      emailRedirectTo: emailRedirectTo,
      shouldCreateUser: shouldCreateUser,
      data: data,
      captchaToken: captchaToken,
    );
  }

  Future<void> resetPasswordForEmail(
    String email, {
    String? redirectTo,
  }) async {
    await _supabase?.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectTo,
    );
  }

  Future<AuthResponse?> verifyOTP({
    required OtpType type,
    String? email,
    String? phone,
    String? token,
    String? redirectTo,
    String? captchaToken,
    String? tokenHash,
  }) async {
    final response = await AppSupabase.instance.verifyOTP(
      type: type,
      email: email,
      phone: phone,
      token: token,
      redirectTo: redirectTo,
      captchaToken: captchaToken,
      tokenHash: tokenHash,
    );
    if (response?.user != null) {
      await AppHomeWidget.saveWidgetData(
        kUserId,
        response!.user!.id,
      );
      await getUserProfile();
    }
    return response;
  }

  Future<ResendResponse?> resend({
    required OtpType type,
    String? email,
    String? phone,
    String? emailRedirectTo,
    String? captchaToken,
  }) async {
    await _supabase?.auth.resend(
      type: type,
      email: email,
      phone: phone,
      emailRedirectTo: emailRedirectTo,
      captchaToken: captchaToken,
    );
    return null;
  }

  Future<AuthResponse?> signInWithApple() async {
    final response = await AppSupabase.instance.signInWithApple();
    if (response?.user != null) {
      await AppHomeWidget.saveWidgetData(
        kUserId,
        response!.user!.id,
      );
      await getUserProfile();
    }
    return response;
  }

  Future<AuthResponse?> signInWithGoogle() async {
    final response = await AppSupabase.instance.signInWithGoogle();
    if (response?.user != null) {
      await AppHomeWidget.saveWidgetData(
        kUserId,
        response!.user!.id,
      );
      await getUserProfile();
    }
    return response;
  }

  Future<AuthResponse?> signInWithWeChat() async {
    final response = await AppSupabase.instance.signInWithWeChat();
    if (response?.user != null) {
      await AppHomeWidget.saveWidgetData(
        kUserId,
        response!.user!.id,
      );
      await getUserProfile();
    }
    return response;
  }

  Future<void> linkWeChat() async {
    await AppSupabase.instance.linkWeChat();
    await getUserProfile(force: true);
  }

  Future<UserEntity?> updateUser({
    String? email,
    String? phone,
    String? password,
    String? nonce,
  }) async {
    final response = await _supabase?.auth.updateUser(
      UserAttributes(
        email: email,
        phone: phone,
        password: password,
        nonce: nonce,
      ),
    );
    if (response?.user == null) {
      throw Exception('Failed to update user');
    }
    return UserEntity(
      user: response!.user!,
      profile: userProfile,
    );
  }

  Future<void> logout() async {
    await _supabase?.auth.signOut();
    await _sp.remove(kUserProfile);
    _invalidateEntitlementCache();
    _onUserProfileChangeController.add(null);
    await AppHomeWidget.removeWidgetData(kUserId);
  }

  Future<void> deleteUser() async {
    try {
      final response = await _supabase?.functions.invoke('delete-account');
      if (response?.status == 200) {
        await _supabase?.auth.signOut();
        await _sp.remove(kUserProfile);
        _invalidateEntitlementCache();
        _onUserProfileChangeController.add(null);
        await AppHomeWidget.removeWidgetData(kUserId);
      } else {
        throw Exception('Failed to delete user');
      }
    } on Exception catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }

    await _db.transaction(() async {
      await (_db.delete(
        _db.tasks,
      )..where((t) => t.userId.equals(user!.id))).go();
      await (_db.delete(
        _db.notes,
      )..where((t) => t.userId.equals(user!.id))).go();
      await (_db.delete(
        _db.tags,
      )..where((t) => t.userId.equals(user!.id))).go();
      await (_db.delete(
        _db.noteTags,
      )..where((t) => t.userId.equals(user!.id))).go();
      await (_db.delete(
        _db.taskTags,
      )..where((t) => t.userId.equals(user!.id))).go();
      await (_db.delete(
        _db.taskActivities,
      )..where((t) => t.userId.equals(user!.id))).go();
      await (_db.delete(
        _db.taskOccurrences,
      )..where((t) => t.taskId.equals(user!.id))).go();
    });
  }

  Future<UserProfileEntity?> getUserProfile({bool force = false}) async {
    if (user == null) return null;

    final cache = await _getUserProfileFromCache();
    if (cache == null || force) {
      final response = await _getUserProfileFromSupabase();
      if (response != null) {
        _onUserProfileChangeController.add(response);
        return response;
      }
    } else {
      _onUserProfileChangeController.add(cache);
      // 后台刷新仅同步缓存，PostgREST 瞬时失败不应冒泡为未捕获异步错误
      unawaited(
        _getUserProfileFromSupabase().catchError((Object e) {
          if (kDebugMode) print('后台刷新 profile 失败: $e');
          return null;
        }),
      );
      return cache;
    }
    return null;
  }

  Future<UserProfileEntity?> _getUserProfileFromCache() async {
    final cache = _sp.getString(kUserProfile);
    if (cache == null) return null;
    return UserProfileEntity.fromJson(cache);
  }

  Future<UserProfileEntity?> _getUserProfileFromSupabase() async {
    var response = await _supabase
        ?.from('user_profiles')
        .select()
        .eq('id', user!.id)
        .maybeSingle();
    if (response == null) {
      response = await _supabase
          ?.from('user_profiles')
          .insert({
            'id': user!.id,
          })
          .select()
          .maybeSingle();
      if (response == null) return null;
    }
    final entity = UserProfileEntity.fromMap(response);
    // 用 entitlements 覆盖 profile 中的权益字段（新真相源；行存在则以之为准）。
    // 强制刷新：profile 刷新（含支付/恢复后的 force 刷新）必须同步更新缓存，
    // 否则合并出来的 profile 与后续 getActiveEntitlementProductId 会不一致。
    final entitlement = await _getEntitlementRow(force: true);
    // 注意 copyWith 的 ?? 语义：entitlement 字段为 null 时保留 profile 原值。
    // entitlement 行以 productId 非空为常态；且行存在时会员判定直接读行
    // （getActiveEntitlementProductId），不经过该合并结果，差异无实害。
    final merged = entitlement == null
        ? entity
        : entity.copyWith(
            productId: entitlement.productId,
            expiresAt: entitlement.expiresAt,
          );
    unawaited(_sp.setString(kUserProfile, merged.toJson()));
    _onUserProfileChangeController.add(merged);
    return merged;
  }

  /// 清空 entitlement 缓存（登出/注销时调用；切账号主要靠 uid 隔离兜底）
  void _invalidateEntitlementCache() {
    _entitlementCache = null;
    _entitlementCacheUserId = null;
    _entitlementCacheAt = null;
    _entitlementCacheLoaded = false;
  }

  Future<({String? productId, DateTime? expiresAt, String? provider})?>
  _getEntitlementRow({bool force = false}) async {
    final uid = user?.id;
    if (uid == null) return null;
    // 命中有效缓存直接返回（uid 必须一致，防止切账号串数据）
    final cachedAt = _entitlementCacheAt;
    if (!force &&
        _entitlementCacheLoaded &&
        _entitlementCacheUserId == uid &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _entitlementCacheTtl) {
      return _entitlementCache;
    }
    try {
      final row = await _supabase
          ?.from('entitlements')
          .select('product_id, expires_at, provider')
          .eq('user_id', uid)
          .maybeSingle();
      final parsed = row == null
          ? null
          : (
              productId: row['product_id'] as String?,
              expiresAt: row['expires_at'] != null
                  ? DateTime.parse(row['expires_at'] as String)
                  : null,
              provider: row['provider'] as String?,
            );
      // 查询成功即刷新缓存（包括「没有行」这一结果）
      _entitlementCache = parsed;
      _entitlementCacheUserId = uid;
      _entitlementCacheAt = DateTime.now();
      _entitlementCacheLoaded = true;
      return parsed;
    } on Exception catch (e) {
      if (kDebugMode) {
        print('get entitlements error: $e');
      }
      // 离线兜底：网络失败时回退到本用户的缓存副本（即使已过 TTL），
      // 避免弱网/离线下付费用户瞬时掉会员；无缓存才返回 null
      if (_entitlementCacheLoaded && _entitlementCacheUserId == uid) {
        return _entitlementCache;
      }
      return null;
    }
  }

  /// 从 planbook.entitlements 读取当前有效商品 id（权威来源）
  ///
  /// [excludeProviders]：海外 RC 已过期时，fallback 应排除 `revenuecat`，
  /// 避免服务端陈旧 RC 行盖过真实商店状态。
  ///
  /// 离线时 [_getEntitlementRow] 会回退到本用户的缓存副本（含 provider，
  /// 可正常参与排除判定）；只有从未成功查询过时才会走到 profile 回退。
  Future<String?> getActiveEntitlementProductId({
    Set<String> excludeProviders = const {},
  }) async {
    if (user == null) return null;
    final row = await _getEntitlementRow();
    if (row == null) {
      // 迁移窗口/从未查到行：回退 profile（无 provider，无法按渠道排除，
      // 为避免陈旧 RC 数据盖过真实商店状态，有排除需求时直接返回 null）
      if (excludeProviders.isNotEmpty) return null;
      final profile = await getUserProfile();
      final productId = profile?.productId;
      if (productId == null) return null;
      if (productId.toLowerCase().contains('lifetime')) return productId;
      final expiresAt = profile?.expiresAt;
      if (expiresAt == null || expiresAt.isBefore(DateTime.now())) return null;
      return productId;
    }
    final provider = row.provider;
    if (provider != null && excludeProviders.contains(provider)) {
      return null;
    }
    final productId = row.productId;
    if (productId == null) return null;
    if (productId.toLowerCase().contains('lifetime')) return productId;
    final expiresAt = row.expiresAt;
    if (expiresAt == null || expiresAt.isBefore(DateTime.now())) return null;
    return productId;
  }

  Future<void> updateUserProfile({
    DateTime? lastLaunchAppAt,
    int? launchCount,
    String? username,
    String? avatar,
    UserGender? gender,
    DateTime? birthday,
  }) async {
    if (!_onUserProfileChangeController.hasValue) return;

    final entity = _onUserProfileChangeController.value;
    if (entity == null) return;

    final newEntity = entity.copyWith(
      username: username,
      avatar: avatar,
      gender: gender,
      birthday: birthday,
    );
    unawaited(_sp.setString(kUserProfile, newEntity.toJson()));
    _onUserProfileChangeController.add(newEntity);
    await _supabase
        ?.from('user_profiles')
        .update({
          if (lastLaunchAppAt != null)
            'last_launch_app_at': lastLaunchAppAt.toUtc().toIso8601String(),
          if (launchCount != null) 'launch_count': launchCount,
          if (username != null) 'username': username,
          if (avatar != null) 'avatar': avatar,
          if (gender != null) 'gender': gender.name,
          if (birthday != null) 'birthday': birthday.toUtc().toIso8601String(),
        })
        .eq('id', entity.id);
  }

  /// 合并写入某年的日记封面路径（`user_profiles.cover_by_year`）
  Future<void> updateJournalCoverForYear({
    required int year,
    required String coverPath,
  }) async {
    if (_supabase?.auth.currentUser == null) {
      throw StateError('用户未登录，无法保存年度封面');
    }
    var entity = userProfile;
    entity ??= await getUserProfile(force: true);
    if (entity == null) {
      throw StateError('用户资料未就绪，无法保存年度封面');
    }
    final yearKey = '$year';
    final merged = Map<String, String>.from(entity.coverByYear)
      ..[yearKey] = coverPath;
    final now = DateTime.now().toUtc();
    final newEntity = entity.copyWith(
      coverByYear: merged,
      updatedAt: now,
    );
    unawaited(_sp.setString(kUserProfile, newEntity.toJson()));
    _onUserProfileChangeController.add(newEntity);
    await _supabase
        ?.from('user_profiles')
        .update({
          'cover_by_year': merged,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', entity.id);
  }

  /// 保存四象限自定义配置到 `user_profiles.quadrant_config`
  Future<void> updateQuadrantConfig(
    List<QuadrantConfigEntity> configs,
  ) async {
    if (_supabase?.auth.currentUser == null) return;
    var entity = userProfile;
    entity ??= await getUserProfile(force: true);
    if (entity == null) return;
    final now = DateTime.now().toUtc();
    final newEntity = entity.copyWith(
      quadrantConfig: configs,
      updatedAt: now,
    );
    unawaited(_sp.setString(kUserProfile, newEntity.toJson()));
    _onUserProfileChangeController.add(newEntity);
    await _supabase
        ?.from('user_profiles')
        .update({
          'quadrant_config': configs.map((e) => e.toJson()).toList(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', entity.id);
  }
}
