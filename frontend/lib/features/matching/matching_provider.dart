import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../shared/models/match.dart';

class MatchesNotifier extends StateNotifier<AsyncValue<List<Match>>> {
  final Ref _ref;

  MatchesNotifier(this._ref) : super(const AsyncLoading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncLoading();
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.get('/matches');
      if (!mounted) return;
      final matches = (res.data as List)
          .map((e) => Match.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncData(matches);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<bool> sendRequest(String matchId) => _updateStatus(matchId, 'request');
  Future<bool> acceptRequest(String matchId) => _updateStatus(matchId, 'accept');
  Future<bool> declineRequest(String matchId) => _updateStatus(matchId, 'decline');

  Future<bool> _updateStatus(String matchId, String action) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/matches/$matchId/$action');
      if (!mounted) return false;
      await load();
      return true;
    } on DioException {
      return false;
    }
  }
}

final matchesProvider =
    StateNotifierProvider<MatchesNotifier, AsyncValue<List<Match>>>(
  (ref) => MatchesNotifier(ref),
);
