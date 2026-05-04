import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      loading: () => const Scaffold(body: LoadingIndicator()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: 'Match nicht gefunden.'),
      ),
      data: (matches) {
        final match = matches.where((m) => m.userId == matchId).firstOrNull;
        if (match == null) {
          return Scaffold(
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(match.alias),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        match.alias[0].toUpperCase(),
                        style: tt.headlineLarge?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(match.alias, style: tt.titleLarge),
                    if (match.studiengang != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        match.studiengang!,
                        style: tt.bodyMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _ScoreBadge(score: match.scorePercent),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Common subjects
            if (match.gemeinsacheFaecher.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.book_outlined,
                title: 'Gemeinsame Fächer',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.gemeinsacheFaecher
                    .map((f) => Chip(label: Text(f)))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Lernstil
            if (match.lernstil != null) ...[
              _SectionHeader(
                icon: Icons.psychology_outlined,
                title: 'Lernstil',
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.psychology_outlined),
                  title: Text(_lernstilLabel(match.lernstil!)),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Time overlaps
            if (match.ueberschneidungen.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.schedule_outlined,
                title: 'Gemeinsame Zeitfenster',
              ),
              ...match.ueberschneidungen.map(
                (o) => Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.access_time_outlined, size: 20),
                    title: Text(_capitalize(o.wochentag)),
                    trailing: Text(o.timeRange),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.chat_outlined),
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

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final int score;

  const _ScoreBadge({required this.score});

  Color _color(BuildContext context) {
    if (score >= 70) return Colors.green.shade600;
    if (score >= 40) return Theme.of(context).colorScheme.primary;
    return Theme.of(context).colorScheme.outline;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _color(context).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score% Match',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _color(context),
          fontSize: 16,
        ),
      ),
    );
  }
}
