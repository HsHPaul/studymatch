import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../shared/models/room.dart';
import '../../shared/models/study_session.dart';

class SessionsState {
  final List<StudySession> sessions;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const SessionsState({
    this.sessions = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  SessionsState copyWith({
    List<StudySession>? sessions,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      SessionsState(
        sessions: sessions ?? this.sessions,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : (error ?? this.error),
      );
}

class SessionsNotifier extends StateNotifier<SessionsState> {
  final Ref _ref;

  SessionsNotifier(this._ref) : super(const SessionsState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.get('/sessions');
      if (!mounted) return;
      final sessions = (res.data as List)
          .map((e) => StudySession.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Termine konnten nicht geladen werden',
      );
    }
  }

  Future<bool> acceptSession(String sessionId) => _updateSessionStatus(sessionId, 'accept');
  Future<bool> declineSession(String sessionId) => _updateSessionStatus(sessionId, 'decline');
  Future<bool> acceptEdit(String sessionId) => _updateSessionStatus(sessionId, 'accept-edit');
  Future<bool> declineEdit(String sessionId) => _updateSessionStatus(sessionId, 'decline-edit');

  Future<bool> cancelSession(String sessionId, {String? reason}) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/sessions/$sessionId/cancel', data: {'reason': reason});
      if (!mounted) return false;
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteSession(String sessionId) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.delete('/sessions/$sessionId');
      if (!mounted) return false;
      state = state.copyWith(
        sessions: state.sessions.where((s) => s.id != sessionId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> proposeEdit({
    required String sessionId,
    required DateTime datum,
    required TimeOfDay uhrzeit,
    TimeOfDay? uhrzeitEnde,
    String? raumId,
  }) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.patch('/sessions/$sessionId/propose-edit', data: {
        'datum': _fmtDate(datum),
        'uhrzeit': _fmtTime(uhrzeit),
        if (uhrzeitEnde != null) 'uhrzeit_ende': _fmtTime(uhrzeitEnde),
        if (raumId != null) 'raum_id': raumId,
      });
      if (!mounted) return false;
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _updateSessionStatus(String sessionId, String action) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.post('/sessions/$sessionId/$action');
      if (!mounted) return false;
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createSession({
    required String matchId,
    required DateTime datum,
    required TimeOfDay uhrzeit,
    TimeOfDay? uhrzeitEnde,
    String? raumId,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final dio = _ref.read(dioProvider);
      final data = <String, dynamic>{
        'match_id': matchId,
        'datum': _fmtDate(datum),
        'uhrzeit': _fmtTime(uhrzeit),
        if (uhrzeitEnde != null) 'uhrzeit_ende': _fmtTime(uhrzeitEnde),
        if (raumId != null) 'raum_id': raumId,
      };
      await dio.post('/sessions', data: data);
      if (!mounted) return false;
      await load();
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Termin konnte nicht erstellt werden',
      );
      return false;
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
}

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, SessionsState>(
  (ref) => SessionsNotifier(ref),
);

final pendingSessionsProvider =
    FutureProvider.family<List<StudySession>, String>((ref, matchId) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/sessions/pending/$matchId');
  return (res.data as List)
      .map((e) => StudySession.fromJson(e as Map<String, dynamic>))
      .toList();
});

final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/rooms');
  return (res.data as List)
      .map((e) => Room.fromJson(e as Map<String, dynamic>))
      .toList();
});
