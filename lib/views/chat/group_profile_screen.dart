import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/models/chat_thread.dart';
import 'package:interview/services/chat_repository.dart';

class GroupProfileScreen extends StatelessWidget {
  final ChatThread thread;

  const GroupProfileScreen({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    final repository = ChatRepository.instance;
    final members = thread.memberIds
        .where((id) => id != repository.currentUserId)
        .map(repository.getContactById)
        .whereType()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('Group Info'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: AppSizes.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(thread.title, style: AppSizes.headingStyle.copyWith(fontSize: 28)),
            AppSizes.verticalSmall,
            Text('${thread.memberIds.length} participants', style: AppSizes.subHeadingStyle),
            AppSizes.verticalLarge,
            const Text('Members', style: AppSizes.textStyle),
            AppSizes.verticalSmall,
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        child: Text(
                          member.fullName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(member.fullName),
                      subtitle: Text(member.phoneNumber),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
