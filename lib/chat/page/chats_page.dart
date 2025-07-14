import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/chat_service.dart';
import '../model/chat_model.dart';
import 'chat_page.dart';
import 'hub_chat_page.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> fetchUserHubs(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final joinedHubs = List<String>.from(userDoc.data()?['joinedHubs'] ?? []);
    final List<Map<String, dynamic>> hubs = [];
    for (final hubId in joinedHubs) {
      final hubDoc =
          await FirebaseFirestore.instance.collection('hubs').doc(hubId).get();
      if (!hubDoc.exists) continue;
      final hubData = hubDoc.data()!;
      // Fetch last message
      final lastMsgQuery =
          await FirebaseFirestore.instance
              .collection('hubs')
              .doc(hubId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();
      String lastMsg = '';
      Timestamp? lastMsgTime;
      if (lastMsgQuery.docs.isNotEmpty) {
        lastMsg = lastMsgQuery.docs.first['text'] ?? '';
        lastMsgTime = lastMsgQuery.docs.first['timestamp'] as Timestamp?;
      }
      hubs.add({
        'hubId': hubId,
        'name': hubData['name'] ?? 'Hub',
        'imageUrl': hubData['imageUrl'] ?? '',
        'lastMsg': lastMsg,
        'lastMsgTime': lastMsgTime,
      });
    }
    return hubs;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUserHubs(user.uid),
        builder: (context, hubSnapshot) {
          return StreamBuilder<List<ChatModel>>(
            stream: ChatService().getUserChats(user.uid),
            builder: (context, chatSnapshot) {
              if (hubSnapshot.connectionState == ConnectionState.waiting ||
                  !chatSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final hubChats = hubSnapshot.data ?? [];
              final chats = chatSnapshot.data ?? [];
              return ListView(
                children: [
                  if (hubChats.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                      child: Text(
                        'Hub Chats',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    ...hubChats.map(
                      (hub) => ListTile(
                        leading:
                            hub['imageUrl'].isNotEmpty
                                ? CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    hub['imageUrl'],
                                  ),
                                )
                                : const CircleAvatar(child: Icon(Icons.groups)),
                        title: Text(
                          hub['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          hub['lastMsg'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing:
                            hub['lastMsgTime'] != null
                                ? Text(
                                  TimeOfDay.fromDateTime(
                                    (hub['lastMsgTime'] as Timestamp).toDate(),
                                  ).format(context),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                )
                                : null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => HubChatPage(
                                    hubId: hub['hubId'],
                                    hubName: hub['name'],
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (chats.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 0, 8),
                      child: Text(
                        'Direct Messages',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    ...List.generate(chats.length, (index) {
                      final chat = chats[index];
                      final otherUserId = chat.participants.firstWhere(
                        (id) => id != user.uid,
                      );
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: fetchUserProfile(otherUserId),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text('Loading...'),
                              subtitle: Text(chat.lastMessage),
                            );
                          }
                          final userData = userSnapshot.data!;
                          final name = userData['fullName'] ?? 'Unknown';
                          final profilePic = userData['profilePicUrl'] ?? '';
                          return ListTile(
                            leading:
                                profilePic.isNotEmpty
                                    ? CircleAvatar(
                                      backgroundImage: NetworkImage(profilePic),
                                    )
                                    : const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                            title: Text(name),
                            subtitle: Text(chat.lastMessage),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatPage(
                                        chatId: chat.id,
                                        otherUserId: otherUserId,
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    }),
                  ],
                  if (hubChats.isEmpty && chats.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 64),
                        child: Text(
                          'No chats yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
