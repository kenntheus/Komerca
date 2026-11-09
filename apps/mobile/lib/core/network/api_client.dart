import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants.dart';
import '../storage/secure_storage.dart';

class _AuthInterceptor extends Interceptor {
  final Dio _dio;

  _AuthInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await SecureStorage.instance.read(SecureStorage.keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    // Don't retry if the failing request was itself a refresh call
    if (statusCode == 401 && !path.contains('/auth/token/refresh')) {
      final refreshToken =
          await SecureStorage.instance.read(SecureStorage.keyRefreshToken);
      if (refreshToken != null) {
        try {
          final refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
          final res = await refreshDio.post(
            '/auth/token/refresh',
            data: {'refreshToken': refreshToken},
          );
          final data = res.data as Map<String, dynamic>;
          final newAccess = data['accessToken'] as String;
          final newRefresh = data['refreshToken'] as String;

          await SecureStorage.instance.write(
              SecureStorage.keyAccessToken, newAccess);
          await SecureStorage.instance.write(
              SecureStorage.keyRefreshToken, newRefresh);

          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final retry = await _dio.fetch(err.requestOptions);
          return handler.resolve(retry);
        } catch (_) {
          await SecureStorage.instance.deleteAll();
        }
      }
    }
    handler.next(err);
  }
}

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(_AuthInterceptor(dio));
  return dio;
});
