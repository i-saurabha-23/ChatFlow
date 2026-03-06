import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/models/chat_thread.dart';
import 'package:interview/models/contact_model.dart';
import 'package:interview/services/chat_repository.dart';
import 'package:interview/views/chat/contact_profile_screen.dart';
import 'package:interview/views/chat/group_profile_screen.dart';

class ChatThreadScreen extends StatefulWidget {
  final ChatThread thread;

  const ChatThreadScreen({super.key, required this.thread});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final ChatRepository _repository = ChatRepository.instance;
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _openProfile() {
    if (widget.thread.isGroup) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupProfileScreen(thread: widget.thread),
        ),
      );
      return;
    }

    final contact = _resolveDirectContact();
    if (contact == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactProfileScreen(contact: contact),
      ),
    );
  }

  ContactModel? _resolveDirectContact() {
    for (final id in widget.thread.memberIds) {
      if (id == _repository.currentUserId) {
        continue;
      }
      return _repository.getContactById(id);
    }
    return null;
  }

  Future<void> _send() async {
    try {
      await _repository.sendMessage(
        threadId: widget.thread.id,
        senderId: _repository.currentUserId,
        content: _messageController.text,
      );
      _messageController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesNotifier = _repository.messagesForThread(widget.thread.id);
    final directContact = _resolveDirectContact();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: InkWell(
          onTap: _openProfile,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    widget.thread.title.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.thread.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.thread.isGroup
                            ? '${widget.thread.memberIds.length} participants'
                            : (directContact?.about ?? 'Tap to view profile'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE7F6ED),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: messagesNotifier,
              builder: (context, messages, _) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nStart chatting.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: AppSizes.screenPadding,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == _repository.currentUserId;

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? AppColors.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(
                            color: isMine ? Colors.white : AppColors.textPrimaryColor,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primaryColor,
                    child: IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
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
}
