import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/social_service.dart';
import '../auth/auth_provider.dart';

class GroupMember {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final DateTime? joinedAt;

  GroupMember({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.role = 'member',
    this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] : json;
    return GroupMember(
      id: user['id'] ?? user['_id'] ?? '',
      displayName: user['displayName'] ?? 'Unknown',
      avatarUrl: user['avatarUrl'],
      role: json['role'] ?? 'member',
      joinedAt:
          json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : null,
    );
  }
}

class SocialGroup {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final int memberCount;
  final bool isCurrentUserAdmin;
  final String? userRole;
  final List<GroupMember> members;
  final DateTime createdAt;

  SocialGroup({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.memberCount = 0,
    this.isCurrentUserAdmin = false,
    this.userRole,
    this.members = const [],
    required this.createdAt,
  });

  factory SocialGroup.fromJson(Map<String, dynamic> json) {
    final membersList = (json['members'] as List?)
            ?.map((m) => GroupMember.fromJson(m))
            .toList() ??
        [];

    return SocialGroup(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'],
      description: json['description'],
      coverImageUrl: json['coverImageUrl'],
      memberCount: json['memberCount'] ?? membersList.length,
      isCurrentUserAdmin: json['isCurrentUserAdmin'] ?? false,
      userRole: json['userRole'],
      members: membersList,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'memberCount': memberCount,
      'isCurrentUserAdmin': isCurrentUserAdmin,
      'userRole': userRole,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class SocialFriend {
  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? city;
  final String status;

  SocialFriend({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.city,
    this.status = 'offline',
  });

  factory SocialFriend.fromJson(Map<String, dynamic> json) {
    return SocialFriend(
      id: json['id'] ?? json['_id'] ?? '',
      displayName: json['displayName'] ?? 'Unknown',
      avatarUrl: json['avatarUrl'],
      city: json['city'],
      status: json['isActive'] == true ? 'online' : 'offline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'city': city,
      'status': status,
    };
  }
}

class FriendRequest {
  final String id;
  final SocialFriend from;
  final String status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.from,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['_id'] ?? '',
      from: SocialFriend.fromJson(json['from'] ?? {}),
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Conversation {
  final String id;
  final String type;
  final List<SocialFriend> participants;
  final String? groupName;
  final Message? lastMessage;
  final String lastMessageAt;
  final Map<String, int> unreadCount;

  Conversation({
    required this.id,
    required this.type,
    required this.participants,
    this.groupName,
    this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = const {},
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final lastMessageData = json['lastMessage'];
    Message? lastMessage;
    if (lastMessageData is Map<String, dynamic>) {
      lastMessage = Message.fromJson(lastMessageData);
    }

    final groupData = json['groupId'];
    String? groupName;
    if (groupData is Map<String, dynamic>) {
      groupName = groupData['name'];
    }

    return Conversation(
      id: json['id'] ?? json['_id'] ?? '',
      type: json['type'] ?? 'direct',
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => SocialFriend.fromJson(p))
              .toList() ??
          [],
      groupName: groupName,
      lastMessage: lastMessage,
      lastMessageAt: json['lastMessageAt'] ?? '',
      unreadCount: Map<String, int>.from(json['unreadCount'] ?? {}),
    );
  }

  String getNameForUser(String currentUserId) {
    if (type == 'group') {
      return groupName ?? 'Group Chat';
    }
    if (participants.isEmpty) return 'Chat';

    // Find the participant who is NOT the current user
    final other = participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );

    return other.displayName ?? 'Chat';
  }

  String get name => participants.isNotEmpty
      ? (participants.first.displayName ?? 'Chat')
      : 'Chat';

  int getUnread(String userId) => unreadCount[userId] ?? 0;
}

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String type;
  final String createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['_id'] ?? '',
      senderId: json['sender'] is Map
          ? json['sender']['id'] ?? json['sender']['_id'] ?? ''
          : json['sender'] ?? '',
      senderName: json['sender'] is Map
          ? json['sender']['displayName'] ?? 'Unknown'
          : 'Unknown',
      senderAvatar: json['sender'] is Map ? json['sender']['avatarUrl'] : null,
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      createdAt: json['createdAt'] ?? '',
      isRead: json['isRead'] ?? false,
    );
  }
}

class SocialProvider with ChangeNotifier {
  final SocialService socialService;

  SocialProvider({required this.socialService});

  List<SocialGroup> _groups = [];
  List<SocialFriend> _friends = [];
  List<FriendRequest> _friendRequests = [];
  List<SocialFriend> _suggestions = [];
  List<Conversation> _conversations = [];
  List<Message> _currentMessages = [];

  bool _isLoading = false;
  String? _error;

  List<SocialGroup> get groups => _groups;
  List<SocialFriend> get friends => _friends;
  List<FriendRequest> get friendRequests => _friendRequests;
  List<SocialFriend> get suggestions => _suggestions;
  List<Conversation> get conversations => _conversations;
  List<Message> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadGroups(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await socialService.getGroups(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _groups = (data['data'] as List<dynamic>?)
                ?.map((g) => SocialGroup.fromJson(g))
                .toList() ??
            [];
      } else {
        _error = 'Failed to load groups';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SocialGroup?> getGroupDetails(String token, String groupId) async {
    try {
      final response = await socialService.getGroup(token, groupId);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SocialGroup.fromJson(data['data']);
      }
    } catch (e) {
      debugPrint('Failed to get group: $e');
    }
    return null;
  }

  Future<bool> updateMemberRole(
      String token, String groupId, String userId, String role) async {
    try {
      final response =
          await socialService.updateMemberRole(token, groupId, userId, role);
      if (response.statusCode == 200) {
        // Reload groups to get updated member info
        await loadGroups(token);
        return true;
      }
    } catch (e) {
      debugPrint('Failed to update role: $e');
    }
    return false;
  }

  Future<bool> createGroup(
      String token, String name, String? description, bool isPrivate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await socialService.createGroup(token, name, description, isPrivate);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newGroup = SocialGroup.fromJson(data['data']);
        _groups.insert(0, newGroup);
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create group';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinGroup(String token, String groupId) async {
    try {
      final response = await socialService.joinGroup(token, groupId);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> leaveGroup(String token, String groupId) async {
    try {
      final response = await socialService.leaveGroup(token, groupId);
      if (response.statusCode == 200) {
        _groups.removeWhere((g) => g.id == groupId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> inviteUserToGroup(
      String token, String groupId, String userId) async {
    try {
      final response =
          await socialService.inviteUserToGroup(token, groupId, userId);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadFriends(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await socialService.getFriends(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _friends = (data['data'] as List<dynamic>?)
                ?.map((f) => SocialFriend.fromJson(f))
                .toList() ??
            [];
      } else {
        _error = 'Failed to load friends';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFriendRequests(String token) async {
    try {
      final response = await socialService.getFriendRequests(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _friendRequests = (data['data'] as List<dynamic>?)
                ?.map((r) => FriendRequest.fromJson(r))
                .toList() ??
            [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load friend requests: $e');
    }
  }

  Future<void> loadSuggestions(String token) async {
    try {
      final response = await socialService.getSuggestions(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _suggestions = (data['data'] as List<dynamic>?)
                ?.map((u) => SocialFriend.fromJson(u))
                .toList() ??
            [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load suggestions: $e');
    }
  }

  Future<List<SocialFriend>> searchUsers(String token, String query) async {
    try {
      final response = await socialService.searchUsers(token, query);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List<dynamic>?)
                ?.map((u) => SocialFriend.fromJson(u))
                .toList() ??
            [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> sendFriendRequest(String token, String userId) async {
    try {
      final response = await socialService.sendFriendRequest(token, userId);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> acceptFriendRequest(String token, String requestId) async {
    try {
      final response =
          await socialService.acceptFriendRequest(token, requestId);
      if (response.statusCode == 200) {
        _friendRequests.removeWhere((r) => r.id == requestId);
        notifyListeners();
        // Reload friends list to see the new friend
        await loadFriends(token);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadConversations(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await socialService.getConversations(token);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _conversations = (data['data'] as List<dynamic>?)
                ?.map((c) => Conversation.fromJson(c))
                .toList() ??
            [];
      } else {
        _error = 'Failed to load conversations';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getOrCreateConversation(String token, String userId) async {
    try {
      final response =
          await socialService.getOrCreateConversation(token, userId);

      debugPrint(
          'getOrCreateConversation response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversation = Conversation.fromJson(data['data']);

        final existingIndex =
            _conversations.indexWhere((c) => c.id == conversation.id);
        if (existingIndex >= 0) {
          _conversations[existingIndex] = conversation;
        } else {
          _conversations.insert(0, conversation);
        }
        notifyListeners();

        return conversation.id;
      }
      return null;
    } catch (e) {
      debugPrint('getOrCreateConversation error: $e');
      return null;
    }
  }

  Future<void> loadMessages(String token, String conversationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await socialService.getMessages(token, conversationId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentMessages = (data['data'] as List<dynamic>?)
                ?.map((m) => Message.fromJson(m))
                .toList() ??
            [];
      }
    } catch (e) {
      debugPrint('Failed to load messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(
      String token, String conversationId, String content) async {
    try {
      final response =
          await socialService.sendMessage(token, conversationId, content);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _currentMessages.insert(0, Message.fromJson(data['data']));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadAllData(BuildContext context) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token == null) return;

    await Future.wait([
      loadGroups(token),
      loadFriends(token),
      loadFriendRequests(token),
      loadSuggestions(token),
      loadConversations(token),
    ]);
  }
}
