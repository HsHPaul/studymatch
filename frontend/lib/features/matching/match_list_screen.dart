import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../features/profile/profile_provider.dart';
import '../../shared/models/match.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'matching_provider.dart';

class MatchListScreen extends ConsumerWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meine Matches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(matchesProvider.notifier).load(),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      body: state.when(
        loading: () =>
            const LoadingIndicator(message: 'Passende Lernpartner suchen…'),
        error: (e, _) => ErrorView(
          message: 'Fehler beim Laden der Matches.',
          onRetry: () => ref.read(matchesProvider.notifier).load(),
        ),
        data: (matches) {
          if (matches.isEmpty) {
            final lernstil = ref.watch(profileProvider).profile?.lernstil;
            return _EmptyState(missingLernstil: lernstil == null);
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(matchesProvider.notifier).load(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _MatchCard(match: matches[i]),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool missingLernstil;

  const _EmptyState({this.missingLernstil = false});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 88,
              height: 88,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.people_outline_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Keine Matches gefunden', style: tt.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Trage Fächer und Verfügbarkeiten in dein Profil ein,\num Lernpartner zu finden.',
              textAlign: TextAlign.center,
              style: tt.bodySmall,
            ),
            if (missingLernstil) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Dein Lernstil muss im Profil angegeben sein, bevor Matches vorgeschlagen werden können.',
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
    );
  }
}

// ── Match Card ────────────────────────────────────────────────────────────────

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
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.go('/matches/${match.userId}'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  match.alias[0].toUpperCase(),
                  style: tt.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name + Studiengang + Chips
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: match.gemeinsacheFaecher.take(3).map((f) {
                        return Chip(
                          label: Text(f),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          labelStyle: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Score circle + label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ScoreCircle(score: score, color: color),
                  const SizedBox(height: 4),
                  Text(
                    _scoreLabel(score),
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
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
  final Color color;

  const _ScoreCircle({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: CustomPaint(
        painter: _ScoreCirclePainter(score: score, color: color),
        child: Center(
          child: Text(
            '$score%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
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

    final bgPaint = Paint()
      ..color = const Color(0xFFEEEBF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * (score / 100),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreCirclePainter old) =>
      old.score != score || old.color != color;
}
