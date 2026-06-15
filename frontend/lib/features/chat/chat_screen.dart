import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/app_localizations.dart';
import '../../core/time_picker_utils.dart';
import '../../core/blacklist_service.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/matching/matching_provider.dart';
import '../../features/profile/profile_provider.dart';
import '../../features/sessions/sessions_provider.dart';
import '../../shared/models/message.dart';
import '../../shared/models/room.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'chat_provider.dart';
import 'unread_chats_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;

  const ChatScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String? _blacklistError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(pendingSessionsProvider(widget.matchId));
      ref.read(unreadChatsProvider.notifier).markRead(widget.matchId);
    });
    _controller.addListener(() {
      if (_blacklistError != null) setState(() => _blacklistError = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showSessionDialog(BuildContext context, WidgetRef ref, String matchId) async {
    final l10n = AppLocalizations.of(context);
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    TimeOfDay? selectedTimeEnde;
    Room? selectedRoom;

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    String fmtTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final rooms = ref.read(roomsProvider);
          return AlertDialog(
            title: Text(l10n.sessionProposalTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_rounded, size: 16),
                        label: Text(fmtDate(selectedDate)),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null) setS(() => selectedDate = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text('${l10n.from}: ${fmtTime(selectedTime)}'),
                        onPressed: () async {
                          final t = await showTimePicker24h(ctx, initialTime: selectedTime);
                          if (t != null) setS(() => selectedTime = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time_filled_rounded, size: 16),
                        label: Text(selectedTimeEnde != null ? '${l10n.until}: ${fmtTime(selectedTimeEnde!)}' : '${l10n.until}: –'),
                        onPressed: () async {
                          final t = await showTimePicker24h(ctx, initialTime: selectedTimeEnde ?? selectedTime);
                          if (t != null) setS(() => selectedTimeEnde = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                rooms.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (roomList) => DropdownButtonFormField<Room>(
                    decoration: InputDecoration(
                      labelText: l10n.roomOptional,
                      prefixIcon: const Icon(Icons.room_outlined),
                    ),
                    items: [
                      DropdownMenuItem(value: null, child: Text(l10n.noRoom)),
                      ...roomList.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))),
                    ],
                    onChanged: (r) => setS(() => selectedRoom = r),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final ok = await ref.read(sessionsProvider.notifier).createSession(
                    matchId: matchId,
                    datum: selectedDate,
                    uhrzeit: selectedTime,
                    uhrzeitEnde: selectedTimeEnde,
                    raumId: selectedRoom?.id,
                  );
                  if (context.mounted) {
                    ref.invalidate(pendingSessionsProvider(matchId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? l10n.sessionRequestSent : l10n.sessionRequestError)),
                    );
                  }
                },
                child: Text(l10n.sendRequest),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    final blacklist = await ref.read(blacklistProvider.future);
    final error = blacklist.checkChat(text);
    if (error != null) {
      if (mounted) setState(() => _blacklistError = error);
      return;
    }
    _controller.clear();
    await ref.read(chatProvider(widget.matchId).notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chat = ref.watch(chatProvider(widget.matchId));
    ref.watch(authProvider); // keep alive
    final myUserId = ref.watch(profileProvider).profile?.id ?? '';
    final partnerAlias = ref.watch(matchesProvider).asData?.value
        .where((m) => m.matchId == widget.matchId)
        .firstOrNull
        ?.alias ?? 'Chat';

    ref.listen(chatProvider(widget.matchId), (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
        ref.read(unreadChatsProvider.notifier).markRead(widget.matchId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l10n.backToMatches,
          onPressed: () => context.go('/matches'),
        ),
        title: Text(partnerAlias),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: () => ref.invalidate(pendingSessionsProvider(widget.matchId)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.circle,
              size: 12,
              color: chat.isConnected ? AppColors.success : AppColors.muted,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chat.error != null)
            Container(
              width: double.infinity,
              color: AppColors.error.withValues(alpha: 0.1),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chat.error!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(chatProvider(widget.matchId).notifier)
                        .refresh(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(l10n.chatReload),
                  ),
                ],
              ),
            ),
          _PendingSessionsBanner(matchId: widget.matchId),
          Expanded(
            child: chat.isLoading
                ? LoadingIndicator(message: l10n.chatLoading)
                : chat.messages.isEmpty
                    ? const _EmptyChat()
                    : _MessageList(
                        messages: chat.messages,
                        myUserId: myUserId,
                        partnerAlias: partnerAlias,
                        scrollController: _scrollController,
                      ),
          ),
          if (_blacklistError != null)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF3CD),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFF856404)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _blacklistError!,
                      style: const TextStyle(
                          color: Color(0xFF856404), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          _InputBar(
            controller: _controller,
            onSend: _send,
            onSession: () => _showSessionDialog(context, ref, widget.matchId),
          ),
        ],
      ),
    );
  }
}

// ── Empty Chat ────────────────────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 38,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.noMessages, style: tt.titleSmall),
          const SizedBox(height: 4),
          Text(l10n.writeFirstMessage, style: tt.bodySmall),
        ],
      ),
    );
  }
}

// ── Message List ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<Message> messages;
  final String myUserId;
  final String partnerAlias;
  final ScrollController scrollController;

  const _MessageList({
    required this.messages,
    required this.myUserId,
    required this.partnerAlias,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final isMe = msg.senderId == myUserId;
        final showName = !isMe &&
            (i == 0 || messages[i - 1].senderId != msg.senderId);
        return _MessageBubble(
          message: msg,
          isMe: isMe,
          senderName: showName ? partnerAlias : null,
        );
      },
    );
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String? senderName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  senderName!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.cardWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: isMe
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: tt.bodyMedium?.copyWith(
                      color: isMe ? Colors.white : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Pending Sessions Banner ───────────────────────────────────────────────────

class _PendingSessionsBanner extends ConsumerWidget {
  final String matchId;

  const _PendingSessionsBanner({required this.matchId});

  String _fmtDate(String datum) {
    final parts = datum.split('-');
    if (parts.length != 3) return datum;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  String _fmtTime(String uhrzeit) => uhrzeit.length >= 5 ? uhrzeit.substring(0, 5) : uhrzeit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(pendingSessionsProvider(matchId));

    return pending.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        if (sessions.isEmpty) return const SizedBox.shrink();
        return Container(
          color: AppColors.primaryLight,
          child: Column(
            children: sessions.map((s) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.sessionRequestBanner(_fmtDate(s.datum), _fmtTime(s.uhrzeit)),
                      style: TextStyle(fontSize: 13, color: AppColors.navy),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () async {
                      await ref.read(sessionsProvider.notifier).declineSession(s.id);
                      ref.invalidate(pendingSessionsProvider(matchId));
                    },
                    child: Text(l10n.decline),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () async {
                      final ok = await ref.read(sessionsProvider.notifier).acceptSession(s.id);
                      ref.invalidate(pendingSessionsProvider(matchId));
                      if (ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.acceptedSession)),
                        );
                      }
                    },
                    child: Text(l10n.accept),
                  ),
                ],
              ),
            )).toList(),
          ),
        );
      },
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onSession;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onSession,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded),
                color: AppColors.primary,
                tooltip: l10n.proposeSession,
                onPressed: onSession,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: l10n.messageHint,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(
                          color: Color(0xFFD0CDED), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(
                          color: Color(0xFFD0CDED), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  maxLines: null,
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: onSend,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                  minimumSize: Size.zero,
                ),
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
