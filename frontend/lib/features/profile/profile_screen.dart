import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../features/auth/auth_provider.dart';
import '../../shared/models/subject.dart';
import '../../shared/models/user.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'profile_provider.dart';

const _wochentage = [
  'montag',
  'dienstag',
  'mittwoch',
  'donnerstag',
  'freitag',
  'samstag',
];

const _wochentageLabels = {
  'montag': 'Montag',
  'dienstag': 'Dienstag',
  'mittwoch': 'Mittwoch',
  'donnerstag': 'Donnerstag',
  'freitag': 'Freitag',
  'samstag': 'Samstag',
};

const _lernstilOptions = {
  'still': 'Ruhig / Still',
  'gemischt': 'Gemischt',
  'diskutierend': 'Diskutierend',
};

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _aliasCtrl;
  late TextEditingController _studiengangCtrl;
  late TextEditingController _bioCtrl;
  String? _selectedLernstil;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _aliasCtrl = TextEditingController();
    _studiengangCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    _studiengangCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _startEditing(ProfileState ps) {
    _aliasCtrl.text = ps.profile?.alias ?? '';
    _studiengangCtrl.text = ps.profile?.studiengang ?? '';
    _bioCtrl.text = ps.profile?.bio ?? '';
    _selectedLernstil = ps.profile?.lernstil;
    setState(() => _editing = true);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(profileProvider.notifier).updateProfile(
          alias: _aliasCtrl.text.trim(),
          studiengang: _studiengangCtrl.text.trim(),
          lernstil: _selectedLernstil,
          bio: _bioCtrl.text.trim(),
        );
    if (ok && mounted) setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final ps = ref.watch(profileProvider);

    if (ps.isLoading) {
      return const Scaffold(body: LoadingIndicator(message: 'Profil laden…'));
    }
    if (ps.profile == null) {
      return Scaffold(
        body: ErrorView(
          message: ps.error ?? 'Profil konnte nicht geladen werden',
          onRetry: () => ref.read(profileProvider.notifier).load(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mein Profil'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _startEditing(ps),
              tooltip: 'Bearbeiten',
            ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            tooltip: 'Abmelden',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(profileProvider.notifier).load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ps.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    ps.error!,
                    style: const TextStyle(color: AppColors.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              _editing
                  ? _EditForm(
                      formKey: _formKey,
                      aliasCtrl: _aliasCtrl,
                      studiengangCtrl: _studiengangCtrl,
                      bioCtrl: _bioCtrl,
                      selectedLernstil: _selectedLernstil,
                      onLernstilChanged: (v) =>
                          setState(() => _selectedLernstil = v),
                      onSave: _saveProfile,
                      onCancel: () => setState(() => _editing = false),
                      isSaving: ps.isSaving,
                    )
                  : _ProfileInfo(profile: ps.profile!),
              const SizedBox(height: 20),
              _SubjectsSection(mySubjects: ps.mySubjects),
              const SizedBox(height: 20),
              _AvailabilitySection(availabilities: ps.myAvailabilities),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Info Card ─────────────────────────────────────────────────────────

class _ProfileInfo extends StatelessWidget {
  final UserProfile profile;

  const _ProfileInfo({required this.profile});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  profile.alias[0].toUpperCase(),
                  style: tt.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile.alias, style: tt.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      profile.email,
                      style: tt.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile.studiengang != null || profile.lernstil != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
          ],
          if (profile.studiengang != null)
            _InfoRow(
              icon: Icons.school_outlined,
              label: profile.studiengang!,
            ),
          if (profile.lernstil != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.psychology_outlined,
              label: _lernstilOptions[profile.lernstil] ?? profile.lernstil!,
            ),
          ],
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              profile.bio!,
              style: tt.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
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
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

// ── Edit Form ─────────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController aliasCtrl;
  final TextEditingController studiengangCtrl;
  final TextEditingController bioCtrl;
  final String? selectedLernstil;
  final ValueChanged<String?> onLernstilChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final bool isSaving;

  const _EditForm({
    required this.formKey,
    required this.aliasCtrl,
    required this.studiengangCtrl,
    required this.bioCtrl,
    required this.selectedLernstil,
    required this.onLernstilChanged,
    required this.onSave,
    required this.onCancel,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              controller: aliasCtrl,
              decoration: const InputDecoration(
                labelText: 'Anzeigename',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) =>
                  v != null && v.trim().length >= 2 ? null : 'Mindestens 2 Zeichen',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: studiengangCtrl,
              decoration: const InputDecoration(
                labelText: 'Studiengang',
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedLernstil,
              decoration: const InputDecoration(
                labelText: 'Lernstil',
                prefixIcon: Icon(Icons.psychology_outlined),
              ),
              items: _lernstilOptions.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: onLernstilChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: bioCtrl,
              decoration: const InputDecoration(
                labelText: 'Über mich (Bio)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isSaving ? null : onSave,
                    child: isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subjects Section ──────────────────────────────────────────────────────────

class _SubjectsSection extends ConsumerWidget {
  final List<Subject> mySubjects;

  const _SubjectsSection({required this.mySubjects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSubjects = ref.watch(allSubjectsProvider);
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Meine Fächer',
          action: TextButton.icon(
            onPressed: () => _showAddSubjectDialog(context, ref, allSubjects),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Hinzufügen'),
          ),
        ),
        const SizedBox(height: 10),
        if (mySubjects.isEmpty)
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
            padding: const EdgeInsets.all(16),
            child: Text(
              'Noch keine Fächer eingetragen.',
              style: tt.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mySubjects
                .map((s) => Chip(
                      label: Text(s.displayName),
                      deleteIcon: const Icon(Icons.close_rounded, size: 15),
                      onDeleted: () =>
                          ref.read(profileProvider.notifier).removeSubject(s.id),
                    ))
                .toList(),
          ),
      ],
    );
  }

  void _showAddSubjectDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Subject>> allSubjects,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _SubjectPickerDialog(
        mySubjectIds: mySubjects.map((s) => s.id).toSet(),
        allSubjects: allSubjects,
        onAdd: (id) => ref.read(profileProvider.notifier).addSubject(id),
      ),
    );
  }
}

class _SubjectPickerDialog extends StatelessWidget {
  final Set<String> mySubjectIds;
  final AsyncValue<List<Subject>> allSubjects;
  final void Function(String id) onAdd;

  const _SubjectPickerDialog({
    required this.mySubjectIds,
    required this.allSubjects,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fach hinzufügen'),
      content: SizedBox(
        width: 320,
        child: allSubjects.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => Text('Fehler: $e'),
          data: (subjects) {
            final available =
                subjects.where((s) => !mySubjectIds.contains(s.id)).toList();
            if (available.isEmpty) {
              return const Text('Alle Fächer bereits hinzugefügt.');
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: available.length,
              itemBuilder: (context, i) {
                final s = available[i];
                return ListTile(
                  title: Text(s.name),
                  subtitle: s.kuerzel != null ? Text(s.kuerzel!) : null,
                  onTap: () {
                    onAdd(s.id);
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}

// ── Availability Section ──────────────────────────────────────────────────────

class _AvailabilitySection extends ConsumerWidget {
  final List<UserAvailability> availabilities;

  const _AvailabilitySection({required this.availabilities});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Meine Verfügbarkeit',
          action: TextButton.icon(
            onPressed: () => _showAddDialog(context, ref),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Hinzufügen'),
          ),
        ),
        const SizedBox(height: 10),
        if (availabilities.isEmpty)
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
            padding: const EdgeInsets.all(16),
            child: Text(
              'Noch keine Zeitfenster eingetragen.',
              style: tt.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          )
        else
          ...availabilities.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _wochentageLabels[a.wochentag] ?? a.wochentag,
                    style: tt.titleSmall,
                  ),
                  subtitle: Text(
                    a.timeRange,
                    style: tt.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.muted,
                    ),
                    onPressed: () => ref
                        .read(profileProvider.notifier)
                        .removeAvailability(a.id),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    String selectedTag = _wochentage[0];
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 11, minute: 0);

    await showDialog<void>(
      context: context,
      builder: (ctx) => _AvailabilityDialog(
        initialWochentag: selectedTag,
        initialStart: start,
        initialEnd: end,
        onSave: (tag, s, e) {
          ref
              .read(profileProvider.notifier)
              .addAvailability(wochentag: tag, startTime: s, endTime: e);
        },
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ── Availability Dialog ───────────────────────────────────────────────────────

class _AvailabilityDialog extends StatefulWidget {
  final String initialWochentag;
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final void Function(String, TimeOfDay, TimeOfDay) onSave;

  const _AvailabilityDialog({
    required this.initialWochentag,
    required this.initialStart,
    required this.initialEnd,
    required this.onSave,
  });

  @override
  State<_AvailabilityDialog> createState() => _AvailabilityDialogState();
}

class _AvailabilityDialogState extends State<_AvailabilityDialog> {
  late String _wochentag;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _wochentag = widget.initialWochentag;
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Zeitfenster hinzufügen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _wochentag,
            decoration: const InputDecoration(labelText: 'Wochentag'),
            items: _wochentage
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(_wochentageLabels[d] ?? d),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _wochentag = v!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text('Von: ${_fmtTime(_start)}'),
                  onPressed: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _start);
                    if (t != null) setState(() => _start = t);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text('Bis: ${_fmtTime(_end)}'),
                  onPressed: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _end);
                    if (t != null) setState(() => _end = t);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () {
            if (_end.hour < _start.hour ||
                (_end.hour == _start.hour && _end.minute <= _start.minute)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Endzeit muss nach Startzeit liegen')),
              );
              return;
            }
            widget.onSave(_wochentag, _start, _end);
            Navigator.of(context).pop();
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
