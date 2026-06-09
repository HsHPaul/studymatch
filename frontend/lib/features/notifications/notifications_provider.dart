import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../shared/models/notification.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
  }) =>
      NotificationsState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
      );
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref _ref;
  Timer? _timer;

  NotificationsNotifier(this._ref) : super(const NotificationsState(isLoading: true)) {
    load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = _ref.read(dioProvider);
      final res = await dio.get('/notifications');
      if (!mounted) return;
      final list = (res.data as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markRead(String id) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.patch('/notifications/$id/read');
      if (!mounted) return;
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.id == id
                ? AppNotification(
                    id: n.id,
                    title: n.title,
                    body: n.body,
                    isRead: true,
                    createdAt: n.createdAt,
                  )
                : n)
            .toList(),
      );
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.delete('/notifications/$id');
      if (!mounted) return;
      state = state.copyWith(
        notifications: state.notifications.where((n) => n.id != id).toList(),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.patch('/notifications/read-all');
      if (!mounted) return;
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => AppNotification(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  isRead: true,
                  createdAt: n.createdAt,
                ))
            .toList(),
      );
    } catch (_) {}
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(ref),
);
