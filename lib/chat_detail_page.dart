import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';
import 'package:stateful_widget/models/message_model.dart';

/* ----------------------------------------------------
   SINGLE FILE :  ChatDetailPage  (complete)
   -------------------------------------------------- */
class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key, required this.conversation});
  final Map<String, dynamic> conversation;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  int _navIndex = 3;
  final DatabaseService _db = DatabaseService();

  /* =========  BOTTOM-NAV HANDLER (existing)  ========= */
  void _handleNavTap(int index) {
    if (index == _navIndex) return;
    setState(() => _navIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/marketplace', (route) => false);
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, '/wall', (route) => false);
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, '/alerts', (route) => false);
        break;
      case 4:
        Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
        break;
    }
  }

  /* =========  BUILD  ========= */
  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    final accent = conversation['accent'] as Color? ?? const Color(0xFF8D0B15);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      bottomNavigationBar: CampusBottomNav(
        currentIndex: _navIndex,
        onItemTapped: _handleNavTap,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(conversation: conversation, accent: accent),
            const SizedBox(height: 12),

            /*  real-time messages  */
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.getMessagesStream(conversation['id'] as String),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final msgs = snap.data!.docs
                      .map((d) => Message.fromFirestore(d))
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (msgs.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    reverse: true,
                    itemCount: msgs.length,
                    itemBuilder: (context, index) {
                      final msg = msgs[index];
                      final bool isMe = msg.senderId == FirebaseAuth.instance.currentUser!.uid;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: isMe ? accent : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                                  bottomRight: Radius.circular(isMe ? 6 : 20),
                                ),
                                boxShadow: isMe
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.content,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : const Color(0xFF4A1C1C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DatabaseService.formatTime(msg.createdAt),
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.grey[600],
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            /*  composer  */
            _MessageComposer(
              accent: accent,
              conversationId: conversation['id'] as String,
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   HEADER  (your old UI, untouched)
   ======================================================= */
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.conversation, required this.accent});
  final Map<String, dynamic> conversation;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          CircleAvatar(
            radius: 26,
            backgroundColor: (conversation['avatarColor'] as Color?) ?? accent,
            child: Text(
              conversation['emoji'] as String? ?? '💬',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation['name'] as String? ?? 'Conversation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  conversation['subtitle'] as String? ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   COMPOSER  (new, real)
   ======================================================= */
class _MessageComposer extends StatefulWidget {
  const _MessageComposer({required this.accent, required this.conversationId});
  final Color accent;
  final String conversationId;

  @override
  State<_MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<_MessageComposer> {
  final _controller = TextEditingController();
  final DatabaseService _db = DatabaseService();
  bool _sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await _db.sendMessage(convId: widget.conversationId, text: text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_sending,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: _sending ? null : _send,
            backgroundColor: widget.accent.withOpacity(0.85),
            elevation: 0,
            child: _sending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
