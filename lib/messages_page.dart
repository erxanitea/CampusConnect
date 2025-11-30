import 'package:flutter/material.dart';
import 'package:stateful_widget/chat_detail_page.dart';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  static const List<Map<String, dynamic>> _conversations = [
    {
      'name': 'CS Club Group',
      'preview': "Don't forget the hackathon tomorrow!",
      'time': '2m ago',
      'badge': 3,
      'emoji': '💬',
      'avatarColor': Color(0xFFE0F2FF),
      'group': true,
      'accent': Color(0xFF8D0B15),
      'subtitle': 'Group • 13 members',
      'messages': [
        {
          'text': "Hey everyone! Don't forget the hackathon tomorrow!",
          'time': '10:30 AM',
          'isMe': false,
        },
        {
          'text': 'What time does it start?',
          'time': '10:32 AM',
          'isMe': true,
        },
        {
          'text': '9 AM sharp at the CS building!',
          'time': '10:33 AM',
          'isMe': false,
        },
      ],
    },
    {
      'name': 'Sarah M.',
      'preview': 'Is the textbook still available?',
      'time': '1h ago',
      'badge': 1,
      'emoji': '👩🏻',
      'avatarColor': Color(0xFFFFE9E2),
      'group': false,
      'accent': Color(0xFFE85D5D),
      'subtitle': 'Direct Message',
      'messages': [
        {
          'text': 'Is the textbook still available?',
          'time': '9:30 AM',
          'isMe': false,
        },
        {
          'text': 'Yep! Want to pick it up today?',
          'time': '9:32 AM',
          'isMe': true,
        },
      ],
    },
    {
      'name': 'Anonymous',
      'preview': 'Thanks for your advice on the ...',
      'time': '3h ago',
      'badge': 0,
      'emoji': '❓',
      'avatarColor': Color(0xFFF5F5F5),
      'group': false,
      'accent': Color(0xFF4A1C1C),
      'subtitle': 'Anonymous • Confession Reply',
      'messages': [
        {
          'text': 'Thanks for your advice on the wall post!',
          'time': '7:30 AM',
          'isMe': false,
        },
      ],
    },
    {
      'name': 'Student Council',
      'preview': 'New campus policy announce...',
      'time': '1d ago',
      'badge': 0,
      'emoji': '📣',
      'avatarColor': Color(0xFFE0F2FF),
      'group': true,
      'accent': Color(0xFF0D47A1),
      'subtitle': 'Group • Official Org',
      'messages': [
        {
          'text': 'Reminder: New campus policy announced today.',
          'time': '10:05 AM',
          'isMe': false,
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      bottomNavigationBar: CampusBottomNav(
        currentIndex: 3,
        onItemTapped: (index) => _handleNavTap(context, index),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _MessagesHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  return _ConversationTile(conversation: conversation);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: _conversations.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNavTap(BuildContext context, int index) {
    if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerts coming soon!')),
      );
      return;
    }

    String route;
    switch (index) {
      case 0:
        route = '/home';
        break;
      case 1:
        route = '/marketplace';
        break;
      case 2:
        route = '/wall';
        break;
      case 4:
        route = '/profile';
        break;
      default:
        return;
    }

    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFA500), Color(0xFFFF8C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Messages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Stay connected with your campus',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});

  final Map<String, dynamic> conversation;

  @override
  Widget build(BuildContext context) {
    final int badge = conversation['badge'] as int? ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatDetailPage(conversation: conversation),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF0E2DC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor:
                          (conversation['avatarColor'] as Color?) ?? Colors.white,
                      child: Text(
                        conversation['emoji'] as String? ?? '💬',
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    if (badge > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB01F1F),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              conversation['name'] as String? ?? 'Conversation',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4A1C1C),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (conversation['group'] == true)
                            _Chip(
                              label: 'Group',
                              color: const Color(0xFFFDEAD5),
                              textColor: const Color(0xFFB54B3A),
                            )
                          else
                            _Chip(
                              label: 'Anonymous',
                              color: const Color(0xFFF5F5F5),
                              textColor: const Color(0xFF4A1C1C),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              conversation['preview'] as String? ?? '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            conversation['time'] as String? ?? '',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ],
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color, required this.textColor});

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
