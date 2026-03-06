import 'package:cherry_toast/cherry_toast.dart';
import 'package:flutter/material.dart';
import 'package:interview/core/constants/app_colors.dart';
import 'package:interview/core/constants/app_sizes.dart';
import 'package:interview/models/chat_thread.dart';
import 'package:interview/models/contact_model.dart';
import 'package:interview/services/app_permissions_service.dart';
import 'package:interview/services/auth_service.dart';
import 'package:interview/services/chat_repository.dart';
import 'package:interview/services/push_notification_service.dart';
import 'package:interview/views/auth/sign_in_screen.dart';
import 'package:interview/views/chat/chat_thread_screen.dart';
import 'package:interview/views/chat/group_details_screen.dart';
import 'package:interview/widgets/chat_floating_action_button.dart';
import 'package:permission_handler/permission_handler.dart';

class MainChatsScreen extends StatefulWidget {
  static const String routeName = '/main-chats';

  const MainChatsScreen({super.key});

  @override
  State<MainChatsScreen> createState() => _MainChatsScreenState();
}

class _MainChatsScreenState extends State<MainChatsScreen> {
  final ChatRepository _repository = ChatRepository.instance;
  final AuthService _authService = AuthService();
  final AppPermissionsService _permissionsService = AppPermissionsService();

  final TextEditingController _chatSearchController = TextEditingController();
  final TextEditingController _contactsSearchController =
      TextEditingController();

  int _currentTabIndex = 0;
  bool _isLoadingChats = true;
  bool _isLoadingContacts = true;
  bool _isOpeningChat = false;
  bool _isHandlingNotificationTap = false;
  bool _isGroupMode = false;

  String? _chatLoadError;
  String? _contactsLoadError;

  List<ContactModel> _contacts = const [];
  final Set<String> _selectedContactIds = <String>{};
  Map<Permission, PermissionStatus> _permissionStatuses = {};
  bool _contactsPermissionGranted = false;

  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getCurrentUser();
    PushNotificationService.instance.setNotificationTapHandler(
      _handleNotificationTap,
    );
    _bootstrapData();
  }

  @override
  void dispose() {
    PushNotificationService.instance.clearNotificationTapHandler();
    _chatSearchController.dispose();
    _contactsSearchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapData() async {
    await _requestNotificationPermission();
    await _requestCorePermissions(showFeedback: false);
    await _loadChats();
    await _loadContacts();
    await PushNotificationService.instance.consumePendingTap();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) {
      return;
    }

    final requested = await Permission.notification.request();
    if (!mounted) {
      return;
    }

    if (requested.isGranted) {
      CherryToast.success(
        title: const Text('Notifications Enabled'),
        description: const Text('You will receive chat alerts in background.'),
      ).show(context);
      return;
    }

    CherryToast.info(
      title: const Text('Enable Notifications'),
      description: const Text(
        'Allow notifications to receive chat messages when app is closed.',
      ),
    ).show(context);

    if (requested.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> payload) async {
    if (!mounted || _isHandlingNotificationTap) {
      return;
    }

    _isHandlingNotificationTap = true;
    try {
      final thread = await _repository.resolveThreadFromNotificationData(
        payload,
      );
      if (!mounted || thread == null) {
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatThreadScreen(thread: thread)),
      );
      await _loadChats();
    } finally {
      _isHandlingNotificationTap = false;
    }
  }

  Future<void> _requestCorePermissions({required bool showFeedback}) async {
    final statuses = await _permissionsService.requestCorePermissions();

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatuses = statuses;
      _contactsPermissionGranted = _permissionsService.isContactsGranted(
        _permissionStatuses,
      );
    });

    if (!showFeedback) {
      return;
    }

    final denied = _permissionsService.deniedPermissionLabels(statuses);
    if (denied.isEmpty) {
      CherryToast.success(
        title: const Text('Permissions Updated'),
        description: const Text('Required permissions are granted.'),
      ).show(context);
      return;
    }

    final needsSettings = _permissionsService.hasAnyPermanentlyDenied(statuses);
    CherryToast.info(
      title: const Text('Permission Required'),
      description: Text('Denied: ${denied.join(', ')}'),
    ).show(context);

    if (needsSettings) {
      await openAppSettings();
    }
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoadingChats = true;
      _chatLoadError = null;
    });

    try {
      await _repository.initialize();
      await _repository.refreshAll();
    } catch (error) {
      _chatLoadError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isLoadingChats = false);
      }
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
      _contactsLoadError = null;
    });

    try {
      final status = await Permission.contacts.status;
      final contactsGranted = status.isGranted || status.isLimited;
      _contactsPermissionGranted = contactsGranted;

      if (!contactsGranted) {
        _contacts = const [];
        return;
      }

      _contacts = await _repository.fetchChatFlowContacts();
    } catch (error) {
      _contactsLoadError = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isLoadingContacts = false);
      }
    }
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = _authService.getCurrentUser();
    });
  }

  List<ChatThread> _filterThreads(List<ChatThread> threads) {
    final query = _chatSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return threads;
    }

    return threads
        .where((thread) => thread.title.toLowerCase().contains(query))
        .toList();
  }

  List<ContactModel> get _filteredContacts {
    final query = _contactsSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _contacts;
    }

    return _contacts.where((contact) {
      return contact.fullName.toLowerCase().contains(query) ||
          contact.phoneNumber.toLowerCase().contains(query) ||
          (contact.email?.toLowerCase().contains(query) ?? false);
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

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatThreadScreen(thread: thread)),
      );
      await _loadChats();
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

  Future<void> _onNextForGroup() async {
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

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupDetailsScreen(selectedContacts: selectedContacts),
      ),
    );

    _selectedContactIds.clear();
    setState(() => _isGroupMode = false);
    await _loadChats();
  }

  Future<void> _signOut() async {
    await _authService.clearToken();
    _repository.clearLocalCache();

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      SignInScreen.routeName,
      (route) => false,
    );
  }

  Widget _buildChatsTab() {
    return Column(
      children: [
        TextField(
          controller: _chatSearchController,
          decoration: InputDecoration(
            hintText: 'Search chats',
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
          child: _isLoadingChats
              ? const Center(child: CircularProgressIndicator())
              : _chatLoadError != null
              ? Center(
                  child: Text(
                    _chatLoadError!,
                    textAlign: TextAlign.center,
                    style: AppSizes.textStyle,
                  ),
                )
              : ValueListenableBuilder<List<ChatThread>>(
                  valueListenable: _repository.threadsNotifier,
                  builder: (context, threads, _) {
                    final filtered = _filterThreads(threads);

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No chats yet.\nOpen Contacts tab to start.',
                          textAlign: TextAlign.center,
                          style: AppSizes.textStyle,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final thread = filtered[index];
                        return Card(
                          color: Colors.white,
                          child: ListTile(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChatThreadScreen(thread: thread),
                                ),
                              );
                              await _loadChats();
                            },
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryColor,
                              child: Icon(
                                thread.isGroup
                                    ? Icons.groups_rounded
                                    : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(thread.title),
                            subtitle: Text(thread.lastMessage),
                            trailing: Text(
                              '${thread.updatedAt.hour.toString().padLeft(2, '0')}:${thread.updatedAt.minute.toString().padLeft(2, '0')}',
                              style: AppSizes.paragraphStyle.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildContactsTab() {
    final contacts = _filteredContacts;

    return Column(
      children: [
        TextField(
          controller: _contactsSearchController,
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
          child: _isLoadingContacts
              ? const Center(child: CircularProgressIndicator())
              : _contactsLoadError != null
              ? Center(
                  child: Text(_contactsLoadError!, textAlign: TextAlign.center),
                )
              : contacts.isEmpty
              ? Center(
                  child: Text(
                    _contactsPermissionGranted
                        ? 'No ChatFlow users found in your saved phone contacts.'
                        : 'Contacts permission is required to discover saved ChatFlow users.',
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
                        subtitle: Text(
                          [
                            contact.phoneNumber,
                            if (contact.email != null &&
                                contact.email!.isNotEmpty)
                              contact.email!,
                          ].join(' - '),
                        ),
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
        if (_isGroupMode)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onNextForGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.curveMedium),
                  ),
                ),
                child: Text('Next (${_selectedContactIds.length})'),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      children: [
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Permissions'),
            subtitle: const Text('Contacts, camera, microphone and storage'),
            onTap: () async {
              await _requestCorePermissions(showFeedback: true);
              await _loadContacts();
            },
          ),
        ),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Allow alerts for incoming chat messages'),
            onTap: _requestNotificationPermission,
          ),
        ),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('App info and version details'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ChatFlow',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Secure messaging app',
              );
            },
          ),
        ),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text('Privacy and account safety options'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy options coming soon.')),
              );
            },
          ),
        ),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            subtitle: const Text('Get help and contact support'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support options coming soon.')),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Log out from this account'),
            onTap: _signOut,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              snapshot.error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
            ),
          );
        }

        final user = snapshot.data ?? <String, dynamic>{};
        final createdAtRaw = user['createdAt']?.toString();
        final createdAt = createdAtRaw == null
            ? null
            : DateTime.tryParse(createdAtRaw)?.toLocal();

        String createdAtText = 'Not available';
        if (createdAt != null) {
          createdAtText =
              '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
        }

        final phoneNumber = user['phoneNumber']?.toString();

        return RefreshIndicator(
          onRefresh: _refreshProfile,
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E7041), Color(0xFF2C9F61)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      child: Text(
                        (user['fullName']?.toString().isNotEmpty ?? false)
                            ? user['fullName']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user['fullName']?.toString() ?? 'Unknown User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _profileTile(
                'User ID',
                user['id']?.toString() ?? 'Not available',
              ),
              _profileTile(
                'Full Name',
                user['fullName']?.toString() ?? 'Not available',
              ),
              _profileTile(
                'Email',
                user['email']?.toString() ?? 'Not available',
              ),
              _profileTile(
                'Phone Number',
                (phoneNumber == null || phoneNumber.isEmpty)
                    ? 'Not available'
                    : phoneNumber,
              ),
              _profileTile('Account Created At', createdAtText),
            ],
          ),
        );
      },
    );
  }

  Widget _profileTile(String label, String value) {
    return Card(
      color: Colors.white,
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _tabTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'Chats';
      case 1:
        return _isGroupMode ? 'Create Group' : 'Contacts';
      case 2:
        return 'Settings';
      case 3:
        return 'My Profile';
      default:
        return 'ChatFlow';
    }
  }

  Widget _tabBody() {
    switch (_currentTabIndex) {
      case 0:
        return _buildChatsTab();
      case 1:
        return _buildContactsTab();
      case 2:
        return _buildSettingsTab();
      case 3:
        return _buildProfileTab();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(_tabTitle()),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_currentTabIndex == 0)
            IconButton(
              onPressed: _loadChats,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh chats',
            ),
          if (_currentTabIndex == 1)
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
          if (_currentTabIndex == 1)
            IconButton(
              onPressed: () async {
                await _requestCorePermissions(showFeedback: false);
                await _loadContacts();
              },
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh contacts',
            ),
        ],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? ChatFloatingActionButton(
              onPressed: () {
                setState(() => _currentTabIndex = 1);
              },
            )
          : null,
      body: Padding(padding: AppSizes.screenPadding, child: _tabBody()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTabIndex,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE6F4EC),
        onDestinationSelected: (index) {
          setState(() => _currentTabIndex = index);
          if (index == 1) {
            _requestCorePermissions(
              showFeedback: false,
            ).then((_) => _loadContacts());
          }
          if (index == 3) {
            _refreshProfile();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            selectedIcon: Icon(Icons.contacts_rounded),
            label: 'Contacts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
