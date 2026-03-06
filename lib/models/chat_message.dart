class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String content;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {required String threadId}) {
    return ChatMessage(
      id: json['id'].toString(),
      threadId: threadId,
      senderId: json['senderId'].toString(),
      content: json['content']?.toString() ?? '',
      sentAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
