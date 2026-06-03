import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/api_client.dart';
import '../../shared/models/message.dart';

const _wsBaseUrl = String.fromEnvironment(
  'WS_BASE_URL',
  defaultValue: 'ws://localhost:8000/api/v1',
);

class ChatState {
  final List<Message> messages;
  final bool isConnected;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isConnected = false,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isConnected,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isConnected: isConnected ?? this.isConnected,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  final String matchId;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;

  ChatNotifier(this._dio, this._storage, this.matchId)
      : super(const ChatState(isLoading: true)) {
    Future.microtask(_init);
  }

  Future<void> _init() async {
    await _loadMessages();
    await _connectWebSocket();
  }

  Future<void> _loadMessages() async {
    try {
      final res = await _dio.get('/chat/$matchId/messages');
      final messages = (res.data as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(messages: messages, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail']?.toString() ??
            'Nachrichten konnten nicht geladen werden',
      );
    }
  }

  Future<void> _connectWebSocket() async {
    final token = await _storage.read(key: tokenKey);
    if (token == null) return;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_wsBaseUrl/chat/ws/$matchId?token=$token'),
      );
      await _channel!.ready;
      state = state.copyWith(isConnected: true);

      _sub = _channel!.stream.listen(
        (data) {
          if (data is! String) return;
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            if (!json.containsKey('id')) return;
            final msg = Message.fromJson(json);
            // Avoid duplicates – server may echo own messages in Sprint 2
            if (state.messages.any((m) => m.id == msg.id)) return;
            state =
                state.copyWith(messages: [...state.messages, msg]);
          } catch (_) {}
        },
        onError: (_) => state = state.copyWith(isConnected: false),
        onDone: () => state = state.copyWith(isConnected: false),
      );
    } catch (_) {
      // WS not available – REST-only fallback is sufficient
      state = state.copyWith(isConnected: false);
    }
  }

  Future<void> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;

    // Always persist via REST so messages survive WebSocket reconnects.
    try {
      final res = await _dio.post(
        '/chat/$matchId/messages',
        data: {'content': trimmed},
      );
      final msg = Message.fromJson(res.data as Map<String, dynamic>);
      if (!state.messages.any((m) => m.id == msg.id)) {
        state = state.copyWith(messages: [...state.messages, msg]);
      }
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['detail']?.toString() ??
            'Nachricht konnte nicht gesendet werden',
      );
    }
  }

  Future<void> refresh() => _loadMessages();

  @override
  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>(
  (ref, matchId) => ChatNotifier(
    ref.read(dioProvider),
    ref.read(secureStorageProvider),
    matchId,
  ),
);
