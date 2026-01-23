import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../../auth/providers/auth_provider.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService.instance;
  
  String? _activeChatId;
  bool _isLoading = false;

  String? get activeChatId => _activeChatId;
  bool get isLoading => _isLoading;

  /// Initialize support chat for current user
  Future<void> initSupportChat(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        _activeChatId = await _chatService.createChat(user.uid, user.name ?? 'User');
      }
    } catch (e) {
      debugPrint('Error creating chat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send message
  Future<void> sendMessage(String text, String senderId) async {
    if (_activeChatId == null) return;
    try {
      await _chatService.sendMessage(_activeChatId!, senderId, text);
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }
}
