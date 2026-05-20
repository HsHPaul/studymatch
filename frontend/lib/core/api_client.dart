import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String baseUrl = 'http://localhost:8000/api/v1';
const String tokenKey = 'jwt_token';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

// Interceptor sets this to true on 401 – AuthNotifier listens and clears state.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: tokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await storage.delete(key: tokenKey);
        ref.read(sessionExpiredProvider.notifier).state = true;
      }
      handler.next(error);
    },
  ));

  return dio;
});
