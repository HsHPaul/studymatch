import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../shared/models/match.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'matching_provider.dart';

class MatchDetailScreen extends ConsumerWidget {
  final String matchId;

  const MatchDetailScreen({super.key, required this.matchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesProvider);

    return state.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingIndicator(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const ErrorView(message: 'Match nicht gefunden.'),
      ),
      data: (matches) {
        final match = matches.where((m) => m.userId == matchId).firstOrNull;
        if (match == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: const ErrorView(message: 'Match nicht gefunden.'),
          );
        }
        return _MatchDetailView(match: match);
      },
    );
  }
}

class _MatchDetailView extends StatelessWidget {
  final Match match;

  const _MatchDetailView({required this.match});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(match.alias),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Card ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      match.alias[0].toUpperCase(),
                      style: tt.displaySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(match.alias, style: tt.titleLarge),
                  if (match.studiengang != null) ...[
                    const SizedBox(height: 4),
                    Text(match.studiengang!, style: tt.bodySmall),
                  ],
                  const SizedBox(height: 12),
                  _ScoreBadge(score: match.scorePercent),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Gemeinsame Fächer ────────────────────────────────────────
            if (match.gemeinsacheFaecher.isNotEmpty) ...[
              const _SectionHeader(
                icon: Icons.book_outlined,
                title: 'Gemeinsame Fächer',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.gemeinsacheFaecher
                    .map((f) => Chip(label: Text(f)))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // ── Lernstil ─────────────────────────────────────────────────
            if (match.lernstil != null) ...[
              const _SectionHeader(
                icon: Icons.psychology_outlined,
                title: 'Lernstil',
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _lernstilLabel(match.lernstil!),
                    style: tt.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Gemeinsame Zeitfenster ───────────────────────────────────
            if (match.ueberschneidungen.isNotEmpty) ...[
              const _SectionHeader(
                icon: Icons.schedule_outlined,
                title: 'Gemeinsame Zeitfenster',
              ),
              const SizedBox(height: 10),
              ...match.ueberschneidungen.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        _capitalize(o.wochentag),
                        style: tt.bodyMedium,
                      ),
                      trailing: Text(
                        o.timeRange,
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),

            // ── Chat Button ──────────────────────────────────────────────
            FilledButton.icon(
              icon: const Icon(Icons.chat_rounded),
              label: const Text('Chat starten'),
              onPressed: () => context.push('/chat/${match.userId}'),
            ),
          ],
        ),
      ),
    );
  }

  String _lernstilLabel(String l) {
    const labels = {
      'still': 'Ruhig / Still',
      'gemischt': 'Gemischt',
      'diskutierend': 'Diskutierend',
    };
    return labels[l] ?? l;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}

// ── Score Badge ───────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  Color get _color {
    if (score >= 70) return AppColors.primary;
    if (score >= 40) return AppColors.success;
    return AppColors.warning;
  }

  String get _label {
    if (score >= 70) return 'Sehr gutes Match';
    if (score >= 40) return 'Gutes Match';
    return 'Mäßiges Match';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score%',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: _color,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
