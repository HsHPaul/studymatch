import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../features/auth/auth_provider.dart';
import '../../shared/models/message.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;

  const ChatScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

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

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(chatProvider(widget.matchId).notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider(widget.matchId));
    final authState = ref.watch(authProvider);

    ref.listen(chatProvider(widget.matchId), (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
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
                    child: const Text('Erneut laden'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: chat.isLoading
                ? const LoadingIndicator(message: 'Nachrichten laden…')
                : chat.messages.isEmpty
                    ? const _EmptyChat()
                    : _MessageList(
                        messages: chat.messages,
                        currentUserId: authState.token ?? '',
                        scrollController: _scrollController,
                      ),
          ),
          _InputBar(controller: _controller, onSend: _send),
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
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
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
          Text('Noch keine Nachrichten.', style: tt.titleSmall),
          const SizedBox(height: 4),
          Text('Schreib die erste Nachricht!', style: tt.bodySmall),
        ],
      ),
    );
  }
}

// ── Message List ──────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;

  const _MessageList({
    required this.messages,
    required this.currentUserId,
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
        final isMe = _isOwnMessage(msg);
        return _MessageBubble(message: msg, isMe: isMe);
      },
    );
  }

  bool _isOwnMessage(Message msg) {
    return false;
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Nachricht…',
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
                      borderSide: const BorderSide(
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
