import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> data) =>
      MessageModel(
        id: id,
        senderId: data['senderId'],
        text: data['text'],
        timestamp:
            (data['timestamp'] != null && data['timestamp'] is Timestamp)
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp,
  };
}
