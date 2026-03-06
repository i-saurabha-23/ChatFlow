class ChatThread {
  final String id;
  final String title;
  final String subtitle;
  final bool isGroup;
  final List<String> memberIds;
  final String? directContactId;
  final String? groupId;
  final String lastMessage;
  final DateTime updatedAt;

  const ChatThread({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.isGroup,
    required this.memberIds,
    this.directContactId,
    this.groupId,
    required this.lastMessage,
    required this.updatedAt,
  });

  ChatThread copyWith({
    String? id,
    String? title,
    String? subtitle,
    bool? isGroup,
    List<String>? memberIds,
    String? directContactId,
    String? groupId,
    String? lastMessage,
    DateTime? updatedAt,
  }) {
    return ChatThread(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      isGroup: isGroup ?? this.isGroup,
      memberIds: memberIds ?? this.memberIds,
      directContactId: directContactId ?? this.directContactId,
      groupId: groupId ?? this.groupId,
      lastMessage: lastMessage ?? this.lastMessage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
