import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_localizations.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/chat/unread_chats_provider.dart';
import '../../features/matching/matching_provider.dart';
import '../../features/profile/profile_provider.dart';
import '../../shared/models/match.dart';
import '../../shared/widgets/loading_indicator.dart';

class MatchListScreen extends ConsumerStatefulWidget {
  const MatchListScreen({super.key});

  @override
  ConsumerState<MatchListScreen> createState() => _MatchListScreenState();
}

class _MatchListScreenState extends ConsumerState<MatchListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(pendingChatPolicyProvider)) {
        ref.read(pendingChatPolicyProvider.notifier).state = false;
        _showChatPolicyDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showChatPolicyDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(l10n.chatPolicyNotice),
          ],
        ),
        content: Text(l10n.chatPolicyText),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.understood),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        ref.read(matchesProvider.notifier).load();
      }
    });

    final state = ref.watch(matchesProvider);

    // Keep unread-chat provider in sync with accepted matches.
    ref.listen(matchesProvider, (_, next) {
      next.whenData((matches) {
        final ids = matches.where((m) => m.isAccepted).map((m) => m.matchId).toList();
        ref.read(unreadChatsProvider.notifier).updateWatched(ids);
      });
    });
    state.whenData((matches) {
      final ids = matches.where((m) => m.isAccepted).map((m) => m.matchId).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(unreadChatsProvider.notifier).updateWatched(ids);
      });
    });

    return state.when(
      loading: () => Scaffold(
        body: LoadingIndicator(message: l10n.loadingMatches),
      ),
      error: (e, _) {
        if (!ref.watch(authProvider).isAuthenticated) {
          return Scaffold(
            body: LoadingIndicator(message: l10n.loadingMatches),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.matchesTitle)),
          body: ErrorView(
            message: l10n.errorLoading,
            onRetry: () => ref.read(matchesProvider.notifier).load(),
          ),
        );
      },
      data: (matches) {
        final accepted = matches.where((m) => m.isAccepted).toList();
        final incoming = matches.where((m) => m.isPending && !m.iRequested).toList();
        final suggestions = matches.where((m) => m.isSuggestion || (m.isPending && m.iRequested)).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.matchesTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.read(matchesProvider.notifier).load(),
                tooltip: l10n.refresh,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.tabAccepted),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.tabRequests),
                      if (incoming.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${incoming.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(text: l10n.tabSuggestions),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _MatchTab(
                matches: accepted,
                emptyIcon: Icons.handshake_outlined,
                emptyTitle: l10n.noAcceptedMatches,
                emptySubtitle: l10n.noAcceptedMatchesSub,
              ),
              _IncomingTab(matches: incoming),
              _SuggestionsTab(
                matches: suggestions,
                showLernstilHint: ref.watch(profileProvider).profile?.lernstil == null,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Match Tab (Angenommen, with local filter) ────────────────────────────────

class _MatchTab extends ConsumerStatefulWidget {
  final List<Match> matches;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  const _MatchTab({
    required this.matches,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  ConsumerState<_MatchTab> createState() => _MatchTabState();
}

class _MatchTabState extends ConsumerState<_MatchTab> {
  bool _showFilter = false;
  int _currentMin = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filtered = widget.matches
        .where((m) => m.scorePercent >= _currentMin)
        .toList();

    return Column(
      children: [
        Container(
          color: AppColors.cardWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                _currentMin == 0 ? l10n.showAll : l10n.matchAbove(_currentMin),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => setState(() => _showFilter = !_showFilter),
                child: Text(_showFilter ? l10n.close : l10n.adjustFilter),
              ),
            ],
          ),
        ),
        if (_showFilter)
          _FilterPanel(
            currentMin: _currentMin,
            isSaving: false,
            buttonLabel: l10n.filterApply,
            onChanged: (val) {
              setState(() {
                _currentMin = val;
                _showFilter = false;
              });
            },
          ),
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(
                  icon: widget.emptyIcon,
                  title: _currentMin > 0
                      ? l10n.noMatchesAbove(_currentMin)
                      : widget.emptyTitle,
                  subtitle: _currentMin > 0
                      ? l10n.lowerThreshold
                      : widget.emptySubtitle,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(matchesProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _MatchCard(match: filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Suggestions Tab (with filter) ────────────────────────────────────────────

class _SuggestionsTab extends ConsumerStatefulWidget {
  final List<Match> matches;
  final bool showLernstilHint;

  const _SuggestionsTab({required this.matches, required this.showLernstilHint});

  @override
  ConsumerState<_SuggestionsTab> createState() => _SuggestionsTabState();
}

class _SuggestionsTabState extends ConsumerState<_SuggestionsTab> {
  bool _showFilter = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).profile;
    final currentMin = profile?.minMatchPercent ?? 0;
    final isSaving = ref.watch(profileProvider).isSaving;

    return Column(
      children: [
        // Filter bar
        Container(
          color: AppColors.cardWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                currentMin == 0 ? l10n.showAll : l10n.matchAbove(currentMin),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () => setState(() => _showFilter = !_showFilter),
                child: Text(_showFilter ? l10n.close : l10n.adjustFilter),
              ),
            ],
          ),
        ),
        if (_showFilter)
          _FilterPanel(
            currentMin: currentMin,
            isSaving: isSaving,
            buttonLabel: l10n.filterSave,
            onChanged: (val) async {
              final ok = await ref
                  .read(profileProvider.notifier)
                  .updateMinMatchScore(val / 100.0);
              if (ok) {
                ref.read(matchesProvider.notifier).load();
                if (mounted) setState(() => _showFilter = false);
              }
            },
          ),
        Expanded(
          child: widget.matches.isEmpty
              ? _EmptyState(
                  icon: Icons.search_rounded,
                  title: currentMin > 0
                      ? l10n.noSuggestionsAbove(currentMin)
                      : l10n.noSuggestions,
                  subtitle: currentMin > 0
                      ? l10n.noSuggestionsLowerThreshold
                      : l10n.noSuggestionsSub,
                  showLernstilHint: widget.showLernstilHint,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref.read(matchesProvider.notifier).load(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: widget.matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _MatchCard(match: widget.matches[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FilterPanel extends StatefulWidget {
  final int currentMin;
  final bool isSaving;
  final ValueChanged<int> onChanged;
  final String buttonLabel;

  const _FilterPanel({
    required this.currentMin,
    required this.isSaving,
    required this.onChanged,
    this.buttonLabel = 'Speichern',
  });

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.currentMin.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      color: AppColors.primaryLight,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.filterMinMatch} ${_value.round()}%',
            style: tt.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.filterDescription,
            style: tt.bodySmall?.copyWith(color: AppColors.muted),
          ),
          Slider(
            value: _value,
            min: 0,
            max: 90,
            divisions: 9,
            label: '${_value.round()}%',
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _value = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.allPercent, style: tt.bodySmall),
              Text('90%', style: tt.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.isSaving
                  ? null
                  : () => widget.onChanged(_value.round()),
              child: widget.isSaving
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(widget.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Incoming Requests Tab ────────────────────────────────────────────────────

class _IncomingTab extends ConsumerWidget {
  final List<Match> matches;

  const _IncomingTab({required this.matches});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (matches.isEmpty) {
      return _EmptyState(
        icon: Icons.mark_email_unread_outlined,
        title: l10n.noOpenRequests,
        subtitle: l10n.noOpenRequestsSub,
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(matchesProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _IncomingCard(match: matches[i]),
      ),
    );
  }
}

class _IncomingCard extends ConsumerWidget {
  final Match match;

  const _IncomingCard({required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  match.alias[0].toUpperCase(),
                  style: tt.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match.alias, style: tt.titleMedium),
                    if (match.studiengang != null)
                      Text(match.studiengang!, style: tt.bodySmall),
                  ],
                ),
              ),
              _ScoreCircle(score: match.scorePercent),
            ],
          ),
          if (match.gemeinsacheFaecher.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: match.gemeinsacheFaecher.take(3).map((f) => Chip(
                label: Text(f),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                labelStyle: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
              )).toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await ref.read(matchesProvider.notifier).declineRequest(match.matchId);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.declineError)),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  child: Text(l10n.decline),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final ok = await ref.read(matchesProvider.notifier).acceptRequest(match.matchId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? l10n.confirmedAlias(match.alias) : l10n.confirmError)),
                      );
                    }
                  },
                  child: Text(l10n.accept),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showLernstilHint;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showLernstilHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 88, height: 88,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                  child: Center(child: Icon(icon, size: 44, color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 20),
              Text(title, style: tt.titleMedium),
              const SizedBox(height: 8),
              Text(subtitle, textAlign: TextAlign.center, style: tt.bodySmall),
              if (showLernstilHint) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.lernstilHint,
                          style: tt.bodySmall?.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Match Card (Bestätigt & Vorschläge) ──────────────────────────────────────

class _MatchCard extends ConsumerWidget {
  final Match match;

  const _MatchCard({required this.match});

  Color _scoreColor(int pct) {
    if (pct >= 70) return AppColors.primary;
    if (pct >= 40) return AppColors.success;
    return AppColors.warning;
  }

  String _scoreLabel(int pct, AppLocalizations l10n) {
    if (pct >= 70) return l10n.scoreVeryGood;
    if (pct >= 40) return l10n.scoreGood;
    return l10n.scoreMedium;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final score = match.scorePercent;
    final color = _scoreColor(score);
    final hasUnread = match.isAccepted &&
        ref.watch(unreadChatsProvider).contains(match.matchId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: InkWell(
        onTap: match.isAccepted ? null : () => context.go('/matches/${match.userId}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  match.alias[0].toUpperCase(),
                  style: tt.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(match.alias, style: tt.titleMedium),
                    if (match.studiengang != null) ...[
                      const SizedBox(height: 2),
                      Text(match.studiengang!, style: tt.bodySmall),
                    ],
                    const SizedBox(height: 8),
                    if (match.isPending && match.iRequested)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.requestSent,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: match.gemeinsacheFaecher.take(3).map((f) => Chip(
                          label: Text(f),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          labelStyle: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                        )).toList(),
                      ),
                  ],
                ),
              ),
              if (match.isAccepted) ...[
                IconButton(
                  icon: const Icon(Icons.person_outline_rounded),
                  color: AppColors.primary,
                  tooltip: l10n.showProfile,
                  onPressed: () => context.go('/matches/${match.userId}'),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.forum_rounded),
                      color: hasUnread ? AppColors.error : AppColors.primary,
                      tooltip: l10n.openChat,
                      onPressed: () => context.go('/chat/${match.matchId}'),
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 6,
                        top: 6,
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
                ),
              ] else ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ScoreCircle(score: score, color: color),
                  const SizedBox(height: 4),
                  Text(
                    _scoreLabel(score, l10n),
                    style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score Circle ──────────────────────────────────────────────────────────────

class _ScoreCircle extends StatelessWidget {
  final int score;
  final Color? color;

  const _ScoreCircle({required this.score, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return SizedBox(
      width: 54, height: 54,
      child: CustomPaint(
        painter: _ScoreCirclePainter(score: score, color: c),
        child: Center(
          child: Text(
            '$score%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c),
          ),
        ),
      ),
    );
  }
}

class _ScoreCirclePainter extends CustomPainter {
  final int score;
  final Color color;

  const _ScoreCirclePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const startAngle = -math.pi / 2;
    canvas.drawCircle(center, radius,
        Paint()..color = const Color(0xFFEEEBF8)..style = PaintingStyle.stroke..strokeWidth = 5);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, 2 * math.pi * (score / 100), false,
      Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter old) =>
      old.score != score || old.color != color;
}
