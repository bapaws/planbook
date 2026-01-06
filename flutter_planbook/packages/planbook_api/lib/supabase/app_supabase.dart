import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  static Future<void> initialize() async {
    if (_supabase != null) return;
    Supabase supabase;
    if (kDebugMode) {
      supabase = await Supabase.initialize(
        url: 'https://ujbjjzrepqahcrkyxlox.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
            'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVqY'
            'mpqenJlcHFhaGNya3l4bG94Iiwicm9sZSI6Im'
            'Fub24iLCJpYXQiOjE3NjI4NTI1MzEsImV4cCI'
            '6MjA3ODQyODUzMX0.'
            'siJey7U0kroIDp2rpuRfRP-Q2I4c44wWi0ThOW6rEsc',
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
      data: data,
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
    if (credential.givenName != null || credential.familyName != null) {
      final nameParts = <String>[];
      if (credential.givenName != null) nameParts.add(credential.givenName!);
      if (credential.familyName != null) nameParts.add(credential.familyName!);
      final fullName = nameParts.join(' ');
      await _supabase?.client.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            'given_name': credential.givenName,
            'family_name': credential.familyName,
          },
        ),
      );
    }
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
    return await _supabase?.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }
}
