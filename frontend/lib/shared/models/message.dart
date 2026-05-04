class Message {
  final String id;
  final String senderId;
  final String content;
  final DateTime sentAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.sentAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        senderId: json['sender_id'] as String,
        content: json['content'] as String,
        sentAt: DateTime.parse(json['sent_at'] as String).toLocal(),
      );
}
