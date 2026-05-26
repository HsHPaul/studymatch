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

  Future<bool> createSession({
    required String matchId,
    required DateTime datum,
    required TimeOfDay uhrzeit,
    String? raumId,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final dio = _ref.read(dioProvider);
      final data = <String, dynamic>{
        'match_id': matchId,
        'datum': _fmtDate(datum),
        'uhrzeit': _fmtTime(uhrzeit),
        if (raumId != null) 'raum_id': raumId,
      };
      final res = await dio.post('/sessions', data: data);
      final session =
          StudySession.fromJson(res.data as Map<String, dynamic>);
      final updated = [...state.sessions, session]
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
      state = state.copyWith(sessions: updated, isSaving: false);
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

final roomsProvider = FutureProvider<List<Room>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/rooms');
  return (res.data as List)
      .map((e) => Room.fromJson(e as Map<String, dynamic>))
      .toList();
});
