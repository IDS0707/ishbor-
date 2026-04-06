import 'package:flutter/material.dart';
import '../core/app_locale.dart';
import '../core/app_theme.dart';
import '../core/l10n.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

/// Full-screen real-time chat between a job seeker and a job poster.
///
/// [jobId] + [seekerUid] are used to derive the chatId.
/// [opponentName] is shown in the AppBar subtitle.
/// Both the seeker and the poster can open this screen.
class ChatScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String seekerUid;
  final String posterUid;
  final String opponentName;

  const ChatScreen({
    required this.jobId,
    required this.jobTitle,
    required this.seekerUid,
    required this.posterUid,
    required this.opponentName,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  String get _myUid => AuthService.currentUser?.uid ?? '';

  String _t(String k) => L10n.t(k, appLocale.value);

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_rebuild);
    appThemeMode.addListener(_rebuild);
  }

  @override
  void dispose() {
    appLocale.removeListener(_rebuild);
    appThemeMode.removeListener(_rebuild);
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    try {
      final u = AuthService.currentUser;
      final myName = u?.displayName ?? u?.email ?? u?.phoneNumber ?? '';
      await FirestoreService.sendMessage(
        jobId: widget.jobId,
        seekerUid: widget.seekerUid,
        senderUid: _myUid,
        text: text,
        posterUid: widget.posterUid,
        jobTitle: widget.jobTitle,
        senderName: myName,
      );
      // Scroll to bottom after send
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeMode.value == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F4FF);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final inputBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.jobTitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.opponentName,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Message list ────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<ChatMsg>>(
              stream: FirestoreService.messagesStream(
                  widget.jobId, widget.seekerUid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data ?? [];
                if (msgs.isEmpty) {
                  return Center(
                    child: Text(
                      _t('no_messages'),
                      style: TextStyle(color: textSecondary, fontSize: 15),
                    ),
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    final isMe = msg.senderUid == _myUid;
                    return _MsgBubble(
                      text: msg.text,
                      isMe: isMe,
                      time: _formatTime(msg.createdAt),
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ───────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
                12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 4,
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: _t('type_message'),
                      hintStyle: TextStyle(color: textSecondary, fontSize: 14),
                      filled: true,
                      fillColor: inputBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _send,
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MsgBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final String time;
  final bool isDark;

  const _MsgBubble({
    required this.text,
    required this.isMe,
    required this.time,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? const Color(0xFF2563EB)
                  : (isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    color: isMe
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
