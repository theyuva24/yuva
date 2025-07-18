import 'package:flutter/material.dart';
import '../service/chat_service.dart';
import '../model/message_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  const ChatPage({Key? key, required this.chatId, required this.otherUserId})
    : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppThemeLight.theme,
      child: Scaffold(
        backgroundColor: AppThemeLight.background,
        appBar: AppBar(
          backgroundColor: AppThemeLight.surface,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppThemeLight.primary),
          title: Text(
            'Chat',
            style: GoogleFonts.orbitron(
              textStyle: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppThemeLight.primary,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: AppThemeLight.primary,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: _chatService.getMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppThemeLight.primary,
                      ),
                    );
                  }
                  final messages = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId != widget.otherUserId;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isMe
                                    ? AppThemeLight.primary
                                    : AppThemeLight.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow:
                                isMe
                                    ? [
                                      BoxShadow(
                                        color: AppThemeLight.primary
                                            .withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                    : [],
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: AppThemeLight.textDark,
                              fontSize: 16,
                            ),
                          ),
                        ),
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
                      style: const TextStyle(color: AppThemeLight.textDark),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(
                          color: AppThemeLight.textLight,
                        ),
                        filled: true,
                        fillColor: AppThemeLight.surface,
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
                    icon: const Icon(Icons.send, color: AppThemeLight.primary),
                    onPressed: () async {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        await _chatService.sendMessage(widget.chatId, text);
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
