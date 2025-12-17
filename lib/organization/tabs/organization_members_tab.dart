import 'package:flutter/material.dart';
import 'package:stateful_widget/services/database/organization_service.dart';
import 'package:stateful_widget/models/user_model.dart';

/// Admin tab for managing membership roster, invites, and roles.
class OrganizationMembersTab extends StatefulWidget {
  final String organizationName;
  final String organizationId;

  const OrganizationMembersTab({
    super.key,
    required this.organizationName,
    required this.organizationId,
  });

  @override
  State<OrganizationMembersTab> createState() => _OrganizationMembersTabState();
}

class _OrganizationMembersTabState extends State<OrganizationMembersTab> {
  final OrganizationService _organizationService = OrganizationService();
  final TextEditingController _searchController = TextEditingController();
  List<AppUser> _searchResults = [];
  List<AppUser> _currentMembers = [];
  bool _isSearching = false;
  /// Cached future for the members section to avoid repeated queries.
  Future<List<AppUser>>? _membersFuture;
  String _organizationId = '';

  @override
  void initState() {
    super.initState();
    _organizationId = widget.organizationId;
    print('OrganizationMembersTab initState - widget.organizationId: "${widget.organizationId}", _organizationId: "$_organizationId"');
    
    if (_organizationId.isEmpty) {
      print('ERROR: organizationId is empty in initState!');
      throw 'OrganizationMembersTab requires a non-empty organizationId';
    }
    
    _membersFuture = _organizationService.getOrganizationMembersDetails(_organizationId);
    _loadCurrentMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentMembers() async {
    try {
      String orgId = widget.organizationId.isNotEmpty ? widget.organizationId : _organizationId;
      if (orgId.isEmpty) {
        print('ERROR: organizationId is empty in _loadCurrentMembers!');
        return;
      }
      
      final members = await _organizationService.getOrganizationMembersDetails(orgId);
      if (mounted) {
        setState(() => _currentMembers = members);
      }
    } catch (e) {
      print('Error loading current members: $e');
      if (mounted) {
        setState(() => _currentMembers = []);
      }
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _organizationService.searchUsersForMembership(query);
      
      // Ensure current members are loaded
      if (_currentMembers.isEmpty) {
        await _loadCurrentMembers();
      }
      
      final currentMemberIds = _currentMembers.map((m) => m.uid).toSet();
      final filteredResults = results
          .where((user) => !currentMemberIds.contains(user.uid))
          .toList();
      
      if (mounted) {
        setState(() => _searchResults = filteredResults);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching users: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _addMember(String userId) async {
    try {
      // Always use widget.organizationId as the source of truth
      String orgId = widget.organizationId;
      if (orgId.isEmpty) {
        orgId = _organizationId;
      }
      
      
      if (orgId.isEmpty) {
        throw 'Organization ID is empty - cannot add member';
      }
      
      print('Adding member $userId to organization $orgId');
      
      await _organizationService.addMemberToOrganization(
        orgId,
        userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully')),
        );
        _searchController.clear();
        setState(() {
          _searchResults = [];
          _membersFuture = _organizationService.getOrganizationMembersDetails(_organizationId);
        });
        
        await _loadCurrentMembers();
      }
    } catch (e) {
      print('Error adding member: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding member: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      String orgId = widget.organizationId.isNotEmpty ? widget.organizationId : _organizationId;
      await _organizationService.removeMemberFromOrganization(
        orgId,
        userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully')),
        );
        setState(() {
          _membersFuture = _organizationService.getOrganizationMembersDetails(orgId);
        });
        await _loadCurrentMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing member: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId = widget.organizationId.isNotEmpty ? widget.organizationId : _organizationId;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FutureBuilder<List<AppUser>>(
            future: _organizationService.getOrganizationMembersDetails(orgId),
            builder: (context, snapshot) {
              int memberCount = 0;
              if (snapshot.hasData) {
                memberCount = snapshot.data?.length ?? 0;
              }

              return FutureBuilder<Map<String, String>>(
                future: snapshot.hasData ? _getMemberRoles(orgId, snapshot.data ?? []) : Future.value({}),
                builder: (context, rolesSnapshot) {
                  int adminCount = 0;
                  if (rolesSnapshot.hasData) {
                    adminCount = rolesSnapshot.data?.values.where((role) => role == 'admin').length ?? 0;
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people_outline,
                          value: '$memberCount',
                          label: 'Total Members',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.shield_outlined,
                          value: '$adminCount',
                          label: 'Admins',
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          Container(
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
                    const Icon(Icons.person_add_outlined, color: Color(0xFF8D0B15), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Members',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF4A1C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: _searchUsers,
                  decoration: InputDecoration(
                    hintText: 'Search students by name or email',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (_searchResults.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: _searchResults
                          .map((user) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(0xFFFADBD2),
                                        child: Text(
                                          (user.displayName ?? 'U')[0].toUpperCase(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF7C0010),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.displayName ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              user.email,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _addMember(user.uid),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF8D0B15),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                        ),
                                        child: const Text(
                                          'Add',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Current Members',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF4A1C1C),
            ),
          ),
          const SizedBox(height: 12),
          if (_membersFuture != null)
            FutureBuilder<List<AppUser>>(
              future: _membersFuture!,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final members = snapshot.data ?? [];

                if (members.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No members yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

              return FutureBuilder<Map<String, String>>(
                key: ValueKey('roles_${members.map((m) => m.uid).join('_')}'),
                future: _getMemberRoles(orgId, members),
                builder: (context, rolesSnapshot) {
                  if (rolesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (rolesSnapshot.hasError) {
                    print('Error loading roles: ${rolesSnapshot.error}');
                  }

                  final memberRoles = rolesSnapshot.data ?? {};
                  

                  return Column(
                    children: members
                        .asMap()
                        .entries
                        .map((entry) {
                          final user = entry.value;
                          final isAdmin = memberRoles[user.uid] == 'admin';
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key < members.length - 1 ? 12 : 0,
                            ),
                            child: _buildMemberCard(
                              user: user,
                              isAdmin: isAdmin,
                              organizationId: orgId,
                            ),
                          );
                        })
                        .toList(),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFECE3DC)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF9EDEA),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8D0B15),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A1C1C),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF7C5A55),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Fetches role labels for each member so UI can highlight admins.
  Future<Map<String, String>> _getMemberRoles(String organizationId, List<AppUser> members) async {
    try {
      final rolesMap = <String, String>{};
      
      for (final member in members) {
        final memberDoc = await _organizationService.getOrganizationMemberRole(
          organizationId,
          member.uid,
        );
        rolesMap[member.uid] = memberDoc;
      }
      return rolesMap;
    } catch (e) {
      print('Error getting member roles: $e');
      return {};
    }
  }

  /// Elevates a member to admin status for the given organization.
  Future<void> _promoteToAdmin(String userId, String organizationId) async {
    try {
      String orgId = organizationId.isNotEmpty ? organizationId : _organizationId;
      if (orgId.isEmpty) {
        throw 'Organization ID is empty';
      }

      await _organizationService.updateMemberRole(orgId, userId, 'admin');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member promoted to admin')),
        );
        setState(() {
          _membersFuture = _organizationService.getOrganizationMembersDetails(orgId);
        });
      }
    } catch (e) {
      print('Error promoting member to admin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Removes admin privileges from a user while keeping them as member.
  Future<void> _demoteFromAdmin(String userId, String organizationId) async {
    try {
      String orgId = organizationId.isNotEmpty ? organizationId : _organizationId;
      if (orgId.isEmpty) {
        throw 'Organization ID is empty';
      }

      await _organizationService.updateMemberRole(orgId, userId, 'member');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin role removed')),
        );
        setState(() {
          _membersFuture = _organizationService.getOrganizationMembersDetails(orgId);
        });
      }
    } catch (e) {
      print('Error demoting admin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildMemberCard({
    required AppUser user,
    required bool isAdmin,
    required String organizationId,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1E4DE)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFADBD2),
            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
            child: user.photoURL == null
                ? Text(
                    (user.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C0010),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC53529),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _demoteFromAdmin(user.uid, organizationId),
                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB74D3A), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Remove admin role',
                ),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _promoteToAdmin(user.uid, organizationId),
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8D0B15), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Make admin',
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _removeMember(user.uid),
                  icon: const Icon(Icons.close, color: Color(0xFFB74D3A), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Remove member',
                ),
              ],
            ),
        ],
      ),
    );
  }
}
