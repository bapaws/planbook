import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:fluwx/fluwx.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 微信开放平台 App ID。
/// 优先通过 `--dart-define=WECHAT_APP_ID=...` 注入；未注入时使用默认值。
const _kWeChatAppId = String.fromEnvironment(
  'WECHAT_APP_ID',
  defaultValue: 'wx43f0daa78129a486',
);

/// iOS universal link，微信 SDK 注册需要。
const _kWeChatUniversalLink = String.fromEnvironment(
  'WECHAT_UNIVERSAL_LINK',
  defaultValue: 'https://bapaws.github.io/',
);

class AppSupabase {
  AppSupabase._();

  static final AppSupabase instance = AppSupabase._();

  static Supabase? _supabase;
  static SupabaseClient? get client => _supabase?.client;

  static User? get user => _supabase?.client.auth.currentUser;

  late StreamSubscription<AuthState>? _onAuthStateChangeSubscription;

  late final _onAuthStateChangeController = BehaviorSubject<AuthState?>();
  Stream<AuthState?> get onAuthStateChange =>
      _onAuthStateChangeController.stream;

  final _fluwx = Fluwx();

  static Future<void> initialize() async {
    if (_supabase != null) return;
    Supabase supabase;
    if (kDebugMode) {
      supabase = await Supabase.initialize(
        url: 'https://rejmbcwozhohcxfvquus.supabase.co',
        anonKey: 'sb_publishable_DHbbqiD_EzFMRy-PFJVc8A_zwLnqog3',
        postgrestOptions: const PostgrestClientOptions(schema: 'planbook'),
      );
    } else {
      supabase = await Supabase.initialize(
        url: 'https://supa.bapaws.top',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiY'
            'XNlIiwiaWF0IjoxNzYyNzA0MDAwLCJleHAiOj'
            'E5MjA0NzA0MDB9.'
            'TKP8eEkch5MSBWn4_Qzz_pYTZWnssVUU-YcTgn_riw8',
        postgrestOptions: const PostgrestClientOptions(schema: 'planbook'),
      );
    }
    _supabase = supabase;

    instance._onAuthStateChangeSubscription = _supabase
        ?.client
        .auth
        .onAuthStateChange
        .listen(
          (authState) {
            instance._onAuthStateChangeController.add(authState);
          },
          onError: (Object error) {
            instance._onAuthStateChangeController.addError(error);
          },
        );

    // 注册微信 SDK，失败不应阻塞启动。
    await instance.registerWeChat();
  }

  void dispose() {
    _onAuthStateChangeSubscription?.cancel();
  }

  Future<AuthResponse?> signUp({
    required String password,
    String? email,
    String? phone,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    await initialize();
    return await _supabase?.client.auth.signUp(
      email: email,
      phone: phone,
      password: password,
      data: {
        ...?data,
        'com.bapaws.planbook': true,
        'planbook': true,
      },
      captchaToken: captchaToken,
      channel: channel,
    );
  }

  Future<AuthResponse?> signInWithPassword({
    required String password,
    String? email,
    String? phone,
    String? captchaToken,
  }) async {
    return await _supabase?.client.auth.signInWithPassword(
      email: email,
      phone: phone,
      password: password,
      captchaToken: captchaToken,
    );
  }

  Future<void> signInWithOtp({
    String? email,
    String? phone,
    String? emailRedirectTo,
    bool? shouldCreateUser,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    await _supabase?.client.auth.signInWithOtp(
      email: email,
      phone: phone,
      emailRedirectTo: emailRedirectTo,
      shouldCreateUser: shouldCreateUser,
      data: {...?data, 'com.bapaws.planbook': true, 'planbook': true},
      captchaToken: captchaToken,
      channel: channel,
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
    return await _supabase?.client.auth.verifyOTP(
      email: email,
      phone: phone,
      token: token,
      type: type,
      redirectTo: redirectTo,
      captchaToken: captchaToken,
      tokenHash: tokenHash,
    );
  }

  /// Performs Apple sign in on iOS or macOS
  Future<AuthResponse?> signInWithApple() async {
    if (_supabase == null) return null;
    final rawNonce = _supabase!.client.auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );
    final idToken = credential.identityToken;
    if (idToken == null) {
      throw const AuthException(
        'Could not find ID Token from generated credential.',
      );
    }
    final authResponse = await _supabase?.client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
    // Apple only provides the user's full name on the first sign-in
    // Save it to user metadata if available
    final data = <String, dynamic>{
      'com.bapaws.planbook': true,
      'planbook': true,
    };
    if (credential.givenName != null || credential.familyName != null) {
      final nameParts = <String>[];
      if (credential.givenName != null) nameParts.add(credential.givenName!);
      if (credential.familyName != null) nameParts.add(credential.familyName!);
      final fullName = nameParts.join(' ');
      data['full_name'] = fullName;
      data['given_name'] = credential.givenName;
      data['family_name'] = credential.familyName;
    }
    await _supabase?.client.auth.updateUser(
      UserAttributes(
        data: data,
      ),
    );
    return authResponse;
  }

  Future<AuthResponse?> signInWithGoogle() async {
    if (_supabase == null) return null;
    const webClientId =
        '468465613098-sldi4kqbojdieefilrnj7kskh31lkn4u.'
        'apps.googleusercontent.com';

    const iosClientId =
        '468465613098-lssueocatme7ic6njm6fbrk6lusnru3a.'
        'apps.googleusercontent.com';
    const androidClientId =
        '468465613098-l8isv6g01r98stohen79h4vgkc0pota0.'
        'apps.googleusercontent.com';
    final scopes = ['email', 'profile'];
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId: webClientId,
      clientId: Platform.isIOS ? iosClientId : androidClientId,
    );
    final googleUser = await googleSignIn.attemptLightweightAuthentication();
    if (googleUser == null) {
      throw const AuthException('No Google user found.');
    }

    /// Authorization is required to obtain the access token with
    /// the appropriate scopes for Supabase authentication,
    ///
    /// while also granting permission to access user information.
    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(scopes) ??
        await googleUser.authorizationClient.authorizeScopes(scopes);
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('No ID Token found.');
    }
    final authResponse = await _supabase?.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
    final data = <String, dynamic>{
      'com.bapaws.planbook': true,
      'planbook': true,
    };
    if (googleUser.photoUrl != null) {
      data['avatar'] = googleUser.photoUrl;
      data['display_name'] = googleUser.displayName;
      data['email'] = googleUser.email;
      data['id'] = googleUser.id;
      data['provider'] = 'google';
    }
    await _supabase?.client.auth.updateUser(
      UserAttributes(
        data: data,
      ),
    );
    return authResponse;
  }

  // ==================== 微信登录相关 ====================

  /// 注册微信 SDK。应在 [initialize] 之后尽早调用。
  Future<void> registerWeChat() async {
    if (_kWeChatAppId.isEmpty) {
      if (kDebugMode) {
        print('WECHAT_APP_ID 为空，跳过微信 SDK 注册');
      }
      return;
    }
    try {
      await _fluwx.registerApi(
        appId: _kWeChatAppId,
        universalLink: _kWeChatUniversalLink,
      );
    } on Exception catch (e) {
      if (kDebugMode) {
        print('微信 SDK 注册失败: $e');
      }
    }
  }

  /// 是否已安装微信。
  Future<bool> isWeChatInstalled() async {
    try {
      return await _fluwx.isWeChatInstalled;
    } on Exception catch (_) {
      return false;
    }
  }

  /// 调起微信授权登录，拿到 code 后调用后端 Edge Function 换取 Supabase session。
  Future<AuthResponse?> signInWithWeChat() async {
    if (_supabase == null) return null;
    if (_kWeChatAppId.isEmpty) {
      throw const AuthException('WECHAT_APP_ID 未配置');
    }
    final installed = await isWeChatInstalled();
    if (!installed) {
      throw const AuthException('WeChat is not installed.');
    }

    final code = await _requestWeChatAuthCode();
    if (code == null || code.isEmpty) {
      // 用户取消或授权失败，不作为错误抛出
      return null;
    }

    final response = await _supabase?.client.functions.invoke(
      'planbook-wechat-auth',
      body: {'code': code},
    );
    if (response == null) {
      throw const AuthException('WeChat auth response is null.');
    }
    if (response.status != 200) {
      final error = (response.data as Map<String, dynamic>?)?['error'];
      throw AuthException(error?.toString() ?? 'WeChat auth failed.');
    }

    final data = response.data as Map<String, dynamic>;
    final tokenHash = data['token_hash'] as String?;
    if (tokenHash == null || tokenHash.isEmpty) {
      throw const AuthException('WeChat auth did not return token_hash.');
    }

    // 在客户端用 token_hash 建立 session，session token 不经过服务端响应传输。
    final authResponse = await _supabase?.client.auth.verifyOTP(
      tokenHash: tokenHash,
      type: OtpType.email,
    );
    return authResponse;
  }

  /// 为当前已登录用户绑定微信。
  Future<void> linkWeChat() async {
    if (_supabase == null) return;
    if (_kWeChatAppId.isEmpty) {
      throw const AuthException('WECHAT_APP_ID 未配置');
    }
    final installed = await isWeChatInstalled();
    if (!installed) {
      throw const AuthException('WeChat is not installed.');
    }
    if (_supabase?.client.auth.currentSession == null) {
      throw const AuthException('User is not signed in.');
    }

    final code = await _requestWeChatAuthCode();
    if (code == null || code.isEmpty) {
      throw const AuthException('WeChat authorization was cancelled.');
    }

    final response = await _supabase?.client.functions.invoke(
      'planbook-wechat-link',
      body: {'code': code},
    );
    if (response == null) {
      throw const AuthException('WeChat link response is null.');
    }
    if (response.status == 409) {
      throw const AuthException('该微信已绑定其他账号');
    }
    if (response.status != 200) {
      final error = (response.data as Map<String, dynamic>?)?['error'];
      throw AuthException(error?.toString() ?? 'WeChat link failed.');
    }

    // 刷新本地 session/user，使 user_metadata 中的微信信息生效。
    try {
      await _supabase?.client.auth.refreshSession();
    } on Exception catch (_) {
      // 即使刷新失败，绑定也已经成功，不阻塞流程。
    }
  }

  /// 调起微信授权并返回 code；用户取消时返回 null。
  Future<String?> _requestWeChatAuthCode() async {
    final completer = Completer<String?>();
    var isCompleted = false;
    FluwxCancelable? cancelable;

    void complete(String? value) {
      if (isCompleted) return;
      isCompleted = true;
      cancelable?.cancel();
      completer.complete(value);
    }

    cancelable = _fluwx.addSubscriber((response) {
      if (response is WeChatAuthResponse) {
        if (response.isSuccessful) {
          final code = response.code;
          complete(code?.isNotEmpty ?? false ? code : null);
        } else {
          complete(null);
        }
      }
    });

    try {
      final launched = await _fluwx.authBy(
        which: NormalAuth(scope: 'snsapi_userinfo'),
      );
      if (!launched) {
        complete(null);
      }
    } on Exception catch (_) {
      complete(null);
    }

    // 微信授权没有回调时兜底：30 秒后当作取消。
    Future.delayed(const Duration(seconds: 30), () => complete(null));

    return completer.future;
  }
}
