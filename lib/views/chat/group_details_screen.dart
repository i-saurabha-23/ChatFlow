import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/models/contact_model.dart';
import 'package:interview/services/chat_repository.dart';
import 'package:interview/views/chat/chat_thread_screen.dart';
import 'package:interview/widgets/app_text_field.dart';
import 'package:interview/widgets/primary_button.dart';

class GroupDetailsScreen extends StatefulWidget {
  final List<ContactModel> selectedContacts;

  const GroupDetailsScreen({super.key, required this.selectedContacts});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_isCreating) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.length < 2) {
      CherryToast.error(
        title: const Text('Invalid Name'),
        description: const Text('Group name must be at least 2 characters.'),
      ).show(context);
      return;
    }

    setState(() => _isCreating = true);

    try {
      final thread = await ChatRepository.instance.createGroupThread(
        groupName: name,
        selectedContacts: widget.selectedContacts,
      );

      if (!mounted) {
        return;
      }

      CherryToast.success(
        title: const Text('Group Created'),
        description: Text('$name group is ready.'),
      ).show(context);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => ChatThreadScreen(thread: thread)),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      CherryToast.error(
        title: const Text('Group Create Failed'),
        description: Text(error.toString().replaceFirst('Exception: ', '')),
      ).show(context);
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text('New Group'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: AppSizes.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Name',
              style: AppSizes.headingStyle.copyWith(fontSize: 24),
            ),
            AppSizes.verticalMedium,
            AppTextField(
              controller: _nameController,
              hintText: 'Enter group name',
            ),
            AppSizes.verticalLarge,
            const Text('Selected Members', style: AppSizes.textStyle),
            AppSizes.verticalSmall,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.selectedContacts
                  .map(
                    (contact) => Chip(
                      backgroundColor: Colors.white,
                      label: Text(contact.fullName),
                    ),
                  )
                  .toList(),
            ),
            const Spacer(),
            PrimaryButton(
              text: _isCreating ? 'Creating...' : 'Create Group',
              onPressed: _createGroup,
            ),
          ],
        ),
      ),
    );
  }
}
