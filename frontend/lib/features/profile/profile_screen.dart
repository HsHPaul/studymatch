import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/theme_provider.dart';
import '../../core/time_picker_utils.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/notifications/notifications_provider.dart';
import '../../shared/models/notification.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(notificationsProvider.notifier).load();
    });
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

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Passwort ändern'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Aktuelles Passwort',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) =>
                    v != null && v.isNotEmpty ? null : 'Pflichtfeld',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Neues Passwort',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (v) => v != null && v.length >= 8
                    ? null
                    : 'Mindestens 8 Zeichen',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Neues Passwort bestätigen',
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (v) => v == newCtrl.text
                    ? null
                    : 'Passwörter stimmen nicht überein',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final currentPw = currentCtrl.text;
              final newPw = newCtrl.text;
              Navigator.of(ctx).pop();
              final ok = await ref
                  .read(profileProvider.notifier)
                  .changePassword(
                    currentPassword: currentPw,
                    newPassword: newPw,
                  );
              if (ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Passwort erfolgreich geändert'),
                  ),
                );
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Account wirklich löschen?'),
        content: const Text(
          'Dein Account wird vollständig und unwiderruflich gelöscht – '
          'einschließlich Profil, Fächer, Verfügbarkeiten, Matches und Nachrichten. '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ja, Account löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref.read(profileProvider.notifier).deleteAccount();
    if (ok && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
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
      appBar: AppBar(
        title: const Text('Mein Profil'),
        actions: [
          _NotificationBell(),
          Consumer(builder: (context, ref, _) {
            final isDark = ref.watch(isDarkModeProvider);
            return IconButton(
              icon: Icon(isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined),
              tooltip: isDark ? 'Heller Modus' : 'Dunkler Modus',
              onPressed: () =>
                  ref.read(isDarkModeProvider.notifier).toggle(),
            );
          }),
          IconButton(
            icon: const Icon(Icons.password_outlined),
            onPressed: _showChangePasswordDialog,
            tooltip: 'Passwort ändern',
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
                  : _ProfileInfo(
                      profile: ps.profile!,
                      onEdit: () => _startEditing(ps),
                    ),
              const SizedBox(height: 20),
              _SubjectsSection(mySubjects: ps.mySubjects),
              const SizedBox(height: 20),
              _AvailabilitySection(availabilities: ps.myAvailabilities),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 8),
              TextButton(
                onPressed: ps.isSaving ? null : _confirmDeleteAccount,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                ),
                child: const Text('Account löschen'),
              ),
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
  final VoidCallback? onEdit;

  const _ProfileInfo({required this.profile, this.onEdit});

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
                    Row(
                      children: [
                        Expanded(
                          child: Text(profile.alias, style: tt.titleLarge),
                        ),
                        if (onEdit != null)
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            color: AppColors.primary,
                            tooltip: 'Bearbeiten',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            onPressed: onEdit,
                          ),
                      ],
                    ),
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

    final atLimit = mySubjects.length >= 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Meine Fächer',
          action: TextButton.icon(
            onPressed: atLimit
                ? null
                : () => _showAddSubjectDialog(context, ref, allSubjects),
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
        mySubjectCount: mySubjects.length,
        allSubjects: allSubjects,
        onAdd: (id) => ref.read(profileProvider.notifier).addSubject(id),
      ),
    );
  }
}

class _SubjectPickerDialog extends StatelessWidget {
  final Set<String> mySubjectIds;
  final int mySubjectCount;
  final AsyncValue<List<Subject>> allSubjects;
  final void Function(String id) onAdd;

  const _SubjectPickerDialog({
    required this.mySubjectIds,
    required this.mySubjectCount,
    required this.allSubjects,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final atLimit = mySubjectCount >= 5;
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fach hinzufügen'),
          const SizedBox(height: 4),
          Text(
            'max. 5 Fächer gleichzeitig ($mySubjectCount/5)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) + 2,
                  color: atLimit
                      ? Theme.of(context).colorScheme.error
                      : Colors.grey[600],
                ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (atLimit)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Du hast bereits die maximale Anzahl an Fächern erreicht. Entferne zuerst ein Fach, um ein neues hinzuzufügen.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              allSubjects.when(
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
          ],
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
                    child: Icon(
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.muted,
                        ),
                        tooltip: 'Bearbeiten',
                        onPressed: () => _showEditDialog(context, ref, a),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.muted,
                        ),
                        tooltip: 'Löschen',
                        onPressed: () => ref
                            .read(profileProvider.notifier)
                            .removeAvailability(a.id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AvailabilityDialog(
        title: 'Zeitfenster hinzufügen',
        initialWochentag: _wochentage[0],
        initialStart: const TimeOfDay(hour: 9, minute: 0),
        initialEnd: const TimeOfDay(hour: 11, minute: 0),
        onSave: (tag, s, e) => ref
            .read(profileProvider.notifier)
            .addAvailability(wochentag: tag, startTime: s, endTime: e),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    UserAvailability avail,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AvailabilityDialog(
        title: 'Zeitfenster bearbeiten',
        initialWochentag: avail.wochentag,
        initialStart: avail.startTime,
        initialEnd: avail.endTime,
        onSave: (tag, s, e) => ref
            .read(profileProvider.notifier)
            .updateAvailability(
              id: avail.id,
              wochentag: tag,
              startTime: s,
              endTime: e,
            ),
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
  final String title;
  final String initialWochentag;
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final void Function(String, TimeOfDay, TimeOfDay) onSave;

  const _AvailabilityDialog({
    required this.title,
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
      title: Text(widget.title),
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
                    final t = await showTimePicker24h(context, initialTime: _start);
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
                    final t = await showTimePicker24h(context, initialTime: _end);
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

// ── Notification Bell ─────────────────────────────────────────────────────────

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final unread = state.unreadCount;

    return IconButton(
      tooltip: 'Benachrichtigungen',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
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
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const _NotificationSheet(),
      ),
    );
  }
}

// ── Notification Sheet ────────────────────────────────────────────────────────

class _NotificationSheet extends ConsumerWidget {
  const _NotificationSheet();

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: const Color(0xFFD0CDED),
                  borderRadius: BorderRadius.circular(2)),
            ),
            Row(
              children: [
                Expanded(
                    child: Text('Benachrichtigungen', style: tt.titleLarge)),
                if (state.unreadCount > 0)
                  TextButton(
                    onPressed: () =>
                        ref.read(notificationsProvider.notifier).markAllRead(),
                    child: const Text('Alle lesen'),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () =>
                      ref.read(notificationsProvider.notifier).load(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 48, color: AppColors.muted),
                              const SizedBox(height: 12),
                              Text('Keine Benachrichtigungen',
                                  style: tt.bodyMedium
                                      ?.copyWith(color: AppColors.muted)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          itemCount: state.notifications.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final n = state.notifications[i];
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: n.isRead
                                    ? AppColors.background
                                    : AppColors.primaryLight,
                                child: Icon(
                                  Icons.notifications_rounded,
                                  size: 20,
                                  color: n.isRead
                                      ? AppColors.muted
                                      : AppColors.primary,
                                ),
                              ),
                              title: Text(n.title,
                                  style: tt.titleSmall?.copyWith(
                                      fontWeight: n.isRead
                                          ? FontWeight.normal
                                          : FontWeight.w700)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(n.body, style: tt.bodySmall),
                                  const SizedBox(height: 4),
                                  Text(_fmtDate(n.createdAt),
                                      style: tt.bodySmall
                                          ?.copyWith(color: AppColors.muted)),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 20),
                                color: AppColors.muted,
                                tooltip: 'Löschen',
                                onPressed: () => ref
                                    .read(notificationsProvider.notifier)
                                    .deleteNotification(n.id),
                              ),
                              onTap: n.isRead
                                  ? null
                                  : () => ref
                                      .read(notificationsProvider.notifier)
                                      .markRead(n.id),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
