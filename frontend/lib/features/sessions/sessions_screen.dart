import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/app_localizations.dart';
import '../../core/time_picker_utils.dart';
import '../../shared/models/match.dart';
import '../../shared/models/room.dart';
import '../../shared/models/study_session.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../core/blacklist_service.dart';
import '../../shared/models/notification.dart';
import '../matching/matching_provider.dart';
import '../notifications/notifications_provider.dart';
import '../profile/profile_provider.dart';
import 'sessions_provider.dart';

class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

// Normalise a date to midnight so Map lookups work regardless of time component.
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

Map<DateTime, Color> _buildMarkedDays(
    List<StudySession> sessions, List<AppNotification> notifications) {
  final map = <DateTime, Color>{};

  for (final s in sessions) {
    if (s.status == 'abgesagt') continue;
    final key = _dateOnly(s.dateTime);
    final color = s.hasPendingEdit ? AppColors.warning : AppColors.success;
    if (!map.containsKey(key) || map[key] == AppColors.success) {
      map[key] = color;
    }
  }

  final dateRe = RegExp(r'(\d{2})\.(\d{2})\.(\d{4})');
  for (final n in notifications) {
    if (n.isRead || n.title != 'Termin abgesagt') continue;
    final match = dateRe.firstMatch(n.body);
    if (match == null) continue;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    map[DateTime(year, month, day)] = AppColors.error;
  }

  return map;
}

enum _GroupOrder { bevorstehend, vergangen, angefragt }

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  DateTime _selectedDay = DateTime.now();
  _GroupOrder _sortOrder = _GroupOrder.bevorstehend;
  DateTime? _filterDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(sessionsProvider);

    final sortLabels = {
      _GroupOrder.bevorstehend: l10n.sortUpcoming,
      _GroupOrder.vergangen: l10n.sortPast,
      _GroupOrder.angefragt: l10n.sortRequested,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mySessions),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<_GroupOrder>(
              value: _sortOrder,
              icon: const Icon(Icons.sort_rounded),
              items: _GroupOrder.values
                  .map((o) => DropdownMenuItem(
                        value: o,
                        child: Text(sortLabels[o]!,
                            style: const TextStyle(fontSize: 14)),
                      ))
                  .toList(),
              onChanged: (o) {
                if (o != null) setState(() => _sortOrder = o);
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(sessionsProvider.notifier).load(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mini Calendar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Builder(builder: (context) {
                  final markedDays = _buildMarkedDays(state.sessions,
                      ref.watch(notificationsProvider).notifications);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MiniCalendar(
                        selectedDay: _selectedDay,
                        onDaySelected: (d) {
                          final key = _dateOnly(d);
                          setState(() {
                            _selectedDay = d;
                            if (markedDays.containsKey(key)) {
                              _filterDay = key;
                            }
                          });
                        },
                        markedDays: markedDays,
                        filterDay: _filterDay,
                        onClearFilter: () => setState(() => _filterDay = null),
                      ),
                      const SizedBox(height: 8),
                      _CalendarLegend(),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Session List ───────────────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? LoadingIndicator(message: l10n.loadingSessions)
                : state.error != null && state.sessions.isEmpty
                    ? ErrorView(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(sessionsProvider.notifier).load(),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () =>
                            ref.read(sessionsProvider.notifier).load(),
                        child: state.sessions.isEmpty
                            ? _EmptyState()
                            : _SessionList(
                                sessions: _filterDay == null
                                    ? state.sessions
                                    : state.sessions
                                        .where((s) =>
                                            _dateOnly(s.dateTime) == _filterDay)
                                        .toList(),
                                sortOrder: _sortOrder,
                                filterDay: _filterDay,
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newSession),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final matchesState = ref.read(matchesProvider);
    final matches = (matchesState.asData?.value ?? [])
        .where((m) => m.isAccepted)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CreateSessionSheet(
        matches: matches,
        onSave: ({
          required String matchId,
          required DateTime datum,
          required TimeOfDay uhrzeit,
          TimeOfDay? uhrzeitEnde,
          String? raumId,
        }) async {
          final ok = await ref.read(sessionsProvider.notifier).createSession(
                matchId: matchId,
                datum: datum,
                uhrzeit: uhrzeit,
                uhrzeitEnde: uhrzeitEnde,
                raumId: raumId,
              );
          if (ok && context.mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.sessionCreated)),
            );
          }
        },
      ),
    );
  }
}

// ── Mini Calendar ─────────────────────────────────────────────────────────────

class _MiniCalendar extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;
  final Map<DateTime, Color> markedDays;
  final DateTime? filterDay;
  final VoidCallback? onClearFilter;

  const _MiniCalendar({
    required this.selectedDay,
    required this.onDaySelected,
    this.markedDays = const {},
    this.filterDay,
    this.onClearFilter,
  });


  int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DateTime.now();
    final year = selectedDay.year;
    final month = selectedDay.month;
    final firstWeekday = DateTime(year, month, 1).weekday;
    final totalDays = _daysInMonth(year, month);
    final offset = firstWeekday - 1;
    final tt = Theme.of(context).textTheme;

    final dayLabels = l10n.calendarDayLabels;
    final monthNames = l10n.calendarMonthNames;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '${monthNames[month]} $year',
                style: tt.titleMedium,
              ),
              if (filterDay != null)
                Expanded(
                  child: Center(
                    child: GestureDetector(
                      onTap: onClearFilter,
                      child: Text(
                        l10n.showAllSessions,
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
              _NavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () {
                  final prev = DateTime(year, month - 1, 1);
                  onDaySelected(DateTime(prev.year, prev.month, 1));
                },
              ),
              const SizedBox(width: 4),
              _NavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () {
                  final next = DateTime(year, month + 1, 1);
                  onDaySelected(DateTime(next.year, next.month, 1));
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day headers
          Row(
            children: dayLabels.map((d) {
              return Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 36,
            ),
            itemCount: offset + totalDays,
            itemBuilder: (context, i) {
              if (i < offset) return const SizedBox.shrink();
              final day = i - offset + 1;
              final date = DateTime(year, month, day);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = date.year == selectedDay.year &&
                  date.month == selectedDay.month &&
                  date.day == selectedDay.day;

              final markColor = markedDays[_dateOnly(date)];
              final bgColor = isSelected
                  ? AppColors.primary
                  : markColor != null
                      ? markColor
                      : isToday
                          ? AppColors.primaryLight
                          : Colors.transparent;
              final textColor = isSelected || markColor != null
                  ? Colors.white
                  : isToday
                      ? AppColors.primary
                      : AppColors.navy;
              return GestureDetector(
                onTap: () => onDaySelected(date),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected || isToday || markColor != null
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Selected date label
          if (selectedDay.day != DateTime.now().day ||
              selectedDay.month != DateTime.now().month ||
              selectedDay.year != DateTime.now().year) ...[
            const SizedBox(height: 8),
            Text(
              _formatDate(selectedDay, l10n),
              style: tt.bodySmall?.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d, AppLocalizations l10n) {
    final weekdays = l10n.calendarWeekdayNames;
    final monthNames = l10n.calendarMonthNames;
    return '${weekdays[d.weekday]}, ${d.day}. ${monthNames[d.month]} ${d.year}';
  }
}

// ── Calendar Legend ───────────────────────────────────────────────────────────

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context)
        .textTheme
        .labelSmall
        ?.copyWith(color: AppColors.navy);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.success),
        const SizedBox(width: 4),
        Text(l10n.legendSession, style: style),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.warning),
        const SizedBox(width: 4),
        Text(l10n.legendPending, style: style),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.error),
        const SizedBox(width: 4),
        Text(l10n.legendCancelled, style: style),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ── Nav Button ────────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                width: 88,
                height: 88,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.calendar_today_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(l10n.noSessions, style: tt.titleMedium),
              const SizedBox(height: 8),
              Text(
                l10n.noSessionsSub,
                textAlign: TextAlign.center,
                style: tt.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Session List ──────────────────────────────────────────────────────────────

class _SessionList extends StatelessWidget {
  final List<StudySession> sessions;
  final _GroupOrder sortOrder;
  final DateTime? filterDay;

  const _SessionList({
    required this.sessions,
    required this.sortOrder,
    this.filterDay,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requested = sessions.where((s) => s.isRequested).toList();
    final upcoming =
        sessions.where((s) => !s.isRequested && s.isUpcoming).toList();
    final past =
        sessions.where((s) => !s.isRequested && !s.isUpcoming).toList();

    List<({String title, List<StudySession> items, bool isPast})> groups = [
      (title: l10n.groupUpcoming, items: upcoming, isPast: false),
      (title: l10n.groupPast, items: past, isPast: true),
      (title: l10n.groupRequested, items: requested, isPast: false),
    ];

    groups.sort((a, b) {
      int rank(_GroupOrder o, String title) {
        final upcoming = l10n.groupUpcoming;
        final past = l10n.groupPast;
        final requested = l10n.groupRequested;
        if (o == _GroupOrder.bevorstehend) {
          return title == upcoming ? 0 : title == requested ? 1 : 2;
        } else if (o == _GroupOrder.vergangen) {
          return title == past ? 0 : title == upcoming ? 1 : 2;
        } else {
          return title == requested ? 0 : title == upcoming ? 1 : 2;
        }
      }

      return rank(sortOrder, a.title).compareTo(rank(sortOrder, b.title));
    });

    final items = <Widget>[];
    for (final g in groups) {
      if (g.items.isEmpty) continue;
      if (items.isNotEmpty) items.add(const SizedBox(height: 16));
      items.add(_GroupHeader(title: g.title));
      items.add(const SizedBox(height: 8));
      for (final s in g.items) {
        items.add(_SessionCard(session: s, isPast: g.isPast));
      }
    }

    if (items.isEmpty && filterDay != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Center(
            child: Text(
              l10n.noSessionsOnDay,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: items,
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
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _SessionCard extends StatelessWidget {
  final StudySession session;
  final bool isPast;

  const _SessionCard({required this.session, required this.isPast});

  @override
  Widget build(BuildContext context) {
    final dt = session.dateTime;
    final tt = Theme.of(context).textTheme;
    final hasPendingIncoming = session.hasPendingEdit && !session.iProposedEdit;
    final hasPendingOutgoing = session.hasPendingEdit && session.iProposedEdit;
    final l10n = AppLocalizations.of(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isPast
        ? (isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF5F3FF))
        : AppColors.cardWhite;
    if (hasPendingOutgoing) cardColor = AppColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: hasPendingIncoming
              ? Border.all(color: AppColors.warning, width: 1.5)
              : hasPendingOutgoing
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
          boxShadow: isPast
              ? null
              : const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: InkWell(
          onTap: () => _showDetailSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dt.day.toString(),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: isPast ? AppColors.muted : AppColors.primary),
                ),
                Text(
                  _monthAbbr(dt.month, l10n),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: isPast ? AppColors.muted : AppColors.primary),
                ),
              ],
            ),
            title: Text(
              session.partnerAlias,
              style: tt.titleSmall?.copyWith(color: isPast ? AppColors.muted : AppColors.navy),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeRange(dt, session.uhrzeitEnde, l10n),
                    style: tt.bodySmall?.copyWith(color: isPast ? AppColors.muted : AppColors.navy),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusChip(status: session.status),
                      if (hasPendingIncoming) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(l10n.pendingChange,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning)),
                        ),
                      ],
                      if (hasPendingOutgoing) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_empty_rounded, size: 10, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(l10n.pendingOutgoing,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            trailing: Icon(Icons.chevron_right_rounded,
                color: isPast ? AppColors.muted : AppColors.navy),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SessionDetailSheet(session: session),
    );
  }

  String _fmt2(int n) => n.toString().padLeft(2, '0');

  String _timeRange(DateTime dt, String? ende, AppLocalizations l10n) {
    final start = '${_fmt2(dt.hour)}:${_fmt2(dt.minute)}';
    final wd = l10n.weekdayAbbrs[dt.weekday];
    if (ende == null || ende.length < 5) return '$wd, $start Uhr';
    return '$wd, $start – ${ende.substring(0, 5)} Uhr';
  }

  String _monthAbbr(int m, AppLocalizations l10n) => l10n.monthAbbrs[m];
}

// ── Session Detail Sheet ──────────────────────────────────────────────────────

class _SessionDetailSheet extends ConsumerStatefulWidget {
  final StudySession session;
  const _SessionDetailSheet({required this.session});

  @override
  ConsumerState<_SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends ConsumerState<_SessionDetailSheet> {
  bool _editing = false;
  late DateTime _newDate;
  late TimeOfDay _newTime;
  TimeOfDay? _newTimeEnde;

  @override
  void initState() {
    super.initState();
    _newDate = widget.session.dateTime;
    _newTime = TimeOfDay(hour: widget.session.dateTime.hour, minute: widget.session.dateTime.minute);
    final ende = widget.session.uhrzeitEnde;
    if (ende != null && ende.length >= 5) {
      final parts = ende.split(':');
      _newTimeEnde = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  String _fmtDate(String d) {
    final p = d.split('-');
    return p.length == 3 ? '${p[2]}.${p[1]}.${p[0]}' : d;
  }

  String _fmtDateDt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _fmtTime(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  String _fmtTimeTod(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _showCancelDialog(BuildContext context, String sessionId) async {
    final l10n = AppLocalizations.of(context);
    final reasonCtrl = TextEditingController();
    String? validationError;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.cancelSessionTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.cancelSessionConfirm),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.cancelReason,
                  hintText: l10n.cancelReasonHint,
                  errorText: validationError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (_) {
                  if (validationError != null) {
                    setDialogState(() => validationError = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.back),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                final reason = reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim();
                if (reason != null) {
                  final blacklist = await ref.read(blacklistProvider.future);
                  final err = blacklist.checkChat(reason);
                  if (err != null) {
                    setDialogState(() => validationError = err);
                    return;
                  }
                }
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                final ok = await ref
                    .read(sessionsProvider.notifier)
                    .cancelSession(sessionId, reason: reason);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? l10n.sessionCancelled : l10n.cancelError),
                  ));
                }
              },
              child: Text(l10n.cancelButton),
            ),
          ],
        ),
      ),
    );
    reasonCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.session;
    final tt = Theme.of(context).textTheme;
    final isPast = !s.isUpcoming;
    final canEdit = (s.status == 'geplant' || s.status == 'bestaetigt') && !s.hasPendingEdit;
    final isIncomingEdit = s.hasPendingEdit && !s.iProposedEdit;
    final currentUserId = ref.read(profileProvider).profile?.id;
    final isIncomingRequest = s.isRequested && s.createdById != null && s.createdById != currentUserId;
    final canCancel = (s.status == 'geplant' || s.status == 'bestaetigt');

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFD0CDED), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Text(l10n.sessionWithPartner(s.partnerAlias), style: tt.titleLarge)),
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.proposeChange,
                  onPressed: () => setState(() => _editing = !_editing),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _InfoRow(icon: Icons.calendar_today_rounded, label: _fmtDate(s.datum)),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.access_time_rounded,
            label: s.uhrzeitEnde != null
                ? '${_fmtTime(s.uhrzeit)} – ${_fmtTime(s.uhrzeitEnde!)} Uhr'
                : '${_fmtTime(s.uhrzeit)} Uhr',
          ),
          const SizedBox(height: 8),
          _StatusChip(status: s.status),

          // Incoming session request
          if (isIncomingRequest) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(l10n.sessionRequest,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.sessionRequestFrom(s.partnerAlias),
                    style: tt.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                          onPressed: () async {
                            final ok = await ref
                                .read(sessionsProvider.notifier)
                                .declineSession(s.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? l10n.declineSessionError : l10n.declineSessionError)));
                            }
                          },
                          child: Text(l10n.decline),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final ok = await ref
                                .read(sessionsProvider.notifier)
                                .acceptSession(s.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(ok ? l10n.acceptedSession : l10n.acceptSessionError)));
                            }
                          },
                          child: Text(l10n.accept),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Incoming change request
          if (isIncomingEdit) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_notifications_outlined, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(l10n.changeRequest,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.proposedDate(_fmtDate(s.proposedDatum!)), style: tt.bodySmall),
                  Text(
                    s.proposedUhrzeitEnde != null
                        ? l10n.proposedTimeRange(_fmtTime(s.proposedUhrzeit!), _fmtTime(s.proposedUhrzeitEnde!))
                        : '${l10n.proposeNewTime}: ${_fmtTime(s.proposedUhrzeit!)} Uhr',
                    style: tt.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                          onPressed: () async {
                            final ok = await ref.read(sessionsProvider.notifier).declineEdit(s.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              if (!ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.declineSessionError)));
                              }
                            }
                          },
                          child: Text(l10n.decline),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final ok = await ref.read(sessionsProvider.notifier).acceptEdit(s.id);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              if (ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.sessionCreated)));
                              }
                            }
                          },
                          child: Text(l10n.accept),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Outgoing change request pending
          if (s.hasPendingEdit && s.iProposedEdit) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.changeRequestSent,
                      style: tt.bodySmall?.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Edit form
          if (_editing) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(l10n.proposeNewTime, style: tt.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(_fmtDateDt(_newDate)),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context, initialDate: _newDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _newDate = d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_rounded, size: 16),
                    label: Text('${l10n.from}: ${_fmtTimeTod(_newTime)}'),
                    onPressed: () async {
                      final t = await showTimePicker24h(context, initialTime: _newTime);
                      if (t != null) setState(() => _newTime = t);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_filled_rounded, size: 16),
                    label: Text(_newTimeEnde != null ? '${l10n.until}: ${_fmtTimeTod(_newTimeEnde!)}' : '${l10n.until}: –'),
                    onPressed: () async {
                      final t = await showTimePicker24h(context, initialTime: _newTimeEnde ?? _newTime);
                      if (t != null) setState(() => _newTimeEnde = t);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                final ok = await ref.read(sessionsProvider.notifier).proposeEdit(
                  sessionId: s.id,
                  datum: _newDate,
                  uhrzeit: _newTime,
                  uhrzeitEnde: _newTimeEnde,
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? l10n.changeRequestSentSuccess : l10n.changeRequestError)),
                  );
                }
              },
              child: Text(l10n.requestChange),
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(l10n.cancelSession),
              onPressed: () => _showCancelDialog(context, s.id),
            ),
          ],
          if (isPast) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text(l10n.deleteSession),
              onPressed: () async {
                final ok = await ref
                    .read(sessionsProvider.notifier)
                    .deleteSession(s.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? l10n.sessionDeleted : l10n.deleteError)),
                  );
                }
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (label, color) = switch (status) {
      'bestaetigt' => (l10n.statusConfirmed, AppColors.success),
      'abgesagt' => (l10n.statusCancelled, AppColors.error),
      'angefragt' => (l10n.statusRequested, AppColors.warning),
      _ => (l10n.statusPlanned, AppColors.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Create Session Sheet ──────────────────────────────────────────────────────

typedef _CreateCallback = Future<void> Function({
  required String matchId,
  required DateTime datum,
  required TimeOfDay uhrzeit,
  TimeOfDay? uhrzeitEnde,
  String? raumId,
});

class _CreateSessionSheet extends ConsumerStatefulWidget {
  final List<Match> matches;
  final _CreateCallback onSave;

  const _CreateSessionSheet({
    required this.matches,
    required this.onSave,
  });

  @override
  ConsumerState<_CreateSessionSheet> createState() =>
      _CreateSessionSheetState();
}

class _CreateSessionSheetState extends ConsumerState<_CreateSessionSheet> {
  Match? _selectedMatch;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay? _selectedTimeEnde;
  Room? _selectedRoom;
  bool _saving = false;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_selectedMatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectPartnerFirst)),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(
      matchId: _selectedMatch!.matchId,
      datum: _selectedDate,
      uhrzeit: _selectedTime,
      uhrzeitEnde: _selectedTimeEnde,
      raumId: _selectedRoom?.id,
    );
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rooms = ref.watch(roomsProvider);
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0CDED),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(l10n.newStudySession, style: tt.headlineSmall),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Match Picker ───────────────────────────────────────────────
          if (widget.matches.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.noMatchesForSession,
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<Match>(
              decoration: InputDecoration(
                labelText: l10n.studyPartner,
                prefixIcon: const Icon(Icons.people_outlined),
              ),
              hint: Text(l10n.choosePartner),
              items: widget.matches
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m.alias),
                      ))
                  .toList(),
              onChanged: (m) => setState(() => _selectedMatch = m),
            ),

          const SizedBox(height: 12),

          // ── Date & Time ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
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
                  icon: const Icon(Icons.access_time_rounded, size: 18),
                  label: Text('${l10n.from}: ${_fmtTime(_selectedTime)}'),
                  onPressed: () async {
                    final t = await showTimePicker24h(context, initialTime: _selectedTime);
                    if (t != null) setState(() => _selectedTime = t);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time_filled_rounded, size: 18),
                  label: Text(_selectedTimeEnde != null ? '${l10n.until}: ${_fmtTime(_selectedTimeEnde!)}' : '${l10n.until}: –'),
                  onPressed: () async {
                    final t = await showTimePicker24h(context, initialTime: _selectedTimeEnde ?? _selectedTime);
                    if (t != null) setState(() => _selectedTimeEnde = t);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Room ───────────────────────────────────────────────────────
          rooms.when(
            loading: () => LinearProgressIndicator(
              color: AppColors.primary,
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (roomList) => DropdownButtonFormField<Room>(
              decoration: InputDecoration(
                labelText: l10n.roomOptional,
                prefixIcon: const Icon(Icons.room_outlined),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.noRoom)),
                ...roomList.map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(r.displayName),
                    )),
              ],
              onChanged: (r) => setState(() => _selectedRoom = r),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _saving || widget.matches.isEmpty ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.createSession),
          ),
        ],
      ),
    );
  }
}
