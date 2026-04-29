class ChatMessage {
  final String? id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isEdited;
  final List<String> reactions;
  final String? chatId;

  ChatMessage({
    this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isEdited = false,
    this.reactions = const [],
    this.chatId,
  });

  ChatMessage copyWith({
    String? text,
    bool? isEdited,
    List<String>? reactions,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      timestamp: timestamp,
      isEdited: isEdited ?? this.isEdited,
      reactions: reactions ?? this.reactions,
      chatId: chatId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'is_edited': isEdited,
      'reactions': reactions,
      'chat_id': chatId,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isUser: json['is_user'],
      timestamp: DateTime.parse(json['timestamp']),
      isEdited: json['is_edited'] ?? false,
      reactions: List<String>.from(json['reactions'] ?? []),
      chatId: json['chat_id'],
    );
  }
}
