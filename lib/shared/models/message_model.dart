import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isImage;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isImage = false,
  });

  /// 🔹 Firestore → Model
  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      isImage: data['isImage'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// 🔹 Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'isImage': isImage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class ConversationModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final MessageModel? lastMessage;
  final DateTime? updatedAt;

  const ConversationModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    this.updatedAt,
  });

  /// 🔹 Firestore → Model
  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      participantNames:
          Map<String, String>.from(data['participantNames'] ?? {}),
      updatedAt:
          (data['updatedAt'] as Timestamp?)?.toDate(),
      lastMessage: data['lastMessage'] != null
          ? MessageModel(
              id: data['lastMessage']['id'] ?? '',
              conversationId: doc.id,
              senderId: data['lastMessage']['senderId'] ?? '',
              text: data['lastMessage']['text'] ?? '',
              isImage: data['lastMessage']['isImage'] ?? false,
              createdAt: (data['lastMessage']['createdAt'] as Timestamp?)
                      ?.toDate() ??
                  DateTime.now(),
            )
          : null,
    );
  }

  /// 🔹 Model → Firestore
  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'updatedAt': Timestamp.fromDate(updatedAt ?? DateTime.now()),
      'lastMessage': lastMessage != null
          ? {
              'id': lastMessage!.id,
              'senderId': lastMessage!.senderId,
              'text': lastMessage!.text,
              'isImage': lastMessage!.isImage,
              'createdAt':
                  Timestamp.fromDate(lastMessage!.createdAt),
            }
          : null,
    };
  }

  /// 🔹 UI helpers (USED BY SCREENS)
  DateTime? get lastMessageTime => lastMessage?.createdAt;
}
