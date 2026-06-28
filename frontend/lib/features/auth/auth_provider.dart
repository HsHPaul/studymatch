import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api_client.dart';
import '../../features/matching/matching_provider.dart';
import '../../features/notifications/notifications_provider.dart';
import '../../features/profile/profile_provider.dart';
import '../../features/sessions/sessions_provider.dart';

final pendingChatPolicyProvider = StateProvider<bool>((ref) => false);

class AuthState {
  final String? token;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.token,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    String? token,
    bool? isLoading,
    String? error,
    bool clearToken = false,
    bool clearError = false,
  }) =>
      AuthState(
        token: clearToken ? null : (token ?? this.token),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final Ref _ref;

  AuthNotifier(this._storage, this._ref) : super(const AuthState(isLoading: true)) {
    _loadToken();
    _ref.listen(sessionExpiredProvider, (_, expired) {
      if (expired) {
        _clearUserData();
        state = const AuthState();
      }
    });
  }

  void _clearUserData() {
    _ref.read(sessionExpiredProvider.notifier).state = false;
    _ref.invalidate(profileProvider);
    _ref.invalidate(matchesProvider);
    _ref.invalidate(sessionsProvider);
    _ref.invalidate(allSubjectsProvider);
    _ref.invalidate(roomsProvider);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> _loadToken() async {
    final token = await _storage.read(key: tokenKey);
    state = AuthState(token: token);
  }

  // Uses a plain Dio without auth interceptor – no token needed for login/register.
  Dio get _publicDio => Dio(BaseOptions(baseUrl: baseUrl));

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _publicDio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = res.data['access_token'] as String;
      await _storage.write(key: tokenKey, value: token);
      _clearUserData();
      state = AuthState(token: token);
    } on DioException catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'E-Mail oder Passwort ist nicht korrekt.',
      );
    }
  }

  Future<void> register({
    required String alias,
    required String email,
    required String password,
    String? studiengang,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data = <String, dynamic>{
        'alias': alias,
        'email': email,
        'password': password,
      };
      if (studiengang != null && studiengang.isNotEmpty) {
        data['studiengang'] = studiengang;
      }
      final res = await _publicDio.post('/auth/register', data: data);
      final token = res.data['access_token'] as String;
      await _storage.write(key: tokenKey, value: token);
      _clearUserData();
      state = AuthState(token: token);
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'];
      state = state.copyWith(
        isLoading: false,
        error: detail?.toString() ?? 'Registrierung fehlgeschlagen',
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: tokenKey);
    _clearUserData();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(secureStorageProvider), ref),
);
