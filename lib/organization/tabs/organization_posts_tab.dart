import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stateful_widget/services/database/organization_service.dart';
import 'package:stateful_widget/models/announcement_model.dart';

class OrganizationPostsTab extends StatefulWidget {
  final String organizationName;
  final String organizationId;

  const OrganizationPostsTab({
    super.key,
    required this.organizationName,
    required this.organizationId,
  });

  @override
  State<OrganizationPostsTab> createState() => _OrganizationPostsTabState();
}

class _OrganizationPostsTabState extends State<OrganizationPostsTab> {
  final OrganizationService _organizationService = OrganizationService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isPosting = false;
  String? _editingAnnouncementId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _postAnnouncement() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      if (_editingAnnouncementId != null) {
        await _organizationService.updateAnnouncement(
          organizationId: widget.organizationId,
          announcementId: _editingAnnouncementId!,
          title: _titleController.text,
          description: _descriptionController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement updated successfully')),
          );
        }
      } else {
        await _organizationService.postAnnouncement(
          organizationId: widget.organizationId,
          title: _titleController.text,
          description: _descriptionController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement posted successfully')),
          );
        }
      }

      _titleController.clear();
      _descriptionController.clear();
      setState(() => _editingAnnouncementId = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  void _editAnnouncement(Announcement announcement) {
    setState(() {
      _editingAnnouncementId = announcement.id;
      _titleController.text = announcement.title;
      _descriptionController.text = announcement.description;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingAnnouncementId = null;
      _titleController.clear();
      _descriptionController.clear();
    });
  }

  Future<void> _archiveAnnouncement(Announcement announcement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Announcement'),
        content: const Text('Are you sure you want to archive this announcement? It will no longer be visible to members.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8D0B15),
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _organizationService.archiveAnnouncement(
        widget.organizationId,
        announcement.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement archived successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error archiving announcement: $e')),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF9F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1E4DE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_outlined, color: Color(0xFF8D0B15)),
                    const SizedBox(width: 8),
                    Text(
                      _editingAnnouncementId != null ? 'Edit Announcement' : 'Create Announcement',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF4A1C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Announcement title...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Share an announcement with all members...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isPosting ? null : _postAnnouncement,
                        icon: const Icon(Icons.send, size: 18),
                        label: Text(_isPosting ? 'Posting...' : (_editingAnnouncementId != null ? 'Update' : 'Post')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8D0B15),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (_editingAnnouncementId != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelEdit,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFF8D0B15)),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Color(0xFF8D0B15)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Announcements',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF4A1C1C),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Announcement>>(
            stream: _organizationService.getOrganizationAnnouncements(widget.organizationId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final allAnnouncements = snapshot.data ?? [];
              final announcements = allAnnouncements.where((a) => !a.isArchived).toList();

              if (announcements.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No announcements yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return Column(
                children: announcements
                    .map((announcement) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAnnouncementCard(announcement),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCreator = currentUser?.uid == announcement.createdBy;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E4DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFFADBD2),
                backgroundImage: announcement.createdByPhotoUrl != null
                    ? NetworkImage(announcement.createdByPhotoUrl!)
                    : null,
                child: announcement.createdByPhotoUrl == null
                    ? const Icon(Icons.groups, color: Color(0xFF7C0010))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement.createdByName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4A1C1C),
                      ),
                    ),
                    Text(
                      _getTimeAgo(announcement.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC53529),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Official',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              if (isCreator) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editAnnouncement(announcement);
                    } else if (value == 'archive') {
                      _archiveAnnouncement(announcement);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18, color: Color(0xFF8D0B15)),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive, size: 18, color: Color(0xFF8D0B15)),
                          SizedBox(width: 8),
                          Text('Archive'),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF8D0B15)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            announcement.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF4A1C1C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            announcement.description,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _organizationService.likeAnnouncement(
                  widget.organizationId,
                  announcement.id,
                ),
                child: Icon(Icons.favorite_outline, size: 16, color: Colors.grey[600]),
              ),
              const SizedBox(width: 4),
              Text(
                '${announcement.likes}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${announcement.comments}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
