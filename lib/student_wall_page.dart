import 'package:flutter/material.dart';
import 'dart:async';
import 'package:stateful_widget/widgets/campus_bottom_nav.dart';
import 'package:stateful_widget/widgets/floating_messages_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/models/post_model.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:stateful_widget/widgets/post_card.dart';
import 'package:stateful_widget/widgets/comment_sheet.dart';

class StudentWallPage extends StatefulWidget {
  const StudentWallPage({super.key});

  @override
  State<StudentWallPage> createState() => _StudentWallPageState();
}

class _StudentWallPageState extends State<StudentWallPage> {

  int _navIndex = 1;

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
        if (ModalRoute.of(context)?.settings.name != '/alerts') {
          Navigator.pushReplacementNamed(context, '/alerts');
        }
        break;
      case 4:
        if (ModalRoute.of(context)?.settings.name != '/profile') {
          Navigator.pushReplacementNamed(context, '/profile');
        }
        break;
    }
  }


  final TextEditingController _postController = TextEditingController();
  bool _postAsAnonymous = false;
  bool _isPosting = false;
  final DatabaseService _databaseService = DatabaseService();

  Stream<QuerySnapshot>? _postsStream;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _loadPosts() {
    _postsStream = _databaseService.getPostsStream(limit: 50);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F2),
      floatingActionButton: FloatingMessagesButton(
        badgeCount: 4,
        onPressed: () {},
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
                    if (_postsStream != null)
                      StreamBuilder<QuerySnapshot>(
                        stream: _postsStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return _buildEmptyState();
                          }

                          final posts = snapshot.data!.docs
                              .map((doc) => Post.fromFirestore(doc))
                              .toList();

                          return Column(
                            children: posts
                                .map((post) => Padding(
                                      padding: const EdgeInsets.only(bottom: 18),
                                      child: _buildPostCard(post, theme),
                                    ))
                                .toList(),
                          );
                        },
                      )
                    else
                      const CircularProgressIndicator(),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF921126), Color(0xFFD4372A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Student Wall',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Share your thoughts freely',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.article_outlined,
                color: Colors.white,
                size: 28,
              ),
            ],
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
            color: Colors.black.withOpacity(0.03),
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
                          return Colors.grey[300]?.withOpacity(0.5);
                        }),
                        onChanged: _isPosting
                            ? null
                            : (value) {
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
            enabled: !_isPosting,
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
            child: _isPosting
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
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

  Future<void> _handlePost() async {
    final text = _postController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share a thought before posting')),
      );
      return;
    }

    try {
      setState(() => _isPosting = true);

      final category = 'Confession';
      final emoji = _postAsAnonymous ? '🤫' : '💬';

      await _databaseService.createPost(
        content: text,
        isAnonymous: _postAsAnonymous,
        category: category,
        emoji: emoji,
      );

      _postController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_postAsAnonymous
              ? 'Anonymous confession posted'
              : 'Public confession posted'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  Widget _buildPostCard(Post post, ThemeData theme) {
   return PostCard(post: post); 
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 60,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your thoughts!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Confession':
        return const Color(0xFFE85D5D);
      // case 'Opinion': return const Color(0xfff2a03c);
      default:
        return const Color(0xFF8D0B15);
    }
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

  String _getAvatarInitial(String name) {
    if (name.isEmpty) return 'UN';
    return name[0].toUpperCase();
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(
        postId: postId,
        databaseService: _databaseService,
      ), 
    );
  }
}
