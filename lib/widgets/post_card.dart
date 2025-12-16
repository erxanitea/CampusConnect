import 'package:flutter/material.dart';
import 'package:stateful_widget/models/post_model.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/widgets/share_to_picker_bottom_sheet.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stateful_widget/widgets/comment_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;
  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final DatabaseService _db = DatabaseService();
  bool? _isLiked;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likesCount;
    _checkLike();
  }

  Future<void> _checkLike() async {
    final liked = await _db.checkIfLiked(widget.post.id);
    setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    if (_isLiked == null) return;
    final oldLiked = _isLiked!;
    final oldCount = _likeCount;

    setState(() {
      _isLiked = !oldLiked;
      _likeCount += _isLiked! ? 1 : 0;
    });

    try {
      final newState = await _db.toggleLike(widget.post.id, widget.post.authorId);
      setState(() {
        _isLiked = newState;
        _likeCount = newState
            ? widget.post.likesCount + 1
            : widget.post.likesCount - 1;
      });
    } catch (_) {
      setState(() {
        _isLiked = oldLiked;
        _likeCount = oldCount;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')),
      );
    }
   }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentSheet(
        postId: widget.post.id,
        databaseService: _db,
      ),
    );
  }

  void _shareExternal() {
    final text = '${widget.post.isAnonymous ? 'Anonymous' : widget.post.authorName}: '
                 '${widget.post.content}\n\nhttps://campusconnect.app/post/${widget.post.id}';
    Share.share(text);
  }

  void _shareToChat() {
    showModalBottomSheet(
      context: context,
      builder: (_) => ShareToPickerBottomSheet(post: widget.post, db: _db),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final isOrganizationAnnouncement = post.category == 'Organization Announcement';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFEDE4E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(theme, post),
          const SizedBox(height: 16),
          
            if (isOrganizationAnnouncement) 
              _buildOrganizationAnnouncementContent(post, theme)
            else
              _buildRegularPostContent(post, theme),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEBD9D4), thickness: 0.8),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconStat(
                Icons.thumb_up_alt_outlined, 
                _likeCount,
                color: _isLiked == true ? const Color(0xFF8D0B15) : null,
                onTap: _toggleLike,
              ),
              _iconStat(
                Icons.chat_bubble_outline,
                post.commentsCount,
                onTap: _openComments,
              ),
              _iconStat(
                Icons.share_outlined,
                post.sharesCount, 
                onTap: () {
                  // simple choice: external or to chat
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.link),
                          title: const Text('Share externally'),
                          onTap: () {
                            Navigator.pop(context);
                            _shareExternal();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.chat),
                          title: const Text('Share to conversation'),
                          onTap: () {
                            Navigator.pop(context);
                            _shareToChat();
                          },
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(ThemeData theme, Post post) {
    final bool isOrg = post.category == 'Announcement';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: post.category == 'Confession' ? const Color(0xFF0EA89B).withOpacity(0.2) 
                         : isOrg
                         ? const Color(0xFF0EA89B).withOpacity(0.2)
                         : const Color(0xFFE0F2FF),
          child: Text(
            post.isAnonymous ? 'A' : post.authorName[0].toUpperCase(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: post.category == 'Confession' ? const Color(0xFFE85D5D)
                                                   : isOrg
                                                   ? const Color(0xFF0EA89B)
                                                   : const Color(0xFF0D47A1),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.isAnonymous ? 'Anonymous' : post.authorName, 
                style: theme.textTheme.titleMedium 
                       ?.copyWith(fontWeight: FontWeight.w700)
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (isOrg) _chip(Icons.verified, 'Official Organization', const Color(0xFF0EA89B))
                  else _chip(Icons.chat_bubble_outline, post.category, Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DatabaseService.formatTime(post.createdAt),
                    style: theme.textTheme.bodySmall ?.copyWith(color: Colors.grey[600])
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizationAnnouncementContent(Post post, ThemeData theme) {
  // Split content into title and description
  final content = post.content;
  final lines = content.split('\n\n');
  final title = lines.isNotEmpty ? lines[0] : '';
  final description = lines.length > 1 ? lines.sublist(1).join('\n\n') : '';

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // TITLE - Bold and larger
      Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF4E2A3A),
          fontSize: 20,
          height: 1.3,
        ),
      ),
      const SizedBox(height: 12),
      
      // DESCRIPTION - Regular text
      if (description.isNotEmpty) ...[
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF4E2A3A),
            height: 1.4,
          ),
        ),
      ],
    ],
  );
}

Widget _buildRegularPostContent(Post post, ThemeData theme) {
  return Text(
    post.content,
    style: theme.textTheme.bodyLarge?.copyWith(
      color: const Color(0xFF4E2A3A),
      height: 1.4,
    ),
  );
}

Widget _chip(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min, 
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600, 
            color: color,
          ),
        ),
      ],
    ),
  );
}

  Widget _iconStat(IconData icon, int count, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap == null || _isLiked == null
        ? null
        : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? const Color(0xFFB54B3A)),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF5B0B0C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
