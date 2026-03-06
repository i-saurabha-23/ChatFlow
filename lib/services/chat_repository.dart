import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:http/http.dart' as http;
import 'package:interview/core/constants/app_endpoints.dart';
import 'package:interview/models/chat_message.dart';
import 'package:interview/models/chat_thread.dart';
import 'package:interview/models/contact_model.dart';
import 'package:interview/services/auth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatRepository {
  ChatRepository._();

  static final ChatRepository instance = ChatRepository._();

  final AuthService _authService = AuthService();
  final ValueNotifier<List<ChatThread>> threadsNotifier =
      ValueNotifier<List<ChatThread>>([]);

  final Map<String, ValueNotifier<List<ChatMessage>>> _messagesNotifiers = {};
  List<ContactModel> _contacts = const [];
  String? _currentUserId;
  bool _initialized = false;

  String get currentUserId {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      throw Exception('Current user is not loaded.');
    }
    return _currentUserId!;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await refreshAll();
    _initialized = true;
  }

  Future<void> refreshAll() async {
    final user = await _authService.getCurrentUser();
    _currentUserId = user['id']?.toString();

    if (_currentUserId == null || _currentUserId!.isEmpty) {
      throw Exception('Missing current user id in session response.');
    }

    final backendUsers = await _fetchBackendUsers();
    _contacts = await _filterSavedChatFlowContacts(backendUsers);
    final groups = await _fetchGroupsForCurrentUser();

    final threads = <ChatThread>[];

    for (final contact in _contacts) {
      final threadId = _directThreadId(contact.id);
      final directMessages = await _fetchDirectConversation(contact.id, threadId);
      final lastMessage = directMessages.isNotEmpty
          ? directMessages.last.content
          : 'Start chatting';
      final updatedAt = directMessages.isNotEmpty
          ? directMessages.last.sentAt
          : DateTime.fromMillisecondsSinceEpoch(0);

      threads.add(
        ChatThread(
          id: threadId,
          title: contact.fullName,
          subtitle: contact.about,
          isGroup: false,
          memberIds: [currentUserId, contact.id],
          directContactId: contact.id,
          lastMessage: lastMessage,
          updatedAt: updatedAt,
        ),
      );
    }

    for (final group in groups) {
      final groupId = group['id'].toString();
      final memberIds = (group['memberIds'] as List<dynamic>)
          .map((id) => id.toString())
          .toList();
      final threadId = _groupThreadId(groupId);
      final groupMessages = await _fetchGroupConversation(groupId, threadId);
      final lastMessage = groupMessages.isNotEmpty
          ? groupMessages.last.content
          : 'Group created';
      final updatedAt = groupMessages.isNotEmpty
          ? groupMessages.last.sentAt
          : DateTime.tryParse(group['createdAt']?.toString() ?? '') ??
              DateTime.now();

      threads.add(
        ChatThread(
          id: threadId,
          title: group['name']?.toString() ?? 'Untitled Group',
          subtitle: '${memberIds.length} participants',
          isGroup: true,
          memberIds: memberIds,
          groupId: groupId,
          lastMessage: lastMessage,
          updatedAt: updatedAt,
        ),
      );
    }

    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    threadsNotifier.value = threads;
  }

  Future<List<ContactModel>> fetchChatFlowContacts() async {
    await initialize();
    return List<ContactModel>.unmodifiable(_contacts);
  }

  ContactModel? getContactById(String contactId) {
    for (final contact in _contacts) {
      if (contact.id == contactId) {
        return contact;
      }
    }
    return null;
  }

  ValueNotifier<List<ChatMessage>> messagesForThread(String threadId) {
    return _messagesNotifiers.putIfAbsent(
      threadId,
      () => ValueNotifier<List<ChatMessage>>([]),
    );
  }

  Future<ChatThread> createOrOpenDirectThread(ContactModel contact) async {
    await initialize();

    final existing = threadsNotifier.value.where((thread) {
      return !thread.isGroup && thread.directContactId == contact.id;
    });

    if (existing.isNotEmpty) {
      return existing.first;
    }

    final thread = ChatThread(
      id: _directThreadId(contact.id),
      title: contact.fullName,
      subtitle: contact.about,
      isGroup: false,
      memberIds: [currentUserId, contact.id],
      directContactId: contact.id,
      lastMessage: 'Start chatting',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    _upsertThread(thread);

    final messages = await _fetchDirectConversation(contact.id, thread.id);
    if (messages.isNotEmpty) {
      final latest = messages.last;
      final updated = thread.copyWith(
        lastMessage: latest.content,
        updatedAt: latest.sentAt,
      );
      _upsertThread(updated);
      return updated;
    }

    return thread;
  }

  Future<ChatThread> createGroupThread({
    required String groupName,
    required List<ContactModel> selectedContacts,
  }) async {
    await initialize();

    final headers = await _authService.authorizedJsonHeaders();
    final response = await http.post(
      Uri.parse(AppEndpoints.groups),
      headers: headers,
      body: jsonEncode({
        'name': groupName,
        'adminId': currentUserId,
        'memberIds': selectedContacts.map((c) => c.id).toList(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response, 'Failed to create group.'));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final groupId = decoded['id'].toString();
    final memberIds = (decoded['memberIds'] as List<dynamic>)
        .map((id) => id.toString())
        .toList();

    final thread = ChatThread(
      id: _groupThreadId(groupId),
      title: decoded['name']?.toString() ?? groupName,
      subtitle: '${memberIds.length} participants',
      isGroup: true,
      memberIds: memberIds,
      groupId: groupId,
      lastMessage: 'Group created',
      updatedAt: DateTime.tryParse(decoded['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );

    _upsertThread(thread);
    messagesForThread(thread.id).value = [];
    return thread;
  }

  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await initialize();

    if (senderId != currentUserId) {
      throw Exception('Invalid sender for current session.');
    }

    final thread = threadsNotifier.value.firstWhere(
      (item) => item.id == threadId,
      orElse: () => throw Exception('Thread not found.'),
    );

    final headers = await _authService.authorizedJsonHeaders();
    final url = thread.isGroup
        ? Uri.parse(AppEndpoints.groupMessages)
        : Uri.parse(AppEndpoints.directMessages);

    String? receiverUserId;
    if (!thread.isGroup) {
      receiverUserId = thread.directContactId;
      if (receiverUserId == null || receiverUserId.isEmpty) {
        for (final id in thread.memberIds) {
          if (id != currentUserId) {
            receiverUserId = id;
            break;
          }
        }
      }
      if (receiverUserId == null || receiverUserId.isEmpty) {
        throw Exception('Missing direct recipient for this thread.');
      }
    }

    final body = thread.isGroup
        ? {
            'senderId': currentUserId,
            'groupId': thread.groupId,
            'content': trimmed,
          }
        : {
            'senderId': currentUserId,
            'receiverUserId': receiverUserId,
            'content': trimmed,
          };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response, 'Failed to send message.'));
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final message = ChatMessage.fromJson(decoded, threadId: threadId);

    final notifier = messagesForThread(threadId);
    notifier.value = [...notifier.value, message];

    final updatedThread = thread.copyWith(
      lastMessage: message.content,
      updatedAt: message.sentAt,
    );
    _upsertThread(updatedThread);
  }

  Future<List<Map<String, dynamic>>> _fetchBackendUsers() async {
    final headers = await _authService.authorizedJsonHeaders();
    final response = await http.get(
      Uri.parse('${AppEndpoints.users}?excludeId=$currentUserId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response, 'Failed to load contacts.'));
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<ContactModel>> _filterSavedChatFlowContacts(
    List<Map<String, dynamic>> backendUsers,
  ) async {
    if (kIsWeb) {
      return [];
    }

    var contactsPermission = await Permission.contacts.status;
    if (!contactsPermission.isGranted && !contactsPermission.isLimited) {
      contactsPermission = await Permission.contacts.request();
    }

    if (!contactsPermission.isGranted && !contactsPermission.isLimited) {
      return [];
    }

    List<Contact> deviceContacts;
    try {
      deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
    } on MissingPluginException {
      return [];
    } on PlatformException {
      return [];
    }

    final savedNameByPhoneKey = <String, String>{};
    for (final contact in deviceContacts) {
      final savedName = contact.displayName.trim();
      if (savedName.isEmpty) {
        continue;
      }
      for (final phone in contact.phones) {
        for (final key in _phoneKeys(phone.number)) {
          savedNameByPhoneKey.putIfAbsent(key, () => savedName);
        }
      }
    }

    final matchedContacts = <ContactModel>[];
    for (final userJson in backendUsers) {
      final backendContact = ContactModel.fromJson(userJson);
      final phoneKeys = _phoneKeys(backendContact.phoneNumber);
      if (phoneKeys.isEmpty) {
        continue;
      }

      String? savedName;
      for (final key in phoneKeys) {
        final match = savedNameByPhoneKey[key];
        if (match != null) {
          savedName = match;
          break;
        }
      }

      if (savedName == null) {
        continue;
      }

      matchedContacts.add(
        ContactModel(
          id: backendContact.id,
          fullName: savedName,
          email: backendContact.email,
          phoneNumber: backendContact.phoneNumber,
          about: backendContact.about,
          isOnChatFlow: true,
          isSavedInDevice: true,
        ),
      );
    }

    matchedContacts.sort((a, b) => a.fullName.compareTo(b.fullName));
    return matchedContacts;
  }

  Future<List<Map<String, dynamic>>> _fetchGroupsForCurrentUser() async {
    final headers = await _authService.authorizedJsonHeaders();
    final response = await http.get(
      Uri.parse('${AppEndpoints.groups}?memberId=$currentUserId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response, 'Failed to load groups.'));
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<ChatMessage>> _fetchDirectConversation(
    String contactId,
    String threadId,
  ) async {
    final headers = await _authService.authorizedJsonHeaders();
    final response = await http.get(
      Uri.parse('${AppEndpoints.directMessages}/$currentUserId/$contactId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response, 'Failed to load direct conversation.'),
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final messages = decoded
        .whereType<Map<String, dynamic>>()
        .map((item) => ChatMessage.fromJson(item, threadId: threadId))
        .toList();

    messagesForThread(threadId).value = messages;
    return messages;
  }

  Future<List<ChatMessage>> _fetchGroupConversation(
    String groupId,
    String threadId,
  ) async {
    final headers = await _authService.authorizedJsonHeaders();
    final response = await http.get(
      Uri.parse('${AppEndpoints.groupMessages}/$groupId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(response, 'Failed to load group conversation.'),
      );
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    final messages = decoded
        .whereType<Map<String, dynamic>>()
        .map((item) => ChatMessage.fromJson(item, threadId: threadId))
        .toList();

    messagesForThread(threadId).value = messages;
    return messages;
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is List && message.isNotEmpty) {
          return message.first.toString();
        }
        if (message != null) {
          return message.toString();
        }
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  Set<String> _phoneKeys(String rawPhone) {
    final digitsOnly = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return {};
    }

    final keys = <String>{digitsOnly};
    if (digitsOnly.length > 10) {
      keys.add(digitsOnly.substring(digitsOnly.length - 10));
    }
    return keys;
  }

  String _directThreadId(String contactId) => 'd-$contactId';
  String _groupThreadId(String groupId) => 'g-$groupId';

  void _upsertThread(ChatThread thread) {
    final updated = [...threadsNotifier.value];
    final index = updated.indexWhere((item) => item.id == thread.id);

    if (index != -1) {
      updated.removeAt(index);
    }

    updated.insert(0, thread);
    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    threadsNotifier.value = updated;
  }

  void clearLocalCache() {
    _initialized = false;
    _currentUserId = null;
    _contacts = const [];
    threadsNotifier.value = [];
    for (final notifier in _messagesNotifiers.values) {
      notifier.value = [];
    }
    _messagesNotifiers.clear();
  }
}
