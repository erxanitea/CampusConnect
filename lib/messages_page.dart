import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stateful_widget/chat_detail_page.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final DatabaseService _db = DatabaseService();
  int _navIndex = 3;

  /* ----------------------------------------------------------
     Static dummy groups / orgs  (optional – delete if you want)
     -------------------------------------------------------- */
  static const _dummyConversations = [
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
      'id': 'cs_club_static', // fake id
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
      'id': 'student_council_static',
    },
  ];

  /* ----------------------------------------------------------
                     Navigation helper
     -------------------------------------------------------- */
  void _handleNavTap(int index) {
    if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerts coming soon!')),
      );
      return;
    }
    final route = {0: '/home', 1: '/marketplace', 2: '/wall', 4: '/profile'}[index];
    if (route != null) {
      Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
    }
  }

  /* ----------------------------------------------------------
                     Build
     -------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      bottomNavigationBar: CampusBottomNav(
        currentIndex: _navIndex,
        onItemTapped: _handleNavTap,
      ),
      body: SafeArea(
        child: Column(
          children: [
            /*  header  */
            Container(
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
            ),

            /*  search bar  */
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            /*  real-time conversations  */
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.getConversationsStream(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // merge real + dummy (optional)
                  final real = (snap.data?.docs ?? []).map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final memberIds = List<String>.from(d['memberIds'] ?? []);
                    final otherId = memberIds.firstWhere(
                          (id) => id != FirebaseAuth.instance.currentUser!.uid,
                      orElse: () => memberIds.first,
                    );
                    return {
                      'id': doc.id,
                      'name': d['name'] ?? 'Chat',
                      'preview': d['lastMessage'] ?? '',
                      'time': DatabaseService.formatTime(
                          (d['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now()),
                      'badge': 0,
                      'emoji': d['emoji'] ?? '💬',
                      'avatarColor': Color(d['avatarColor'] ?? 0xFFE0F2FF),
                      'group': d['type'] != 'direct',
                      'accent': const Color(0xFF8D0B15),
                      'subtitle': d['type'] == 'direct' ? 'Direct message' : 'Group',
                    };
                  }).toList();

                  final merged = [...real, ..._dummyConversations];

                  if (merged.isEmpty) {
                    return Center(
                      child: Text(
                        'No conversations yet',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    itemBuilder: (context, index) => _ConversationTile(
                      conversation: merged[index],
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: merged.length,
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

/* ======================================================
   Conversation tile  (visually identical to your old one)
   ==================================================== */
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});
  final Map<String, dynamic> conversation;

  @override
  Widget build(BuildContext context) {
    final badge = conversation['badge'] as int? ?? 0;
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
                color: Colors.black.withOpacity(0.05),
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
                      backgroundColor: (conversation['avatarColor'] as Color?) ?? Colors.white,
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
                              label: 'Direct',
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
