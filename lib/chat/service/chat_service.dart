import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../initial pages/auth_service.dart';
import '../model/message_model.dart';
import '../model/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of messages for a chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  // Send a message
  Future<void> sendMessage(String chatId, String text) async {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');
    final messageRef =
        _firestore.collection('chats').doc(chatId).collection('messages').doc();
    await messageRef.set({
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    // Ensure timestamp is set
    final written = await messageRef.get();
    if (written['timestamp'] == null) {
      await messageRef.update({'timestamp': FieldValue.serverTimestamp()});
    }
    // Update last message in chat
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // --- Push Notification Logic ---
    // Get chat document to find participants
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final participants = List<String>.from(chatDoc['participants'] ?? []);
    // Find recipient (other than current user)
    final recipientId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (recipientId.isEmpty) return;
    // Fetch recipient's FCM token
    final userDoc = await _firestore.collection('users').doc(recipientId).get();
    final fcmToken = userDoc.data()?['fcmToken'];
    if (fcmToken == null || fcmToken.isEmpty) return;
    // Fetch sender's name
    final senderDoc =
        await _firestore.collection('users').doc(currentUserId).get();
    final senderName = senderDoc.data()?['fullName'] ?? 'New Message';
    // Send push notification
    await _sendPushNotification(token: fcmToken, title: senderName, body: text);
  }

  Future<void> updateLastReadTimestamp(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).set({
      'lastReadTimestamps': {userId: FieldValue.serverTimestamp()},
    }, SetOptions(merge: true));
  }

  // Returns a stream of all direct chats for a user
  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatModel.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  // Returns the chat between the current user and another user, creating it if it doesn't exist
  Future<ChatModel> getOrCreateChatWith(String otherUserId) async {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');
    final query =
        await _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUserId)
            .get();
    for (final doc in query.docs) {
      final participants = List<String>.from(doc['participants'] ?? []);
      if (participants.contains(otherUserId) && participants.length == 2) {
        return ChatModel.fromMap(doc.id, doc.data());
      }
    }
    // If not found, create a new chat
    final chatRef = await _firestore.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'lastMessage': '',
      'lastMessageTime': DateTime.now(),
    });
    final newChatDoc = await chatRef.get();
    return ChatModel.fromMap(newChatDoc.id, newChatDoc.data()!);
  }

  // Helper to send push notification using FCM HTTP v1 API
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    const String serverAccessToken =
        'YOUR_SERVER_ACCESS_TOKEN'; // TODO: Provide this securely, e.g., via environment variable or secure backend
    if (serverAccessToken == 'YOUR_SERVER_ACCESS_TOKEN') {
      throw Exception(
        'FCM server access token is not set.\n'
        'To send push notifications, you must generate a valid OAuth2 access token for your Firebase service account.\n'
        'For development, you can use the following command (requires gcloud CLI):\n'
        'gcloud auth print-access-token\n'
        'and paste the result as the serverAccessToken.\n'
        'For production, move this logic to a secure backend.',
      );
    }
    const String projectId =
        'yuva-1263'; // Replace with your Firebase project ID
    final url =
        'https://fcm.googleapis.com/v1/projects/ projectId/messages:send';
    final message = {
      'message': {
        'token': token,
        'notification': {'title': title, 'body': body},
        'data': {'type': 'chat'},
      },
    };
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $serverAccessToken',
      },
      body: jsonEncode(message),
    );
    if (response.statusCode != 200) {
      print('Failed to send push notification: \n{response.body}');
    }
  }
}
