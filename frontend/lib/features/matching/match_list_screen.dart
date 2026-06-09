import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../features/auth/auth_provider.dart';
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
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            const Text('Hinweis'),
          ],
        ),
        content: const Text(
          'Bleib respektvoll: Beleidigungen, Diskriminierung, Bedrohungen und unangemessene Inhalte sind im Chat nicht erlaubt.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isAuthenticated && !(prev?.isAuthenticated ?? false)) {
        ref.read(matchesProvider.notifier).load();
      }
    });

    final state = ref.watch(matchesProvider);

    return state.when(
      loading: () => Scaffold(
        body: const LoadingIndicator(message: 'Lade Matches…'),
      ),
      error: (e, _) {
        if (!ref.watch(authProvider).isAuthenticated) {
          return Scaffold(
                body: const LoadingIndicator(message: 'Lade Matches…'),
          );
        }
        return Scaffold(
            appBar: AppBar(title: const Text('Matches')),
          body: ErrorView(
            message: 'Fehler beim Laden.',
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
            title: const Text('Matches'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.read(matchesProvider.notifier).load(),
                tooltip: 'Aktualisieren',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: 'Angenommen'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Anfragen'),
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
                const Tab(text: 'Vorschläge'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _MatchTab(
                matches: accepted,
                emptyIcon: Icons.handshake_outlined,
                emptyTitle: 'Noch keine bestätigten Matches',
                emptySubtitle: 'Schicke Anfragen an passende Lernpartner\naus dem Vorschläge-Tab.',
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
                _currentMin == 0 ? 'Alle anzeigen' : 'Ab $_currentMin% Match',
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
                child: Text(_showFilter ? 'Schließen' : 'Anpassen'),
              ),
            ],
          ),
        ),
        if (_showFilter)
          _FilterPanel(
            currentMin: _currentMin,
            isSaving: false,
            buttonLabel: 'Anwenden',
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
                      ? 'Keine Matches ab $_currentMin%'
                      : widget.emptyTitle,
                  subtitle: _currentMin > 0
                      ? 'Senke den Mindest-Prozentwert.'
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
    final profile = ref.watch(profileProvider).profile;
    final currentMin = profile?.minMatchPercent ?? 0;
    final isSaving = ref.watch(profileProvider).isSaving;

    return Column(
      children: [
        // Filter-Leiste
        Container(
          color: AppColors.cardWhite,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                currentMin == 0 ? 'Alle anzeigen' : 'Ab $currentMin% Match',
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
                child: Text(_showFilter ? 'Schließen' : 'Anpassen'),
              ),
            ],
          ),
        ),
        if (_showFilter)
          _FilterPanel(
            currentMin: currentMin,
            isSaving: isSaving,
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
                      ? 'Keine Vorschläge ab $currentMin%'
                      : 'Keine Vorschläge gefunden',
                  subtitle: currentMin > 0
                      ? 'Senke den Mindest-Prozentwert oder ergänze dein Profil.'
                      : 'Trage Fächer und Verfügbarkeiten in dein Profil ein.',
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

    return Container(
      color: AppColors.primaryLight,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mindest-Match: ${_value.round()}%',
            style: tt.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Nur Personen ab diesem Wert werden angezeigt – und umgekehrt.',
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
              Text('0% (alle)', style: tt.bodySmall),
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
    if (matches.isEmpty) {
      return const _EmptyState(
        icon: Icons.mark_email_unread_outlined,
        title: 'Keine offenen Anfragen',
        subtitle: 'Wenn jemand eine Match-Anfrage\nan dich sendet, erscheint sie hier.',
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
                        const SnackBar(content: Text('Fehler beim Ablehnen')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Ablehnen'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final ok = await ref.read(matchesProvider.notifier).acceptRequest(match.matchId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(ok ? '${match.alias} bestätigt!' : 'Fehler beim Bestätigen')),
                      );
                    }
                  },
                  child: const Text('Annehmen'),
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
                          'Dein Lernstil muss im Profil angegeben sein.',
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

class _MatchCard extends StatelessWidget {
  final Match match;

  const _MatchCard({required this.match});

  Color _scoreColor(int pct) {
    if (pct >= 70) return AppColors.primary;
    if (pct >= 40) return AppColors.success;
    return AppColors.warning;
  }

  String _scoreLabel(int pct) {
    if (pct >= 70) return 'Sehr gutes Match';
    if (pct >= 40) return 'Gutes Match';
    return 'Mäßiges Match';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final score = match.scorePercent;
    final color = _scoreColor(score);

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
                        child: const Text(
                          'Anfrage gesendet',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning),
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
                  tooltip: 'Profil anzeigen',
                  onPressed: () => context.go('/matches/${match.userId}'),
                ),
                IconButton(
                  icon: const Icon(Icons.forum_rounded),
                  color: AppColors.primary,
                  tooltip: 'Chat öffnen',
                  onPressed: () => context.go('/chat/${match.matchId}'),
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
                    _scoreLabel(score),
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
