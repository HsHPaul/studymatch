import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../shared/models/message.dart';
import '../auth/auth_provider.dart';
import '../profile/profile_provider.dart';

class UnreadChatsNotifier extends StateNotifier<Set<String>> {
  final Dio _dio;
  final Ref _ref;
  final Map<String, DateTime> _lastReadAt = {};
  // Tracks match IDs we're periodically watching
  final Set<String> _watchedIds = {};
  Timer? _timer;

  UnreadChatsNotifier(this._dio, this._ref) : super(const {}) {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _recheckAll());
    // Sobald das Profil das erste Mal geladen ist, sofort nachprüfen.
    // Ohne diesen Listener bricht _checkMatch still ab weil myId noch leer ist.
    _ref.listen<ProfileState>(profileProvider, (prev, next) {
      if (prev?.profile == null && next.profile != null && _watchedIds.isNotEmpty) {
        Future.microtask(_recheckAll);
      }
    });
  }

  /// Called from match list screen with the current accepted match IDs.
  /// Immediately checks new IDs and registers them for periodic re-checks.
  Future<void> updateWatched(List<String> matchIds) async {
    final fresh = matchIds.toSet();
    final newIds = fresh.difference(_watchedIds);
    _watchedIds
      ..clear()
      ..addAll(fresh);
    // Check new matches immediately; existing ones were already checked recently
    for (final id in newIds) {
      unawaited(_checkMatch(id));
    }
  }

  Future<void> _recheckAll() async {
    for (final id in List.of(_watchedIds)) {
      await _checkMatch(id);
    }
  }

  Future<void> _checkMatch(String matchId) async {
    if (!mounted) return;
    if (!_ref.read(authProvider).isAuthenticated) return;
    final myId = _ref.read(profileProvider).profile?.id ?? '';
    if (myId.isEmpty) return;

    try {
      final res = await _dio.get('/chat/$matchId/messages');
      if (!mounted) return;
      final msgs = (res.data as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();

      // Find the last message from the other user
      Message? lastOther;
      for (final m in msgs.reversed) {
        if (m.senderId != myId) {
          lastOther = m;
          break;
        }
      }

      if (lastOther == null) {
        // No message from other user → not unread
        if (state.contains(matchId)) {
          state = {...state}..remove(matchId);
        }
        return;
      }

      final lastRead = _lastReadAt[matchId];
      final isUnread =
          lastRead == null || lastOther.sentAt.isAfter(lastRead);
      if (isUnread && !state.contains(matchId)) {
        state = {...state, matchId};
      } else if (!isUnread && state.contains(matchId)) {
        state = {...state}..remove(matchId);
      }
    } on DioException {
      // Silently ignore network errors
    }
  }

  void markRead(String matchId) {
    _lastReadAt[matchId] = DateTime.now();
    if (state.contains(matchId)) {
      state = {...state}..remove(matchId);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final unreadChatsProvider =
    StateNotifierProvider<UnreadChatsNotifier, Set<String>>(
  (ref) => UnreadChatsNotifier(ref.read(dioProvider), ref),
);
