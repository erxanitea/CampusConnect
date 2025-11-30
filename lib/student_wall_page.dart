import 'package:flutter/material.dart';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';
import 'package:stateful_widget/widgets/floating_messages_button.dart';

class StudentWallPage extends StatefulWidget {
  const StudentWallPage({super.key});

  @override
  State<StudentWallPage> createState() => _StudentWallPageState();
}

class _StudentWallPageState extends State<StudentWallPage> {
  final TextEditingController _postController = TextEditingController();
  bool _postAsAnonymous = false;
  int _navIndex = 2;

  final List<Map<String, dynamic>> _posts = [
    {
      'author': 'Anonymous',
      'anonymous': true,
      'time': '3h ago',
      'category': 'Confession',
      'categoryColor': Color(0xFFE85D5D),
      'emoji': '🥤',
      'content':
          'Anyone else feel like finals week is never-ending? Coffee has become my best friend.',
      'likes': 156,
      'comments': 23,
      'boosts': 6,
    },
    {
      'author': 'Taylor S.',
      'anonymous': false,
      'time': '6h ago',
      'category': 'Opinion',
      'categoryColor': Color(0xFFF2A03C),
      'emoji': '📚',
      'content':
          'Hot take: the library should be open 24/7 during finals week. Who’s with me?',
      'likes': 98,
      'comments': 14,
      'boosts': 3,
    },
  ];

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      floatingActionButton: FloatingMessagesButton(
        badgeCount: 4,
        onPressed: () => Navigator.pushNamed(context, '/messages'),
        heroTag: 'wallMessagesFab',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CampusBottomNav(
        currentIndex: _navIndex,
        onItemTapped: _handleNavTap,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              _buildHeader(theme),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildCreatePostCard(theme),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Latest on the Wall',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF5B0B0C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._posts.map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _buildPostCard(post, theme),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB347), Color(0xFFFF7E29)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Wall',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share your thoughts freely',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1E4DE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a Post',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5B0B0C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "What's on your mind? Share a confession, opinion, or thought...",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _postAsAnonymous,
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF8D0B15);
                          }
                          return Colors.grey[300];
                        }),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFFF6D8D6);
                          }
                          return Colors.grey[300]?.withValues(alpha: 0.5);
                        }),
                        onChanged: (value) {
                          setState(() => _postAsAnonymous = value);
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Post as Anonymous',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _postAsAnonymous ? 'You\'ll appear as Anonymous' : 'Posting as You',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _postController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "What's on your mind? Share a confession, opinion, or thought...",
              fillColor: const Color(0xFFFFFBF8),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _handlePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D0B15),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Post',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, ThemeData theme) {
    final Color accent = post['categoryColor'] as Color? ?? const Color(0xFFFFD6C2);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: const Border(
            left: BorderSide(color: Color(0xFFB01F1F), width: 5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: accent.withValues(alpha: 0.2),
                    child: Text(
                      _avatarInitial(post),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF8D0B15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post['anonymous'] == true ? 'Anonymous' : post['author'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4A1C1C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          post['time'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                post['content'] as String,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF4A1C1C),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _reactionStat(Icons.favorite_border, post['likes'] as int),
                  const SizedBox(width: 18),
                  _reactionStat(Icons.chat_bubble_outline, post['comments'] as int),
                  const SizedBox(width: 18),
                  _reactionStat(Icons.share_outlined, post['boosts'] as int),
                  const Spacer(),
                  Text(
                    post['emoji'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reactionStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB74D3A), size: 20),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF5B0B0C),
          ),
        ),
      ],
    );
  }

  void _handleNavTap(int index) {
    if (index == _navIndex) return;
    if (index == 0) {
      Navigator.pop(context);
      return;
    }
    if (index == 1) {
      setState(() => _navIndex = index);
      Navigator.pushNamed(context, '/marketplace').then((_) {
        if (!mounted) return;
        setState(() => _navIndex = 2);
      });
      return;
    }
    if (index == 3) {
      setState(() => _navIndex = index);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alerts coming soon!')),
      );
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _navIndex = 2);
      });
      return;
    }
    if (index == 4) {
      setState(() => _navIndex = index);
      Navigator.pushNamed(context, '/profile').then((_) {
        if (!mounted) return;
        setState(() => _navIndex = 2);
      });
      return;
    }
    setState(() => _navIndex = index);
  }

  String _avatarInitial(Map<String, dynamic> post) {
    if (post['anonymous'] == true) return 'A';
    final author = (post['author'] as String?)?.trim();
    if (author == null || author.isEmpty) return 'U';
    return author.substring(0, 1).toUpperCase();
  }

  void _handlePost() {
    final text = _postController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share a thought before posting.')),
      );
      return;
    }

    final isAnon = _postAsAnonymous;
    final Map<String, dynamic> newPost = {
      'author': isAnon ? 'Anonymous' : 'You',
      'anonymous': isAnon,
      'time': 'Just now',
      'category': isAnon ? 'Confession' : 'Thought',
      'categoryColor': isAnon ? const Color(0xFFE85D5D) : const Color(0xFF8D0B15),
      'emoji': isAnon ? '🤫' : '💬',
      'content': text,
      'likes': 0,
      'comments': 0,
      'boosts': 0,
    };

    setState(() {
      _posts.insert(0, newPost);
      _postController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isAnon ? 'Anonymous confession posted!' : 'Shared with your name!'),
      ),
    );
  }
}
