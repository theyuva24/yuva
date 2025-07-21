import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/chat_service.dart';
import 'chat_page.dart';
import 'hub_chat_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> fetchUnifiedChats(String userId) async {
    // Fetch direct chats
    final directChats = await ChatService().getUserChats(userId).first;
    final List<Map<String, dynamic>> unified = [];
    for (final chat in directChats) {
      final otherUserId = chat.participants.firstWhere(
        (id) => id != userId,
        orElse: () => userId,
      );
      final userProfile = await fetchUserProfile(otherUserId);
      unified.add({
        'type': 'direct',
        'id': chat.id,
        'name': userProfile?['fullName'] ?? 'Unknown',
        'imageUrl': userProfile?['profilePicUrl'] ?? '',
        'lastMsg': chat.lastMessage,
        'lastMsgTime': chat.lastMessageTime,
        'otherUserId': otherUserId,
      });
    }
    // Fetch hub chats
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final joinedHubs = List<String>.from(userDoc.data()?['joinedHubs'] ?? []);
    for (final hubId in joinedHubs) {
      final hubDoc =
          await FirebaseFirestore.instance.collection('hubs').doc(hubId).get();
      if (!hubDoc.exists) continue;
      final hubData = hubDoc.data()!;
      final lastMsgQuery =
          await FirebaseFirestore.instance
              .collection('hubs')
              .doc(hubId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();
      String lastMsg = '';
      DateTime? lastMsgTime;
      if (lastMsgQuery.docs.isNotEmpty) {
        lastMsg = lastMsgQuery.docs.first['text'] ?? '';
        final ts = lastMsgQuery.docs.first['timestamp'];
        if (ts is Timestamp) lastMsgTime = ts.toDate();
      }
      unified.add({
        'type': 'hub',
        'id': hubId,
        'name': hubData['name'] ?? 'Hub',
        'imageUrl': hubData['imageUrl'] ?? '',
        'lastMsg': lastMsg,
        'lastMsgTime': lastMsgTime,
      });
    }
    // Remove chats with no lastMsgTime (optional)
    unified.removeWhere((c) => c['lastMsgTime'] == null);
    // Sort by lastMsgTime descending
    unified.sort(
      (a, b) => (b['lastMsgTime'] as DateTime).compareTo(
        a['lastMsgTime'] as DateTime,
      ),
    );
    return unified;
  }

  Future<int> fetchUnreadCount(String chatId, String userId) async {
    final chatDoc =
        await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    final lastReadTimestamps = chatDoc.data()?['lastReadTimestamps'] ?? {};
    final lastRead =
        lastReadTimestamps[userId] != null &&
                lastReadTimestamps[userId] is Timestamp
            ? (lastReadTimestamps[userId] as Timestamp).toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
    final messagesQuery =
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('timestamp', isGreaterThan: lastRead)
            .where('senderId', isNotEqualTo: userId)
            .get();
    return messagesQuery.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          'Not logged in',
          style: TextStyle(color: AppThemeLight.textDark),
        ),
      );
    }
    return Theme(
      data: AppThemeLight.theme,
      child: Scaffold(
        backgroundColor: AppThemeLight.background,
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchUnifiedChats(user.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppThemeLight.primary),
              );
            }
            final chats = snapshot.data!;
            if (chats.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: Text(
                    'No chats yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppThemeLight.primary,
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return FutureBuilder<int>(
                  future:
                      chat['type'] == 'direct'
                          ? fetchUnreadCount(chat['id'], user.uid)
                          : Future.value(0),
                  builder: (context, unreadSnapshot) {
                    final unreadCount = unreadSnapshot.data ?? 0;
                    return ListTile(
                      tileColor: AppThemeLight.surface,
                      leading:
                          chat['imageUrl'].isNotEmpty
                              ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppThemeLight.primary,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppThemeLight.primary.withAlpha(
                                        29,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    chat['imageUrl'],
                                  ),
                                  backgroundColor: AppThemeLight.surface,
                                ),
                              )
                              : Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppThemeLight.primary,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppThemeLight.primary.withAlpha(
                                        29,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundColor: AppThemeLight.surface,
                                  child: Icon(
                                    chat['type'] == 'hub'
                                        ? Icons.groups
                                        : Icons.person,
                                    color: AppThemeLight.primary,
                                  ),
                                ),
                              ),
                      title: Text(
                        chat['name'],
                        style: GoogleFonts.orbitron(
                          textStyle: const TextStyle(
                            color: AppThemeLight.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                color: AppThemeLight.primary,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      subtitle: Text(
                        chat['lastMsg'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppThemeLight.textLight),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (chat['lastMsgTime'] != null)
                            Text(
                              TimeOfDay.fromDateTime(
                                chat['lastMsgTime'],
                              ).format(context),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppThemeLight.primary,
                              ),
                            ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        if (chat['type'] == 'hub') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => HubChatPage(
                                    hubId: chat['id'],
                                    hubName: chat['name'],
                                  ),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => ChatPage(
                                    chatId: chat['id'],
                                    otherUserId: chat['otherUserId'],
                                  ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
