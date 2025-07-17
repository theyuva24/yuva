import 'package:cloud_firestore/cloud_firestore.dart';
import '../../initial pages/auth_service.dart';
import '../model/chat_model.dart';
import '../model/message_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get or create a one-on-one chat between current user and another user
  Future<ChatModel> getOrCreateChatWith(String otherUserId) async {
    final currentUserId = AuthService().currentUser?.uid;
    if (currentUserId == null) throw Exception('User not authenticated');
    final participants = [currentUserId, otherUserId]..sort();
    final chatQuery =
        await _firestore
            .collection('chats')
            .where('participants', isEqualTo: participants)
            .limit(1)
            .get();
    if (chatQuery.docs.isNotEmpty) {
      return ChatModel.fromMap(
        chatQuery.docs.first.id,
        chatQuery.docs.first.data(),
      );
    } else {
      final chatRef = await _firestore.collection('chats').add({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      final chatSnap = await chatRef.get();
      return ChatModel.fromMap(chatSnap.id, chatSnap.data()!);
    }
  }

  // Stream all chats for current user
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

  // Stream messages for a chat
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

  // Helper to send push notification using FCM HTTP v1 API
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
  }) async {
    // TODO: Replace with your service account access token logic
    const String serverAccessToken =
        'YOUR_SERVER_ACCESS_TOKEN'; // Use OAuth2 token
    const String projectId =
        'yuva-1263'; // Replace with your Firebase project ID
    final url =
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
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
      print('Failed to send push notification: ${response.body}');
    }
  }
}
