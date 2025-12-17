import 'package:flutter/material.dart';

/// Placeholder tab describing the upcoming broadcast messaging workflow.
class OrganizationMessagesTab extends StatelessWidget {
  final String organizationName;

  const OrganizationMessagesTab({
    super.key,
    required this.organizationName,
  });

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
                    const Icon(Icons.message_outlined, color: Color(0xFF8D0B15)),
                    const SizedBox(width: 8),
                    const Text(
                      'Broadcast Message',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF4A1C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a direct message to all 3 members of $organizationName',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your message here...',
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Send to All Members'),
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
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recipients (3)',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF4A1C1C),
            ),
          ),
          const SizedBox(height: 12),
          _buildRecipientCard(
            name: 'John Doe',
            email: 'john@campus.edu',
          ),
          const SizedBox(height: 12),
          _buildRecipientCard(
            name: 'Sarah Smith',
            email: 'sarah@campus.edu',
          ),
          const SizedBox(height: 12),
          _buildRecipientCard(
            name: 'Alex Chen',
            email: 'alex@campus.edu',
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientCard({
    required String name,
    required String email,
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
            child: Text(
              name.split(' ').map((e) => e[0]).join(),
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
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
