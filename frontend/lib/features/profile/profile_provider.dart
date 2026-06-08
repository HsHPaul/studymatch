import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../shared/models/subject.dart';
import '../../shared/models/user.dart';

class UserAvailability {
  final String id;
  final String wochentag;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const UserAvailability({
    required this.id,
    required this.wochentag,
    required this.startTime,
    required this.endTime,
  });

  factory UserAvailability.fromJson(Map<String, dynamic> json) {
    return UserAvailability(
      id: json['id'] as String,
      wochentag: json['wochentag'] as String,
      startTime: _parseTime(json['start_time'] as String),
      endTime: _parseTime(json['end_time'] as String),
    );
  }

  static TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String get timeRange =>
      '${_fmt(startTime)}–${_fmt(endTime)}';

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class ProfileState {
  final UserProfile? profile;
  final List<Subject> mySubjects;
  final List<UserAvailability> myAvailabilities;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  const ProfileState({
    this.profile,
    this.mySubjects = const [],
    this.myAvailabilities = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? profile,
    List<Subject>? mySubjects,
    List<UserAvailability>? myAvailabilities,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) =>
      ProfileState(
        profile: profile ?? this.profile,
        mySubjects: mySubjects ?? this.mySubjects,
        myAvailabilities: myAvailabilities ?? this.myAvailabilities,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        error: clearError ? null : (error ?? this.error),
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Dio _dio;

  ProfileNotifier(this._dio) : super(const ProfileState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _dio.get('/profiles/me'),
        _dio.get('/profiles/me/subjects'),
        _dio.get('/profiles/me/availabilities'),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        profile: UserProfile.fromJson(results[0].data as Map<String, dynamic>),
        mySubjects: (results[1].data as List)
            .map((e) => Subject.fromJson(e as Map<String, dynamic>))
            .toList(),
        myAvailabilities: (results[2].data as List)
            .map((e) => UserAvailability.fromJson(e as Map<String, dynamic>))
            .toList(),
        isLoading: false,
      );
    } on DioException catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['detail']?.toString() ?? 'Laden fehlgeschlagen',
      );
    }
  }

  Future<bool> updateProfile({
    String? alias,
    String? studiengang,
    String? lernstil,
    String? bio,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final data = <String, dynamic>{};
      if (alias != null) data['alias'] = alias;
      if (studiengang != null) data['studiengang'] = studiengang;
      if (lernstil != null) data['lernstil'] = lernstil;
      if (bio != null) data['bio'] = bio;

      final res = await _dio.patch('/profiles/me', data: data);
      state = state.copyWith(
        profile: UserProfile.fromJson(res.data as Map<String, dynamic>),
        isSaving: false,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.response?.data?['detail']?.toString() ?? 'Speichern fehlgeschlagen',
      );
      return false;
    }
  }

  Future<void> addSubject(String subjectId) async {
    try {
      await _dio.post('/profiles/me/subjects', data: {'subject_id': subjectId});
      await _reloadSubjects();
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['detail']?.toString() ?? 'Fach konnte nicht hinzugefügt werden',
      );
    }
  }

  Future<void> removeSubject(String subjectId) async {
    try {
      await _dio.delete('/profiles/me/subjects/$subjectId');
      state = state.copyWith(
        mySubjects: state.mySubjects.where((s) => s.id != subjectId).toList(),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['detail']?.toString() ?? 'Fach konnte nicht entfernt werden',
      );
    }
  }

  Future<void> addAvailability({
    required String wochentag,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    try {
      await _dio.post('/profiles/me/availabilities', data: {
        'wochentag': wochentag,
        'start_time': _formatTime(startTime),
        'end_time': _formatTime(endTime),
      });
      await _reloadAvailabilities();
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['detail']?.toString() ?? 'Zeitfenster konnte nicht hinzugefügt werden',
      );
    }
  }

  Future<void> removeAvailability(String id) async {
    try {
      await _dio.delete('/profiles/me/availabilities/$id');
      state = state.copyWith(
        myAvailabilities:
            state.myAvailabilities.where((a) => a.id != id).toList(),
      );
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['detail']?.toString() ?? 'Zeitfenster konnte nicht entfernt werden',
      );
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _dio.patch('/profiles/me/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      if (!mounted) return false;
      state = state.copyWith(isSaving: false);
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        error: e.response?.data?['detail']?.toString() ?? 'Passwort konnte nicht geändert werden',
      );
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _dio.delete('/profiles/me');
      return true;
    } on DioException catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSaving: false,
        error: e.response?.data?['detail']?.toString() ?? 'Account konnte nicht gelöscht werden',
      );
      return false;
    }
  }

  Future<void> _reloadSubjects() async {
    final res = await _dio.get('/profiles/me/subjects');
    state = state.copyWith(
      mySubjects: (res.data as List)
          .map((e) => Subject.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> _reloadAvailabilities() async {
    final res = await _dio.get('/profiles/me/availabilities');
    state = state.copyWith(
      myAvailabilities: (res.data as List)
          .map((e) => UserAvailability.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(ref.read(dioProvider)),
);

final allSubjectsProvider = FutureProvider<List<Subject>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/profiles/subjects');
  return (res.data as List)
      .map((e) => Subject.fromJson(e as Map<String, dynamic>))
      .toList();
});
