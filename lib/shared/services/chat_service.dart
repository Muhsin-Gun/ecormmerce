import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/constants.dart';
import 'firebase_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'chats';

  // Singleton pattern
  static final ChatService _instance = ChatService._internal();
  static ChatService get instance => _instance;
  ChatService._internal();

  /// Create or get existing chat
  Future<String> createChat(String userId, String userName) async {
    // Check if active chat exists
    final query = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }

    // Create new chat
    final docRef = await _firestore.collection(_collection).add({
      'userId': userId,
      'userName': userName,
      'status': 'active',
      'unreadCount': 0, // For admin side
      'lastMessage': 'Chat started',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'participants': [userId], // Add admin/employee IDs later
    });

    return docRef.id;
  }

  /// Send a message
  Future<void> sendMessage(String chatId, String senderId, String text, {String? type = 'text', String? imageUrl}) async {
    await _firestore.collection(_collection).doc(chatId).collection('messages').add({
      'senderId': senderId,
      'text': text,
      'type': type,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    // Update last message in chat doc
    await _firestore.collection(_collection).doc(chatId).update({
      'lastMessage': type == 'image' ? '📷 Image' : text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1), 
    });
  }

  /// Get messages stream
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection(_collection)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Get user chats (for admin/employee)
  Stream<QuerySnapshot> getAllChats() {
    return _firestore
        .collection(_collection)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Mark messages as read
  Future<void> markAsRead(String chatId) async {
    await _firestore.collection(_collection).doc(chatId).update({'unreadCount': 0});
  }
}
