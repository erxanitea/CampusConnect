import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stateful_widget/admin/admin_dashboard.dart';
import 'package:stateful_widget/admin/admin_analytics.dart';
import 'package:stateful_widget/admin/admin_reports.dart';
import 'package:stateful_widget/widgets/admin_bottom_nav.dart';
import 'package:stateful_widget/services/database/organization_service.dart';
import 'package:stateful_widget/models/organization_model.dart';
import 'dart:io';

class AdminOrganizations extends StatefulWidget {
  const AdminOrganizations({super.key});

  @override
  State<AdminOrganizations> createState() => _AdminOrganizationsState();
}

class _AdminOrganizationsState extends State<AdminOrganizations> {
  int _navIndex = 3;
  final OrganizationService _organizationService = OrganizationService();
  final ImagePicker _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _foundedDateController = TextEditingController();
  String _selectedCategory = 'Academic';
  String _selectedStatus = 'active';
  File? _selectedLogoFile;
  int _memberListRefreshKey = 0;

  static const _statsData = [
    {'title': 'Total Orgs', 'value': '0'},
    {'title': 'Avg Members', 'value': '0'},
    {'title': 'Active', 'value': '0'},
  ];

  @override
  void initState() {
    super.initState();
    _cleanupAndSyncAllMemberCounts();
  }

  Future<void> _cleanupAndSyncAllMemberCounts() async {
    try {
      print('Starting cleanup and sync of all organization member counts...');
      await _organizationService.syncAllOrganizationMemberCounts();
      print('All organization member counts synced successfully');
      if (mounted) {
        // Force a complete rebuild to refresh all StreamBuilders
        setState(() {});
        // Add a small delay to ensure Firestore has updated
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {});
      }
    } catch (e) {
      print('Error syncing member counts: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _foundedDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: AdminBottomNav(
          currentIndex: _navIndex,
          onItemTapped: (index) {
            setState(() {
              _navIndex = index;
            });
            _handleNavTap(index);
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      StreamBuilder(
                        stream: _organizationService.getOrganizationsStream(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Row(
                              children: _statsData.map((stat) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: _buildStatCard(stat),
                                  ),
                                );
                              }).toList(),
                            );
                          }

                          final orgs = snapshot.data!.docs;
                          final allOrgsList = orgs.map((doc) => Organization.fromSnapshot(doc)).toList();
                          final activeOrgsList = allOrgsList.where((org) => org.status == 'active').toList();
                          
                          final totalOrgs = allOrgsList.length;
                          final activeOrgs = activeOrgsList.length;
                          
                          int totalMembers = 0;
                          for (var org in activeOrgsList) {
                            totalMembers += org.memberCount;
                          }
                          final avgMembers = activeOrgs > 0 ? (totalMembers / activeOrgs).toStringAsFixed(0) : '0';

                          final stats = [
                            {'title': 'Total Orgs', 'value': totalOrgs.toString()},
                            {'title': 'Avg Members', 'value': avgMembers},
                            {'title': 'Active', 'value': activeOrgs.toString()},
                          ];

                          return Row(
                            children: stats.map((stat) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildStatCard(stat),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder(
                        stream: _organizationService.getOrganizationsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return _buildEmptyState();
                          }
                          return _buildTopOrganizationsCard(snapshot.data!.docs);
                        },
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C000F), Color(0xFFC63528)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Organizations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage campus organizations',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddOrganizationModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Org'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7C000F),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stat['title'] as String,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              stat['value'] as String,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.apartment_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Organizations Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first organization to get started',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopOrganizationsCard(List<dynamic> docs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Organizations',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Most active organizations by engagement',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ...docs.map((doc) {
            final org = Organization.fromSnapshot(doc);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrgItem(org),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrgItem(Organization org) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      org.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: org.status == 'archived'
                                ? Colors.grey[200]
                                : org.status == 'inactive'
                                    ? const Color(0xFFFFEBEE)
                                    : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            org.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: org.status == 'archived'
                                  ? Colors.grey[700]
                                  : org.status == 'inactive'
                                      ? const Color(0xFFC62828)
                                      : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showEditOrganizationModal(org),
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.blue[700],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Edit',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _showArchiveConfirmation(org),
                    icon: Icon(
                      Icons.archive_outlined,
                      size: 18,
                      color: Colors.orange[700],
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Archive',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildOrgStat(Icons.people_outline, '${org.memberCount}'),
              const SizedBox(width: 16),
              _buildOrgStat(Icons.article_outlined, '${org.postCount}'),
              const SizedBox(width: 16),
              _buildOrgStat(Icons.trending_up, '${org.engagementRate.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            org.category,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showOrgDetailsDialog(org),
              icon: Icon(
                Icons.visibility_outlined,
                size: 16,
                color: Colors.grey[700],
              ),
              label: Text(
                'View Details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrgStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showOrgDetailsDialog(Organization org) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        org.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        org.status,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      org.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  org.description ?? 'No description provided',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(Icons.email_outlined, org.email),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.calendar_today_outlined, 'Founded ${org.foundedDate ?? 'N/A'}'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.location_on_outlined, org.location),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('organizations')
                            .doc(org.id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final memberCount = snapshot.hasData
                              ? (snapshot.data!['memberCount'] ?? 0)
                              : org.memberCount;
                          return _buildDetailCard('Members', '$memberCount');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailCard('Total Posts', '${org.postCount}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailCard('Weekly Posts', '${org.weeklyPosts}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailCard('Avg Reactions', '${org.avgReactions}'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engagement Rate',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${org.engagementRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Members',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMembersDialog(
                        org.id,
                        org.name,
                        onMembersAdded: () {
                          // Refresh the members list in the dialog
                          setState(() {});
                        },
                      ),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Member'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C000F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('organizations')
                      .doc(org.id)
                      .collection('organization_members')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final memberDocs = snapshot.data?.docs ?? [];
                    
                    if (memberDocs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No members yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }

                    // Sort members by admin status
                    final sortedMemberDocs = memberDocs.toList();
                    sortedMemberDocs.sort((a, b) {
                      final aIsAdmin = a['role'] == 'admin' ? 0 : 1;
                      final bIsAdmin = b['role'] == 'admin' ? 0 : 1;
                      return aIsAdmin.compareTo(bIsAdmin);
                    });

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedMemberDocs.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                        itemBuilder: (context, index) {
                          final memberDoc = sortedMemberDocs[index];
                          final userId = memberDoc.id;
                          final role = memberDoc['role'] ?? 'member';
                          
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }
                              
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                              final displayName = (userData?['displayName'] ?? 'Unknown') as String;
                              final email = (userData?['email'] ?? '') as String;

                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            email,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (role == 'admin')
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFE0B2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Admin',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFE65100),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () async {
                                        try {
                                          await _organizationService
                                              .removeMemberFromOrganization(
                                            org.id,
                                            userId,
                                          );
                                          
                                          // Sync member count after removal
                                          await _organizationService
                                              .syncOrganizationMemberCount(org.id);
                                          
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '$displayName removed',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Remove member',
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getOrganizationMembers(String organizationId) async {
    try {
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(organizationId)
          .collection('organization_members')
          .get();

      final members = <Map<String, dynamic>>[];

      for (final memberDoc in membersSnapshot.docs) {
        final userId = memberDoc.id;
        final role = memberDoc['role'] ?? 'member';

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          members.add({
            'id': userId,
            'displayName': userData['displayName'] ?? 'Unknown',
            'email': userData['email'] ?? '',
            'role': role,
          });
        }
      }

      return members;
    } catch (e) {
      print('Error getting organization members: $e');
      return [];
    }
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogoImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedLogoFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showAddOrganizationModal() {
    _nameController.clear();
    _emailController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _logoUrlController.clear();
    _foundedDateController.clear();
    _selectedLogoFile = null;
    _selectedCategory = 'Academic';
    _selectedStatus = 'active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Organization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Organization Name',
                      hintText: 'Enter organization name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter email address',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      hintText: 'Enter location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter organization description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setModalState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organization Logo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: _selectedLogoFile != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 40,
                                        color: Colors.green[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image selected',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _pickLogoImage();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Choose Logo from Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _foundedDateController,
                    decoration: InputDecoration(
                      labelText: 'Founded Date',
                      hintText: 'e.g., Sept 2020',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                      DropdownMenuItem(value: 'Leadership', child: Text('Leadership')),
                      DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                      DropdownMenuItem(value: 'Cultural', child: Text('Cultural')),
                      DropdownMenuItem(value: 'Social', child: Text('Social')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(value: 'archived', child: Text('Archived')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (_nameController.text.isEmpty ||
                              _emailController.text.isEmpty ||
                              _locationController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields'),
                              ),
                            );
                            return;
                          }

                          try {
                            String? logoUrl;
                            
                            // Upload image if selected
                            if (_selectedLogoFile != null) {
                              final tempOrgId = 'org_${DateTime.now().millisecondsSinceEpoch}';
                              logoUrl = await _organizationService.uploadOrganizationLogo(
                                tempOrgId,
                                _selectedLogoFile!,
                              );
                            }
                            
                            final orgId = await _organizationService.createOrganization(
                              name: _nameController.text,
                              email: _emailController.text,
                              location: _locationController.text,
                              category: _selectedCategory,
                              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                              logoUrl: logoUrl,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              _showSelectAdminsDialog(orgId, _nameController.text);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C000F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add Organization'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddMembersDialog(
    String organizationId,
    String organizationName, {
    VoidCallback? onMembersAdded,
  }) {
    List<Map<String, dynamic>> availableUsers = [];
    List<Map<String, dynamic>> filteredUsers = [];
    bool isLoading = true;
    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          if (isLoading) {
            _loadAvailableUsers().then((users) {
              setState(() {
                availableUsers = users;
                filteredUsers = [];
                isLoading = false;
              });
            });
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Members to $organizationName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        if (query.isEmpty) {
                          filteredUsers = [];
                        } else {
                          final lowerQuery = query.toLowerCase();
                          filteredUsers = availableUsers
                              .where((user) =>
                                  (user['displayName'] as String)
                                      .toLowerCase()
                                      .contains(lowerQuery) ||
                                  (user['email'] as String)
                                      .toLowerCase()
                                      .contains(lowerQuery))
                              .toList();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredUsers.isEmpty
                            ? Center(
                                child: Text(
                                  searchController.text.isEmpty
                                      ? 'Search to add members'
                                      : 'No users found',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredUsers.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: Colors.grey[200],
                                ),
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                                  final userId = user['id'] as String;
                                  final displayName = user['displayName'] as String;
                                  final email = user['email'] as String;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: const Color(0xFFFADBD2),
                                          child: Text(
                                            displayName[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF7C0010),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                email,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            try {
                                              await _organizationService
                                                  .addMemberToOrganization(
                                                organizationId,
                                                userId,
                                                role: 'admin',
                                              );

                                              // Sync organization data to ensure consistency
                                              await _organizationService
                                                  .syncOrganizationData(organizationId);

                                              if (mounted) {
                                                setState(() {
                                                  filteredUsers.removeAt(index);
                                                  searchController.clear();
                                                });
                                                onMembersAdded?.call();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '$displayName added as admin',
                                                    ),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF7C000F),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                          ),
                                          child: const Text(
                                            'Add',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showSelectAdminsDialog(String organizationId, String organizationName) {
    List<String> selectedAdminIds = [];
    List<Map<String, dynamic>> availableUsers = [];
    bool isLoading = true;

    _loadAvailableUsers().then((users) {
      availableUsers = users;
      isLoading = false;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Admins for $organizationName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (availableUsers.isEmpty)
                    const Center(
                      child: Text('No users available'),
                    )
                  else
                    Column(
                      children: availableUsers.map((user) {
                        final userId = user['id'] as String;
                        final displayName = user['displayName'] as String;
                        final email = user['email'] as String;

                        return CheckboxListTile(
                          title: Text(displayName),
                          subtitle: Text(email),
                          value: selectedAdminIds.contains(userId),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedAdminIds.add(userId);
                              } else {
                                selectedAdminIds.remove(userId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Skip'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: selectedAdminIds.isEmpty
                            ? null
                            : () async {
                                try {
                                  await _organizationService.assignAdminsToOrganization(
                                    organizationId,
                                    selectedAdminIds,
                                  );

                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${selectedAdminIds.length} admin(s) assigned successfully',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error assigning admins: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C000F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Assign Admins'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadAvailableUsers() async {
    try {
      print('Loading available users from Firestore...');
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      print('Fetched ${usersSnapshot.docs.length} users from Firestore');

      final users = usersSnapshot.docs
          .map((doc) {
            final data = {
              'id': doc.id,
              'displayName': doc['displayName'] ?? 'Unknown',
              'email': doc['email'] ?? '',
            };
            print('User: ${data['displayName']} (${data['email']})');
            return data;
          })
          .toList();

      print('Returning ${users.length} users');
      return users;
    } catch (e) {
      print('Error loading users: $e');
      print('Stack trace: $e');
      return [];
    }
  }

  void _showEditOrganizationModal(Organization org) {
    _nameController.text = org.name;
    _emailController.text = org.email;
    _locationController.text = org.location;
    _descriptionController.text = org.description ?? '';
    _logoUrlController.text = org.logoUrl ?? '';
    _foundedDateController.text = org.foundedDate ?? '';
    _selectedCategory = org.category;
    _selectedStatus = org.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Organization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Organization Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setModalState) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Organization Logo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: _selectedLogoFile != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 40,
                                        color: Colors.green[600],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Image selected',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _pickLogoImage();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Choose Logo from Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[800],
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _foundedDateController,
                    decoration: InputDecoration(
                      labelText: 'Founded Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                      DropdownMenuItem(value: 'Leadership', child: Text('Leadership')),
                      DropdownMenuItem(value: 'Sports', child: Text('Sports')),
                      DropdownMenuItem(value: 'Cultural', child: Text('Cultural')),
                      DropdownMenuItem(value: 'Social', child: Text('Social')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'archived', child: Text('Archived')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            String? logoUrl;
                            
                            // Upload image if selected
                            if (_selectedLogoFile != null) {
                              logoUrl = await _organizationService.uploadOrganizationLogo(
                                org.id,
                                _selectedLogoFile!,
                              );
                            }
                            
                            await _organizationService.updateOrganization(
                              org.id,
                              name: _nameController.text,
                              email: _emailController.text,
                              location: _locationController.text,
                              category: _selectedCategory,
                              status: _selectedStatus,
                              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
                              logoUrl: logoUrl,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${_nameController.text} updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C000F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Update Organization'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showArchiveConfirmation(Organization org) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Organization'),
        content: Text('Are you sure you want to archive "${org.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _organizationService.updateOrganization(
                  org.id,
                  status: 'archived',
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${org.name} archived successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  void _handleNavTap(int index) {
    switch (index) {
      case 0:
        // Dashboard - pop all the way back to dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
        break;
      case 1:
        // Analytics
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAnalytics()),
        );
        break;
      case 2:
        // Reports
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminReports()),
        );
        break;
      case 3:
        // Organizations - already on it
        break;
    }
  }
}
