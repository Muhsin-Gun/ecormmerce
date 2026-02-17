import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_feedback.dart';
import '../services/cloudinary_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/message_model.dart';
import '../providers/message_provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;
  bool _showEmojiPicker = false;
  final FocusNode _messageFocusNode = FocusNode();

  static const List<String> _quickEmojis = ['🔥', '💯', '✨', '❤️', '😂', '👏', '👍', '🚀'];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final user = context.read<AuthProvider>().firebaseUser;
    if (user == null) return;

    try {
      await context.read<MessageProvider>().sendMessage(
            conversationId: widget.chatId,
            senderId: user.uid,
            text: text,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AppFeedback.error(
          context,
          e,
          fallbackMessage: 'Could not send message.',
          nextStep: 'Please retry.',
        );
      }
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final user = context.read<AuthProvider>().firebaseUser;
    final messageProvider = context.read<MessageProvider>();
    if (user == null) return;

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return;

      setState(() => _isUploadingImage = true);
      final imageUrl = await CloudinaryService.uploadImage(file);
      if (imageUrl == null) throw Exception('Image upload failed');

      await messageProvider.sendMessage(
            conversationId: widget.chatId,
            senderId: user.uid,
            text: imageUrl,
            type: 'image',
            imageUrl: imageUrl,
          );
      _scrollToBottom();
    } on PlatformException catch (e) {
      if (mounted) {
        AppFeedback.error(
          context,
          e.message ?? e.code,
          fallbackMessage: 'Camera access failed.',
          nextStep: 'Allow camera permission and try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.error(
          context,
          e,
          fallbackMessage: 'Image upload failed.',
          nextStep: 'Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addEmoji(String emoji) {
    final value = _messageController.value;
    final selection = value.selection;
    final newText = value.text.replaceRange(
      selection.start >= 0 ? selection.start : value.text.length,
      selection.end >= 0 ? selection.end : value.text.length,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.start >= 0 ? selection.start : value.text.length) + emoji.length,
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().firebaseUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messageProvider = context.watch<MessageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: messageProvider.streamMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.gray300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Say Hi!',
                          style: TextStyle(
                            color: AppColors.gray500,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == user?.uid;
                    return _buildMessageBubble(msg, isMe, isDark);
                  },
                );
              },
            ),
          ),
          Container(
            height: 42,
            padding: const EdgeInsets.only(left: 12),
            alignment: Alignment.centerLeft,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickEmojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () => _addEmoji(_quickEmojis[index]),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.electricPurple.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(_quickEmojis[index], style: const TextStyle(fontSize: 20)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined,
                          color: AppColors.electricPurple,
                        ),
                        onPressed: () {
                          setState(() {
                            _showEmojiPicker = !_showEmojiPicker;
                            if (_showEmojiPicker) {
                              _messageFocusNode.unfocus();
                            } else {
                              _messageFocusNode.requestFocus();
                            }
                          });
                        },
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.electricPurple.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: _isUploadingImage
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_photo_alternate, color: AppColors.electricPurple),
                          onPressed: _isUploadingImage ? null : _showImageSourceSheet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.gray800 : AppColors.gray100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            onTap: () {
                              if (_showEmojiPicker) {
                                setState(() => _showEmojiPicker = false);
                              }
                            },
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _messageController,
                        builder: (context, value, _) {
                          return GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryIndigo,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.send, color: Colors.white, size: 20),
                            ).animate(target: value.text.trim().isNotEmpty ? 1 : 0).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                          );
                        },
                      ),
                    ],
                  ),
                  if (_showEmojiPicker)
                    SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: (category, emoji) {
                          _addEmoji(emoji.emoji);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe, bool isDark) {
    final text = msg.text;
    final isEmoji = _isSingleEmoji(text);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: isEmoji ? const EdgeInsets.all(8) : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: isEmoji
            ? null
            : BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [AppColors.primaryIndigo, AppColors.electricPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : (isDark ? AppColors.gray700 : AppColors.gray200),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                ),
              ),
        child: msg.isImage ? _buildImageBubble(msg.text) : _buildMessageContent(text, isEmoji, isMe, isDark),
      ),
    );
  }

  Widget _buildImageBubble(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 190,
        height: 190,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 190,
          height: 190,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => const SizedBox(
          width: 190,
          height: 80,
          child: Center(child: Text('Could not load image')),
        ),
      ),
    );
  }

  Widget _buildMessageContent(String text, bool isEmoji, bool isMe, bool isDark) {
    if (isEmoji) {
      return Text(text, style: const TextStyle(fontSize: 42));
    }

    return Text(
      text,
      style: TextStyle(
        color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
        fontSize: 15,
      ),
    );
  }

  bool _isSingleEmoji(String text) {
    if (text.isEmpty) return false;
    final characters = text.characters;
    if (characters.length > 2) return false;
    final regex = RegExp(r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');
    return regex.hasMatch(text);
  }
}

