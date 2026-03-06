import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';

class ChatFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ChatFloatingActionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primaryColor,
      foregroundColor: Colors.white,
      child: const Icon(Icons.chat_rounded),
    );
  }
}
