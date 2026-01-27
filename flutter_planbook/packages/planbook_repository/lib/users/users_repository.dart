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
    await AppHomeWidget.removeWidgetData(kUserId);
  }

  Future<void> deleteUser() async {
    try {
      final response = await _supabase?.functions.invoke('delete-account');
      if (response?.status == 200) {
        await _supabase?.auth.signOut();
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

  Future<UserProfileEntity?> getUserProfile() async {
    if (user == null) return null;

    final cache = await _getUserProfileFromCache();
    if (cache == null) {
      final response = await _getUserProfileFromSupabase();
      if (response != null) {
        _onUserProfileChangeController.add(response);
        return response;
      }
    } else {
      _onUserProfileChangeController.add(cache);
      unawaited(_getUserProfileFromSupabase());
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
    unawaited(_sp.setString(kUserProfile, entity.toJson()));
    _onUserProfileChangeController.add(entity);
    return entity;
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
}
