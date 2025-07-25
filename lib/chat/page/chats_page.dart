import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/chat_service.dart';
import 'chat_page.dart';
import 'hub_chat_page.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {}); // Refresh when coming back from message page
  }

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
      // Fetch latest message from messages subcollection
      final latestMsgQuery =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chat.id)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();
      String lastMsg = '';
      DateTime? lastMsgTime;
      if (latestMsgQuery.docs.isNotEmpty) {
        lastMsg = latestMsgQuery.docs.first['text'] ?? '';
        final ts = latestMsgQuery.docs.first['timestamp'];
        if (ts is Timestamp) lastMsgTime = ts.toDate();
      }
      unified.add({
        'type': 'direct',
        'id': chat.id,
        'name': userProfile?['fullName'] ?? 'Unknown',
        'imageUrl': userProfile?['profilePicUrl'] ?? '',
        'lastMsg': lastMsg,
        'lastMsgTime': lastMsgTime,
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
      return Center(
        child: Text(
          'Not logged in',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .where('participants', arrayContains: user.uid)
                .orderBy('lastMessageTime', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          }
          final chatDocs = snapshot.data!.docs;
          if (chatDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.only(top: 64),
                child: Text(
                  'No chats yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data();
              final chatId = chatDoc.id;
              final participants = List<String>.from(
                chatData['participants'] ?? [],
              );
              final otherUserId = participants.firstWhere(
                (id) => id != user.uid,
                orElse: () => user.uid,
              );
              return FutureBuilder<Map<String, dynamic>?>(
                future: fetchUserProfile(otherUserId),
                builder: (context, userProfileSnapshot) {
                  final userProfile = userProfileSnapshot.data;
                  final currentUserId = user.uid;
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .snapshots(),
                    builder: (context, chatDocSnapshot) {
                      if (!chatDocSnapshot.hasData ||
                          chatDocSnapshot.data == null) {
                        return const SizedBox.shrink();
                      }
                      final chatData = chatDocSnapshot.data!.data();
                      final lastReadTimestamps =
                          chatData?['lastReadTimestamps'] ?? {};
                      final lastRead =
                          lastReadTimestamps[currentUserId] != null &&
                                  lastReadTimestamps[currentUserId] is Timestamp
                              ? (lastReadTimestamps[currentUserId] as Timestamp)
                                  .toDate()
                              : DateTime.fromMillisecondsSinceEpoch(0);
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chatId)
                                .collection('messages')
                                .orderBy('timestamp', descending: true)
                                .limit(1)
                                .snapshots(),
                        builder: (context, latestMsgSnapshot) {
                          String lastMsg = '';
                          DateTime? lastMsgTime;
                          if (latestMsgSnapshot.hasData &&
                              latestMsgSnapshot.data!.docs.isNotEmpty) {
                            final msgDoc = latestMsgSnapshot.data!.docs.first;
                            lastMsg = msgDoc['text'] ?? '';
                            final ts = msgDoc['timestamp'];
                            if (ts is Timestamp) lastMsgTime = ts.toDate();
                          }
                          return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>
                          >(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(chatId)
                                    .collection('messages')
                                    .where('timestamp', isGreaterThan: lastRead)
                                    .where('timestamp', isNotEqualTo: null)
                                    .where(
                                      'senderId',
                                      isNotEqualTo: currentUserId,
                                    )
                                    .snapshots(),
                            builder: (context, unreadSnapshot) {
                              int unreadCount = 0;
                              if (unreadSnapshot.hasData) {
                                unreadCount = unreadSnapshot.data!.docs.length;
                              }
                              return ListTile(
                                tileColor:
                                    Theme.of(context).colorScheme.surface,
                                leading:
                                    userProfile != null &&
                                            (userProfile['profilePicUrl'] ?? '')
                                                .isNotEmpty
                                        ? Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withAlpha(29),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              userProfile['profilePicUrl'],
                                            ),
                                            backgroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                          ),
                                        )
                                        : Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withAlpha(29),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            backgroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                            child: Icon(
                                              Icons.person,
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                title: Text(
                                  userProfile?['fullName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 8,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        offset: Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                ),
                                subtitle: Text(
                                  lastMsg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (lastMsgTime != null)
                                      Text(
                                        TimeOfDay.fromDateTime(
                                          lastMsgTime,
                                        ).format(context),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
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
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: TextStyle(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ChatPage(
                                            chatId: chatId,
                                            otherUserId: otherUserId,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
