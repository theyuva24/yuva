import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../universal/theme/app_theme.dart';

class HubChatPage extends StatefulWidget {
  final String hubId;
  final String hubName;
  const HubChatPage({Key? key, required this.hubId, required this.hubName})
    : super(key: key);

  @override
  State<HubChatPage> createState() => _HubChatPageState();
}

class _HubChatPageState extends State<HubChatPage> {
  final TextEditingController _controller = TextEditingController();

  Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream() {
    return FirebaseFirestore.instance
        .collection('hubs')
        .doc(widget.hubId)
        .collection('messages')
        .where('timestamp', isGreaterThan: Timestamp(0, 0))
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<Map<String, dynamic>?> _fetchUserProfile(String userId) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> _sendMessage(String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('hubs')
        .doc(widget.hubId)
        .collection('messages')
        .add({
          'senderId': user.uid,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          '${widget.hubName} Chat',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }
                final messages = snapshot.data!.docs;
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data();
                    final senderId = msg['senderId'] ?? '';
                    final text = msg['text'] ?? '';
                    final timestamp = msg['timestamp'] as Timestamp?;
                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchUserProfile(senderId),
                      builder: (context, userSnapshot) {
                        final userData = userSnapshot.data;
                        final name = userData?['fullName'] ?? 'Unknown';
                        final profilePic = userData?['profilePicUrl'] ?? '';
                        return ListTile(
                          leading:
                              profilePic.isNotEmpty
                                  ? CircleAvatar(
                                    backgroundImage: NetworkImage(profilePic),
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surface,
                                  )
                                  : CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.surface,
                                    child: Icon(
                                      Icons.person,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                          title: Row(
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (timestamp != null)
                                Text(
                                  TimeOfDay.fromDateTime(
                                    timestamp.toDate(),
                                  ).format(context),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            text,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      _controller.clear();
                      await _sendMessage(text);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
