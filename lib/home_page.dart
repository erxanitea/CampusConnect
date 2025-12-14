import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';
import 'package:stateful_widget/widgets/floating_messages_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/models/post_model.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stateful_widget/widgets/post_card.dart';
import 'package:stateful_widget/widgets/comment_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navIndex = 0;

  void _handleNavTap(int index) {
    setState(() {
      _navIndex = index;
    });

     switch (index) {
      case 0:
        if (ModalRoute.of(context)?.settings.name != '/home') {
          Navigator.pushReplacementNamed(context, '/home');
        }
        break;
      case 1:
        if (ModalRoute.of(context)?.settings.name != '/wall') {
          Navigator.pushReplacementNamed(context, '/wall');
        }
        break;
      case 2:
        if (ModalRoute.of(context)?.settings.name != '/marketplace') {
          Navigator.pushReplacementNamed(context, '/marketplace');
        }
        break;
      case 3:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alerts coming soon!')),
        );
        break;
      case 4:
        if (ModalRoute.of(context)?.settings.name != '/profile') {
          Navigator.pushReplacementNamed(context, '/profile');
        }
        break;
    }
  }


  final List<String> _filters = const ['All', 'Orgs', 'Confessions'];
  int _selectedFilter = 0;
  final DatabaseService _databaseService = DatabaseService();

  List<Post> _confessions = [];
  List<Post> _allPosts = [];
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot>? _postsSubscription;

  static const _recentMessages = [
    {
      'name': 'CS Club Group',
      'preview': "Don't forget the hackathon tomorrow!",
      'badge': 3,
      'color': Color(0xFFE0F2FF),
      'emoji': '💬',
    },
    {
      'name': 'Sarah M.',
      'preview': 'Is the textbook still available?',
      'badge': 1,
      'color': Color(0xFFFFE9E2),
      'emoji': '👩🏻',
    },
    {
      'name': 'Anonymous',
      'preview': 'Thanks for your advice!',
      'badge': 0,
      'color': Color(0xFFF5F5F5),
      'emoji': '❓',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    super.dispose();
  }

  void _loadPosts() {
    _isLoading = true;
    _postsSubscription = _databaseService.getPostsStream().listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _allPosts = [];
            _confessions = [];
          });
        }
        return;
      }
      final posts = snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList();
      final confessions = posts.where((post) => post.category == 'Confession').toList();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _allPosts = posts;
          _confessions = confessions;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading posts: $error');
    });
  }

  List<Post> get _displayedPosts {
    switch (_selectedFilter) {
      case 0:
        return _allPosts;
      case 1:
        return _allPosts.where((post) => post.category == 'Announcement').toList();
      case 2:
        return _confessions;
      default:
        return _allPosts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingMessagesButton(
        badgeCount: 4,
        onPressed: () => Navigator.pushNamed(context, '/messages'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CampusBottomNav(
        currentIndex: _navIndex,
        onItemTapped: _handleNavTap,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            children: [
              _buildHeroHeader(context),
              _buildFilterChips(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildRecentMessagesCard(theme),
                    const SizedBox(height: 18),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      )
                    else if (_displayedPosts.isEmpty)
                      _buildEmptyState(theme)
                    else
                      ..._displayedPosts.map(
                        (post) => Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: PostCard(post: post),
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

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C000F), Color(0xFFC63528)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CampusConnect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.18),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/');
                },
                icon: const Icon(Icons.logout, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your campus community hub',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      transform: Matrix4.translationValues(0, -26, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_filters.length, (index) {
            final bool active = index == _selectedFilter;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFEDD6D1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _filters[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF7C000F)
                          : Colors.grey[600],
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecentMessagesCard(ThemeData theme) {
  return StreamBuilder<QuerySnapshot>(
    stream: DatabaseService().getConversationsStream().take(3),
    builder: (context, snap) {
      if (!snap.hasData || snap.data!.docs.isEmpty) {
        return const SizedBox(); // hide if no chats
      }
      final conversations = snap.data!.docs.map((doc) {
        final d = doc.data() as Map<String, dynamic>;
        final memberIds = List<String>.from(d['memberIds'] ?? []);
        final otherId = memberIds.firstWhere((id) => id != FirebaseAuth.instance.currentUser!.uid,
            orElse: () => memberIds.first);
        return {
          'name': d['name'] ?? 'Chat',
          'preview': d['lastMessage'] ?? '',
          'badge': 0,
          'color': Color(d['avatarColor'] ?? 0xFFE0F2FF),
          'emoji': d['emoji'] ?? '💬',
        };
      }).toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF9F5), Color(0xFFFFF0EB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(26),
          border: const Border(left: BorderSide(color: Color(0xFFB01F1F), width: 5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Color(0xFF7C000F)),
                    const SizedBox(width: 8),
                    Text('Recent Messages', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/messages'),
                  child: Text('View All', style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFFBD2C1A))),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...conversations.take(3).map((c) => _messageRow(c, theme)).toList(),
          ],
        ),
      );
    },
  );
}

Widget _messageRow(Map<String, dynamic> c, ThemeData theme) {
  final bool hasBadge = c['badge'] as int > 0;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: c['color'] as Color,
          child: Text(c['emoji'] as String, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c['name'] as String, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(c['preview'] as String, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
        if (hasBadge) _buildBadge(c['badge'] as int),
      ],
    ),
  );
}


  Widget _reactionItem(IconData icon, int count, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB54B3A), size: 20),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF5B0B0C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, bool filled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF8D0B15) : const Color(0xFFF5E6E1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: filled ? Colors.white : const Color(0xFF8D0B15),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : const Color(0xFF8D0B15),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, {Color color = const Color(0xFF8D0B15)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            _selectedFilter == 0
                ? Icons.forum_outlined
                : _selectedFilter == 1
                    ? Icons.groups_outlined
                    : Icons.psychology_outlined,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateTitle(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getEmptyStateSubtitle(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedFilter == 2)
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/wall');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8D0B15),
                foregroundColor: Colors.white,
              ),
              child: const Text('Share Your First Confession'),
            ),
        ],
      ),
    );
  }

  String _getEmptyStateTitle() {
    switch (_selectedFilter) {
      case 0:
        return 'No posts yet';
      case 1:
        return 'No organization posts';
      case 2:
        return 'No confessions yet';
      default:
        return 'No content';
    }
  }

  String _getEmptyStateSubtitle() {
    switch (_selectedFilter) {
      case 0:
        return 'Be the first to share something!';
      case 1:
        return 'Organization announcements will appear here';
      case 2:
        return 'Share your anonymous thoughts on the Student Wall';
      default:
        return 'Check back soon';
    }
  }

  Color _getPostAvatarColor(Post post) {
    if (post.category == 'Confession') return const Color(0xFFE85D5D).withOpacity(0.2);
    if (post.category == 'Announcement') return const Color(0xFF0EA89B).withOpacity(0.2);
    return const Color(0xFFE0F2FF);
  }

  Color _getPostTextColor(Post post) {
    if (post.category == 'Confession') return const Color(0xFFE85D5D);
    if (post.category == 'Announcement') return const Color(0xFF0EA89B);
    return const Color(0xFF0D47A1);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Confession':
        return Icons.psychology_outlined;
      case 'Announcement':
        return Icons.verified;
      case 'Opinion':
        return Icons.lightbulb_outline;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  String _getAvatarInitial(String name) {
    if (name.isEmpty) return 'U';
    return name[0].toUpperCase();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${time.month}/${time.day}/${time.year}';
  }

  Future<void> _handleLike(Post post) async {
    try {
      await _databaseService.toggleLike(post.id, post.authorId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleComment(Post post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Comment on post'),
        content: Text('Comment functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(
        postId: postId,
        databaseService: _databaseService,
      ),
    );
  }

  void _handleShare(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing: "${post.content.substring(0, 30)}..."'),
      ),
    );
  }

  void _showReactions(Post post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reactions for post'),
          ],
        ),
      ),
    );
  }
}
