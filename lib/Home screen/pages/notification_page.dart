import 'package:flutter/material.dart';
import '../../connect/service/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();
    return Container(
      color: const Color(0xFF181C23),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationService.getUserNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00F6FF)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(fontSize: 18, color: Color(0xFF00F6FF)),
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
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      read
                          ? const Color(0xFF232733)
                          : const Color(0xFF00F6FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: read ? Colors.white24 : const Color(0xFF00F6FF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (!read)
                      BoxShadow(
                        color: const Color(0xFF00F6FF).withOpacity(0.18),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(
                    type == 'like' ? Icons.thumb_up : Icons.comment,
                    color:
                        type == 'like' ? Color(0xFF00F6FF) : Color(0xFF00F6FF),
                  ),
                  title: Text(
                    message,
                    style: GoogleFonts.orbitron(
                      textStyle: const TextStyle(
                        color: Color(0xFF00F6FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(color: Color(0xFF00F6FF), blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                  subtitle:
                      time != null
                          ? Text(
                            _formatTime(time),
                            style: const TextStyle(color: Colors.white70),
                          )
                          : null,
                  tileColor: Colors.transparent,
                  onTap: () {
                    notificationService.markAsRead(notifications[index].id);
                  },
                ),
              );
            },
          );
        },
      ),
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
