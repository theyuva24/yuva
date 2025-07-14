import 'package:flutter/material.dart';
import '../../connect/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: notificationService.getUserNotificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No notifications yet.',
              style: TextStyle(fontSize: 18, color: Color(0xFF6C63FF)),
            ),
          );
        }
        final notifications = snapshot.data!.docs;
        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final data = notifications[index].data();
            final type = data['type'] ?? '';
            final senderName = data['senderName'] ?? 'Someone';
            final commentText = data['commentText'];
            final read = data['read'] ?? false;
            final time = (data['timestamp'] as Timestamp?)?.toDate();
            String message = '';
            if (type == 'like') {
              message = '$senderName liked your post.';
            } else if (type == 'comment') {
              message = '$senderName commented: "$commentText"';
            } else {
              message = 'You have a new notification.';
            }
            return ListTile(
              leading: Icon(
                type == 'like' ? Icons.thumb_up : Icons.comment,
                color: type == 'like' ? Colors.purple : Colors.blue,
              ),
              title: Text(message),
              subtitle: time != null ? Text(_formatTime(time)) : null,
              tileColor: read ? Colors.white : const Color(0xFFEDE7F6),
              onTap: () {
                notificationService.markAsRead(notifications[index].id);
              },
            );
          },
        );
      },
    );
  }
}

String _formatTime(DateTime time) {
  final now = DateTime.now();
  final difference = now.difference(time);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} hr ago';
  return '${time.day}/${time.month}/${time.year}';
}
