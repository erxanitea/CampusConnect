import 'package:flutter/material.dart';
import 'package:stateful_widget/admin/admin_analytics.dart';
import 'package:stateful_widget/admin/admin_reports.dart';
import 'package:stateful_widget/widgets/admin_bottom_nav.dart';

class AdminOrganizations extends StatefulWidget {
  const AdminOrganizations({super.key});

  @override
  State<AdminOrganizations> createState() => _AdminOrganizationsState();
}

class _AdminOrganizationsState extends State<AdminOrganizations> {
  int _navIndex = 3;

  static const _statsData = [
    {'title': 'Total Orgs', 'value': '38'},
    {'title': 'Avg Members', 'value': '152'},
    {'title': 'Active', 'value': '35'},
  ];

  static const _organizations = [
    {
      'name': 'Computer Science Club',
      'status': 'active',
      'category': 'Academic',
      'members': 245,
      'posts': 128,
      'engagement': 92,
      'email': 'cs.club@campus.edu',
      'founded': 'Sept 2020',
      'location': 'Engineering Building',
      'weeklyPosts': 12,
      'avgReactions': 34,
    },
    {
      'name': 'Student Government',
      'status': 'active',
      'category': 'Leadership',
      'members': 189,
      'posts': 94,
      'engagement': 88,
      'email': 'sg@campus.edu',
      'founded': 'Aug 2019',
      'location': 'Student Center',
      'weeklyPosts': 8,
      'avgReactions': 28,
    },
    {
      'name': 'Debate Society',
      'status': 'active',
      'category': 'Academic',
      'members': 156,
      'posts': 67,
      'engagement': 85,
      'email': 'debate@campus.edu',
      'founded': 'Oct 2020',
      'location': 'Liberal Arts Building',
      'weeklyPosts': 6,
      'avgReactions': 22,
    },
  ];

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
                      Row(
                        children: _statsData.map((stat) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildStatCard(stat),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      _buildTopOrganizationsCard(),
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
        children: const [
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

  Widget _buildTopOrganizationsCard() {
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
          ..._organizations.map((org) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrgItem(org),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrgItem(Map<String, dynamic> org) {
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
                      org['name'] as String,
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
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            org['status'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                org['category'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildOrgStat(Icons.people_outline, '${org['members']}'),
              const SizedBox(width: 16),
              _buildOrgStat(Icons.article_outlined, '${org['posts']}'),
              const SizedBox(width: 16),
              _buildOrgStat(Icons.trending_up, '${org['engagement']}%'),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showOrgDetailsDialog(org),
              icon: Icon(
                Icons.visibility_outlined,
                size: 18,
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

  void _showOrgDetailsDialog(Map<String, dynamic> org) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    org['name'] as String,
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
                      org['status'] as String,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    org['category'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'A community for students interested in computer science, programming, and technology.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.email_outlined, org['email'] as String),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.calendar_today_outlined, 'Founded ${org['founded'] as String}'),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.location_on_outlined, org['location'] as String),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard('Members', '${org['members']}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailCard('Total Posts', '${org['posts']}'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard('Weekly Posts', '${org['weeklyPosts']}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailCard('Avg Reactions', '${org['avgReactions']}'),
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
                      '${org['engagement']}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
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
