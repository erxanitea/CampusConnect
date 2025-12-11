import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stateful_widget/services/database/database_service.dart';
import 'package:stateful_widget/models/post_model.dart';

class ShareToPickerBottomSheet extends StatelessWidget {
  final Post post;
  final DatabaseService db;

  const ShareToPickerBottomSheet({
    super.key,
    required this.post,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Share post to...', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.getConversationsForPicker(),
              builder: (_, snap) {
                if (snap.hasError) return Text('Error ${snap.error}');
                if (!snap.hasData) return const CircularProgressIndicator();
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Text('No conversations yet');
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final c = docs[i].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                                backgroundColor: c['avatarColor'] ?? Colors.blue,
                                child: Text(c['emoji'] ?? '💬'),
                              ),
                      title: Text(c['name'] ?? 'Chat'),
                      onTap: () async {
                        Navigator.pop(context);
                        db.sendShareToConversation(
                          conversationId: docs[i].id,
                          post: post,
                        );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post share to conversation')),
                      );
                      },
                    );
                  },
                );
            },
            ),
          ),
        ],
      ),
    );
  }
}
