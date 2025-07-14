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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUnifiedChats(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 64),
                child: Text(
                  'No chats yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                leading:
                    chat['imageUrl'].isNotEmpty
                        ? CircleAvatar(
                          backgroundImage: NetworkImage(chat['imageUrl']),
                        )
                        : CircleAvatar(
                          child: Icon(
                            chat['type'] == 'hub' ? Icons.groups : Icons.person,
                          ),
                        ),
                title: Text(
                  chat['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  chat['lastMsg'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing:
                    chat['lastMsgTime'] != null
                        ? Text(
                          TimeOfDay.fromDateTime(
                            chat['lastMsgTime'],
                          ).format(context),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        )
                        : null,
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
      ),
    );
  }
}
