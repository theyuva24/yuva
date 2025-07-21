import 'package:flutter/material.dart';
import '../../connect/service/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../universal/theme/app_theme.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final NotificationService notificationService = NotificationService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      color: colorScheme.background,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: notificationService.getUserNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(fontSize: 18.sp, color: colorScheme.primary),
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
                margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color:
                      read
                          ? colorScheme.surface
                          : colorScheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: read ? colorScheme.outline : colorScheme.primary,
                    width: 1.5.w,
                  ),
                  boxShadow: [
                    if (!read)
                      BoxShadow(
                        color: colorScheme.primary.withAlpha(31),
                        blurRadius: 8.r,
                        spreadRadius: 1.r,
                      ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(
                    type == 'like' ? Icons.thumb_up : Icons.comment,
                    color: colorScheme.primary,
                  ),
                  title: Text(
                    message,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                      letterSpacing: 1.w,
                    ),
                  ),
                  subtitle:
                      time != null
                          ? Text(
                            _formatTime(time),
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color,
                              fontSize: 13.sp,
                            ),
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
