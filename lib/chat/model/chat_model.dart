import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;

  ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
  });

  factory ChatModel.fromMap(String id, Map<String, dynamic> data) => ChatModel(
    id: id,
    participants: List<String>.from(data['participants'] ?? []),
    lastMessage: data['lastMessage'] ?? '',
    lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'participants': participants,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime,
  };
}
