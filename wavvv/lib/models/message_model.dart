class MessageModel {
  final String id;
  final String roomId;
  final String? userId;
  final String username;
  final String text;
  final String type; // 'text' | 'reaction' | 'system'
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.roomId,
    this.userId,
    required this.username,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['messageId'] ?? json['_id'] ?? json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      userId: json['userId'],
      username: json['username'] ?? 'Guest',
      text: json['text'] ?? '',
      type: json['type'] ?? 'text',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isSystem => type == 'system';
  bool get isReaction => type == 'reaction';
}
