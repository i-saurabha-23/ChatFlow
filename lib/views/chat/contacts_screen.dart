import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/models/contact_model.dart';
import 'package:interview/services/chat_repository.dart';
import 'package:interview/views/chat/chat_thread_screen.dart';
import 'package:interview/views/chat/group_details_screen.dart';
import 'package:interview/widgets/primary_button.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final ChatRepository _repository = ChatRepository.instance;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedContactIds = {};
  List<ContactModel> _contacts = const [];
  bool _isGroupMode = false;
  bool _isLoading = true;
  bool _isOpeningChat = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      _contacts = await _repository.fetchChatFlowContacts();
    } catch (error) {
      _loadError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ContactModel> get _filteredContacts {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return _contacts;
    }

    return _contacts.where((contact) {
      return contact.fullName.toLowerCase().contains(query) ||
          contact.phoneNumber.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _onContactTap(ContactModel contact) async {
    if (_isOpeningChat) {
      return;
    }

    if (_isGroupMode) {
      setState(() {
        if (_selectedContactIds.contains(contact.id)) {
          _selectedContactIds.remove(contact.id);
        } else {
          _selectedContactIds.add(contact.id);
        }
      });
      return;
    }

    setState(() => _isOpeningChat = true);
    try {
      final thread = await _repository.createOrOpenDirectThread(contact);
      if (!mounted) {
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ChatThreadScreen(thread: thread)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      CherryToast.error(
        title: const Text('Unable to open chat'),
        description: Text(error.toString().replaceFirst('Exception: ', '')),
      ).show(context);
    } finally {
      if (mounted) {
        setState(() => _isOpeningChat = false);
      }
    }
  }

  void _onNextForGroup() {
    final selectedContacts = _contacts
        .where((contact) => _selectedContactIds.contains(contact.id))
        .toList();

    if (selectedContacts.isEmpty) {
      CherryToast.info(
        title: const Text('Select Contacts'),
        description: const Text('Choose at least one contact for group.'),
      ).show(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(selectedContacts: selectedContacts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _filteredContacts;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(_isGroupMode ? 'Create Group' : 'Select Contact'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isGroupMode = !_isGroupMode;
                _selectedContactIds.clear();
              });
            },
            icon: Icon(
              _isGroupMode ? Icons.close_rounded : Icons.group_add_rounded,
              color: Colors.white,
            ),
            label: Text(
              _isGroupMode ? 'Cancel' : 'Group',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: AppSizes.screenPadding,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.curveMedium),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            AppSizes.verticalMedium,
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? Center(
                          child: Text(
                            _loadError!,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : contacts.isEmpty
                  ? const Center(
                      child: Text(
                        'No ChatFlow contacts found in your saved contacts.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        final isSelected = _selectedContactIds.contains(contact.id);

                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            onTap: () => _onContactTap(contact),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryColor,
                              child: Text(
                                contact.fullName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                ),
            ),
                            title: Text(contact.fullName),
                            subtitle: Text('${contact.phoneNumber}  •  ${contact.about}'),
                            trailing: _isGroupMode
                                ? Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? AppColors.primaryColor
                                        : AppColors.textSecondaryColor,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
            if (_isGroupMode) ...[
              AppSizes.verticalSmall,
              PrimaryButton(
                text: 'Next (${_selectedContactIds.length})',
                onPressed: _onNextForGroup,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
