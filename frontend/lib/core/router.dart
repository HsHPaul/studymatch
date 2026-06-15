import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/matching/match_detail_screen.dart';
import '../features/matching/match_list_screen.dart';
import '../features/chat/unread_chats_provider.dart';
import '../features/notifications/notifications_provider.dart';
import '../features/profile/profile_screen.dart';
import '../features/sessions/sessions_screen.dart';
import 'app_colors.dart';
import 'app_localizations.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/matches',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;

      final loggedIn = auth.isAuthenticated;
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/login' || loc == '/register';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/matches';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/chat/:matchId',
        builder: (context, state) =>
            ChatScreen(matchId: state.pathParameters['matchId']!),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            _MainScaffold(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/matches',
            builder: (_, __) => const MatchListScreen(),
            routes: [
              GoRoute(
                path: ':matchId',
                builder: (context, state) => MatchDetailScreen(
                  matchId: state.pathParameters['matchId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/sessions',
            builder: (_, __) => const SessionsScreen(),
          ),
        ],
      ),
    ],
  );
});

class _MainScaffold extends ConsumerStatefulWidget {
  final String location;
  final Widget child;

  const _MainScaffold({required this.location, required this.child});

  @override
  ConsumerState<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<_MainScaffold> {
  late int _currentIndex;
  late int _prevIndex;

  static int _indexOf(String location) {
    if (location.startsWith('/matches')) return 0;
    if (location.startsWith('/profile')) return 1;
    if (location.startsWith('/sessions')) return 2;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = _indexOf(widget.location);
    _prevIndex = _currentIndex;
  }

  @override
  void didUpdateWidget(_MainScaffold old) {
    super.didUpdateWidget(old);
    final newIndex = _indexOf(widget.location);
    if (newIndex != _currentIndex) {
      _prevIndex = _currentIndex;
      _currentIndex = newIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = ref.watch(notificationsProvider).unreadCount > 0;
    final hasUnreadChats = ref.watch(unreadChatsProvider).isNotEmpty;
    final goingRight = _currentIndex > _prevIndex;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, animation) {
          final isIncoming =
              (child.key as ValueKey<int>).value == _currentIndex;
          final enterOffset =
              goingRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          final exitOffset =
              goingRight ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
          final tween = Tween<Offset>(
            begin: isIncoming ? enterOffset : exitOffset,
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
            position: tween.animate(animation),
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: widget.child,
        ),
      ),
      bottomNavigationBar: _StyledNavBar(
        selectedIndex: _currentIndex,
        hasProfileBadge: hasUnread,
        hasMatchesBadge: hasUnreadChats,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/matches');
            case 1:
              context.go('/profile');
            case 2:
              context.go('/sessions');
          }
        },
      ),
    );
  }
}

class _StyledNavBar extends ConsumerWidget {
  final int selectedIndex;
  final bool hasProfileBadge;
  final bool hasMatchesBadge;
  final ValueChanged<int> onTap;

  const _StyledNavBar({
    required this.selectedIndex,
    required this.hasProfileBadge,
    required this.hasMatchesBadge,
    required this.onTap,
  });

  Widget _matchesIcon({required bool selected, required bool badge}) {
    final icon = Icon(selected ? Icons.people : Icons.people_outline);
    if (!badge) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -3,
          top: -3,
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileIcon({required bool selected, required bool badge}) {
    final icon = Icon(selected ? Icons.person : Icons.person_outline);
    if (!badge) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -3,
          top: -3,
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        destinations: [
          NavigationDestination(
            icon: _matchesIcon(selected: false, badge: hasMatchesBadge),
            selectedIcon: _matchesIcon(selected: true, badge: hasMatchesBadge),
            label: l10n.navMatches,
          ),
          NavigationDestination(
            icon: _profileIcon(selected: false, badge: hasProfileBadge),
            selectedIcon: _profileIcon(selected: true, badge: hasProfileBadge),
            label: l10n.navProfile,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.navSessions,
          ),
        ],
      ),
    );
  }
}
