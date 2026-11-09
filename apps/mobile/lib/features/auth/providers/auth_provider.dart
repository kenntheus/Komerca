import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/storage/secure_storage.dart';

class AuthState {
  final AppUser? user;
  final String? accessToken;
  final String? refreshToken;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.accessToken,
    this.refreshToken,
    this.isLoading = false,
    this.error,
  });

  bool get isLoggedIn => user != null && accessToken != null;

  AuthState copyWith({
    AppUser? user,
    String? accessToken,
    String? refreshToken,
    bool? isLoading,
    String? error,
    bool clearCredentials = false,
  }) =>
      AuthState(
        user: clearCredentials ? null : user ?? this.user,
        accessToken:
            clearCredentials ? null : accessToken ?? this.accessToken,
        refreshToken:
            clearCredentials ? null : refreshToken ?? this.refreshToken,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio _dio;

  AuthNotifier(this._dio, {bool skipInit = false})
      : super(const AuthState()) {
    if (!skipInit) _init();
  }

  Future<void> _init() async {
    final token =
        await SecureStorage.instance.read(SecureStorage.keyAccessToken);
    final refreshToken =
        await SecureStorage.instance.read(SecureStorage.keyRefreshToken);
    final userJson =
        await SecureStorage.instance.read(SecureStorage.keyUser);
    if (token != null && userJson != null) {
      try {
        final user = AppUser.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>);
        state = AuthState(
          user: user,
          accessToken: token,
          refreshToken: refreshToken,
        );
      } catch (_) {
        // Corrupted stored state, start fresh
      }
    }
  }

  Future<void> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _dio.post('/auth/otp/request', data: {'phone': phone});
      state = state.copyWith(isLoading: false);
    } on DioException catch (e) {
      final err = ApiError.fromDioException(e);
      state = state.copyWith(isLoading: false, error: err.message);
      rethrow;
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post(
        '/auth/otp/verify',
        data: {'phone': phone, 'code': code},
      );
      final data = res.data as Map<String, dynamic>;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      await SecureStorage.instance.write(
          SecureStorage.keyAccessToken, accessToken);
      await SecureStorage.instance.write(
          SecureStorage.keyRefreshToken, refreshToken);
      await SecureStorage.instance.write(
          SecureStorage.keyUser, jsonEncode(user.toJson()));

      state = AuthState(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (e) {
      final err = ApiError.fromDioException(e);
      state = state.copyWith(isLoading: false, error: err.message);
      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = state.refreshToken;
    state = state.copyWith(isLoading: true);
    try {
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {
      // Always clear local state even if API call fails
    }
    await SecureStorage.instance.deleteAll();
    state = const AuthState();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AuthNotifier(dio);
});
