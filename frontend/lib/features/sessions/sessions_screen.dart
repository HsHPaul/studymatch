import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/room.dart';
import '../../shared/models/study_session.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'sessions_provider.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Termine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(sessionsProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading
          ? const LoadingIndicator(message: 'Termine laden…')
          : state.error != null && state.sessions.isEmpty
              ? ErrorView(
                  message: state.error!,
                  onRetry: () => ref.read(sessionsProvider.notifier).load(),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(sessionsProvider.notifier).load(),
                  child: state.sessions.isEmpty
                      ? _EmptyState()
                      : _SessionList(sessions: state.sessions),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Neuer Termin'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CreateSessionSheet(
        onSave: ({
          required String matchId,
          required DateTime datum,
          required TimeOfDay uhrzeit,
          String? raumId,
        }) async {
          final ok = await ref.read(sessionsProvider.notifier).createSession(
                matchId: matchId,
                datum: datum,
                uhrzeit: uhrzeit,
                raumId: raumId,
              );
          if (ok && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Termin erstellt!')),
            );
          }
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Noch keine Termine',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Erstelle einen neuen Lerntermin\nmit einem deiner Matches.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<StudySession> sessions;

  const _SessionList({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final upcoming = sessions.where((s) => s.isUpcoming).toList();
    final past = sessions.where((s) => !s.isUpcoming).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcoming.isNotEmpty) ...[
          const _GroupHeader(title: 'Bevorstehend'),
          const SizedBox(height: 8),
          ...upcoming.map((s) => _SessionCard(session: s, isPast: false)),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _GroupHeader(title: 'Vergangen'),
          const SizedBox(height: 8),
          ...past.map((s) => _SessionCard(session: s, isPast: true)),
        ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String title;

  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final StudySession session;
  final bool isPast;

  const _SessionCard({required this.session, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dt = session.dateTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isPast ? cs.surfaceContainerHighest : null,
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dt.day.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isPast ? cs.outline : cs.primary,
              ),
            ),
            Text(
              _monthAbbr(dt.month),
              style: TextStyle(
                fontSize: 12,
                color: isPast ? cs.outline : cs.primary,
              ),
            ),
          ],
        ),
        title: Text(
          '${_weekday(dt.weekday)}, ${_fmt2(dt.hour)}:${_fmt2(dt.minute)} Uhr',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isPast ? cs.onSurfaceVariant : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusChip(status: session.status),
          ],
        ),
        trailing:
            Icon(Icons.chevron_right, color: isPast ? cs.outline : cs.onSurface),
      ),
    );
  }

  String _fmt2(int n) => n.toString().padLeft(2, '0');

  String _monthAbbr(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
    ];
    return months[m];
  }

  String _weekday(int w) {
    const days = ['', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return days[w];
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'bestaetigt' => ('Bestätigt', Colors.green),
      'abgesagt' => ('Abgesagt', Colors.red),
      _ => ('Geplant', Theme.of(context).colorScheme.primary),
    };

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

typedef _CreateCallback = Future<void> Function({
  required String matchId,
  required DateTime datum,
  required TimeOfDay uhrzeit,
  String? raumId,
});

class _CreateSessionSheet extends ConsumerStatefulWidget {
  final _CreateCallback onSave;

  const _CreateSessionSheet({required this.onSave});

  @override
  ConsumerState<_CreateSessionSheet> createState() =>
      _CreateSessionSheetState();
}

class _CreateSessionSheetState extends ConsumerState<_CreateSessionSheet> {
  final _matchIdController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  Room? _selectedRoom;
  bool _saving = false;

  @override
  void dispose() {
    _matchIdController.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final matchId = _matchIdController.text.trim();
    if (matchId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match-ID ist erforderlich')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(
      matchId: matchId,
      datum: _selectedDate,
      uhrzeit: _selectedTime,
      raumId: _selectedRoom?.id,
    );
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Neuer Lerntermin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _matchIdController,
            decoration: const InputDecoration(
              labelText: 'Match-ID (UUID)',
              helperText: 'Die UUID des Match-Datensatzes aus der Datenbank',
              prefixIcon: Icon(Icons.people_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_fmtDate(_selectedDate)),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setState(() => _selectedDate = d);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_fmtTime(_selectedTime)),
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (t != null) setState(() => _selectedTime = t);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          rooms.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
            data: (roomList) => DropdownButtonFormField<Room>(
              value: _selectedRoom,
              decoration: const InputDecoration(
                labelText: 'Raum (optional)',
                prefixIcon: Icon(Icons.room_outlined),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Kein Raum'),
                ),
                ...roomList.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.displayName),
                    )),
              ],
              onChanged: (r) => setState(() => _selectedRoom = r),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Termin erstellen'),
          ),
        ],
      ),
    );
  }
}
