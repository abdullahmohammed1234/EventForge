import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';
import 'social_provider.dart';
import '../../core/api/social_service.dart';

class YourGroupsScreen extends StatefulWidget {
  const YourGroupsScreen({super.key});

  @override
  State<YourGroupsScreen> createState() => _YourGroupsScreenState();
}

class _YourGroupsScreenState extends State<YourGroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final socialProvider = context.read<SocialProvider>();

    final token = authProvider.token;
    if (token != null && !_isInitialized) {
      _isInitialized = true;
      await Future.wait([
        socialProvider.loadGroups(token),
        socialProvider.loadFriends(token),
        socialProvider.loadFriendRequests(token),
        socialProvider.loadSuggestions(token),
        socialProvider.loadConversations(token),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final socialProvider = context.watch<SocialProvider>();

    // Load data on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized && mounted) {
        _loadData();
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(user?.displayName ?? 'There'),
          _buildTabBar(),
          Expanded(
            child: _isInitialized &&
                    socialProvider.isLoading &&
                    socialProvider.groups.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildGroupsTab(socialProvider),
                      _buildFriendsTab(socialProvider),
                      _buildMessagesTab(socialProvider),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Text(
            'Hey, $userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildQuickAction(
            icon: Icons.person_add_outlined,
            onTap: () => _showAddFriendDialog(),
          ),
          const SizedBox(width: 8),
          _buildQuickAction(
            icon: Icons.add_circle_outline,
            onTap: () => _showCreateGroupDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: const Color(0xFFFE76B8)),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFFFE76B8),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFFFE76B8),
        indicatorWeight: 2,
        tabs: const [
          Tab(text: 'Groups'),
          Tab(text: 'Friends'),
          Tab(text: 'Messages'),
        ],
      ),
    );
  }

  Widget _buildGroupsTab(SocialProvider provider) {
    final groups = provider.groups;

    return RefreshIndicator(
      onRefresh: () async {
        final token = context.read<AuthProvider>().token;
        if (token != null) {
          await provider.loadGroups(token);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Your Groups', onViewAll: null),
            const SizedBox(height: 12),
            if (groups.isEmpty)
              _buildEmptyState(
                icon: Icons.group_add,
                title: 'No groups yet',
                subtitle: 'Create or join a group to get started!',
                onAction: _showCreateGroupDialog,
              )
            else
              ...groups.map((group) => _buildGroupCard(group, provider)),
            const SizedBox(height: 24),
            _buildDiscoverSection(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverSection(SocialProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Discover Groups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            TextButton(
              onPressed: () => _showDiscoverGroupsSheet(context, provider),
              child: const Text('Browse'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Find public groups to join',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  void _showDiscoverGroupsSheet(
      BuildContext context, SocialProvider provider) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DiscoverGroupsSheet(
        token: token,
        socialService: provider.socialService,
        onJoinGroup: () => provider.loadGroups(token),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View All >',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(SocialGroup group, SocialProvider provider) {
    return GestureDetector(
      onTap: () {
        // Navigate to group detail or show group info
        _showGroupInfoDialog(group);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.group,
                color: Color(0xFFFE76B8),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.memberCount} members',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFFFE76B8)),
              onPressed: () => _openGroupChat(group, provider),
              tooltip: 'Open Chat',
            ),
            if (group.isCurrentUserAdmin)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE76B8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showGroupInfoDialog(SocialGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.group,
                color: Color(0xFFFE76B8),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              group.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${group.memberCount} member${group.memberCount != 1 ? 's' : ''}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            if (group.description != null && group.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                group.description!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildGroupActionButton(
                  icon: Icons.person_add,
                  label: 'Invite',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showInviteToGroup(group);
                  },
                ),
                _buildGroupActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareGroup(group);
                  },
                ),
                if (group.isCurrentUserAdmin)
                  _buildGroupActionButton(
                    icon: Icons.exit_to_app,
                    label: 'Leave',
                    color: Colors.red,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _handleLeaveGroup(group);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFFFE76B8),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLeaveGroup(SocialGroup group) async {
    final confirmed = await _showLeaveGroupConfirmation(group.name);
    if (confirmed) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final provider = context.read<SocialProvider>();
        await provider.leaveGroup(token, group.id);
      }
    }
  }

  void _shareGroup(SocialGroup group) {
    final provider = context.read<SocialProvider>();
    final friends = provider.friends;

    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add friends first to share!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share "${group.name}" with friends',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...friends.take(5).map((f) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFE4F0),
                    child: Text(f.displayName[0]),
                  ),
                  title: Text(f.displayName),
                  trailing: IconButton(
                    icon: const Icon(Icons.share),
                    color: const Color(0xFFFE76B8),
                    onPressed: () async {
                      final token = context.read<AuthProvider>().token;
                      if (token != null) {
                        final provider = context.read<SocialProvider>();
                        final convId =
                            await provider.getOrCreateConversation(token, f.id);
                        if (convId != null) {
                          await provider.sendMessage(
                            token,
                            convId,
                            'Check out my group "${group.name}"! It has ${group.memberCount} members.',
                          );
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Shared with ${f.displayName}!')),
                            );
                          }
                        }
                      }
                    },
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showInviteToGroup(SocialGroup group) {
    final provider = context.read<SocialProvider>();
    final friends = provider.friends;

    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add friends first to invite them!')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invite friends to "${group.name}"',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...friends.take(5).map((f) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFE4F0),
                    child: Text(f.displayName[0]),
                  ),
                  title: Text(f.displayName),
                  trailing: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    color: const Color(0xFFFE76B8),
                    onPressed: () async {
                      final token = context.read<AuthProvider>().token;
                      if (token != null) {
                        final provider = context.read<SocialProvider>();
                        // First create or get conversation, then send invite message
                        final convId =
                            await provider.getOrCreateConversation(token, f.id);
                        if (convId != null) {
                          final msgSent = await provider.sendMessage(
                              token,
                              convId,
                              'Hey! Come join my group "${group.name}"!');
                          if (msgSent && context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Invited ${f.displayName} to chat!'),
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsTab(SocialProvider provider) {
    final requests = provider.friendRequests;
    final suggestions = provider.suggestions;

    return RefreshIndicator(
      onRefresh: () async {
        final token = context.read<AuthProvider>().token;
        if (token != null) {
          await provider.loadFriends(token);
          await provider.loadFriendRequests(token);
          await provider.loadSuggestions(token);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Friend suggestions
            if (suggestions.isNotEmpty) ...[
              _buildSectionTitle('People You May Know', onViewAll: null),
              const SizedBox(height: 12),
              ...suggestions.map((s) => _buildSuggestionCard(s, provider)),
              const SizedBox(height: 20),
            ],

            // Friend requests
            if (requests.isNotEmpty) ...[
              _buildSectionTitle('Friend Requests', onViewAll: null),
              const SizedBox(height: 12),
              ...requests.map((r) => _buildFriendRequestCard(r, provider)),
              const SizedBox(height: 20),
            ],

            // Online friends
            _buildOnlineFriendsSection(provider),
            _buildAllFriendsSection(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard(
      FriendRequest request, SocialProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFFE4F0),
            child: Text(
              request.from.displayName[0],
              style: const TextStyle(
                color: Color(0xFFFE76B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.from.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  request.from.city ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final token = context.read<AuthProvider>().token;
              if (token != null) {
                await provider.acceptFriendRequest(token, request.id);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFE76B8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(SocialFriend friend, SocialProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFFE4F0),
            child: Text(
              friend.displayName[0],
              style: const TextStyle(
                color: Color(0xFFFE76B8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  friend.city ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final token = context.read<AuthProvider>().token;
              if (token != null) {
                final success =
                    await provider.sendFriendRequest(token, friend.id);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Friend request sent!')),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFE76B8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineFriendChip(SocialFriend friend, SocialProvider provider) {
    return GestureDetector(
      onTap: () => _showMessageDialog(friend, provider),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFFFE4F0),
                  child: Text(
                    friend.displayName[0],
                    style: const TextStyle(
                      color: Color(0xFFFE76B8),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              friend.displayName.split(' ')[0],
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendListItem(SocialFriend friend, SocialProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFFFE4F0),
                child: Text(
                  friend.displayName[0],
                  style: const TextStyle(
                    color: Color(0xFFFE76B8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (friend.status == 'online')
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  friend.status == 'online'
                      ? 'Online'
                      : friend.city ?? 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: friend.status == 'online'
                        ? Colors.green
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          _buildActionButton(
            icon: Icons.message_outlined,
            onTap: () => _showMessageDialog(friend, provider),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.share_outlined,
            onTap: () => _showShareOptions(friend),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4F0),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFFFE76B8)),
      ),
    );
  }

  Widget _buildMessagesTab(SocialProvider provider) {
    final conversations = provider.conversations;

    return RefreshIndicator(
      onRefresh: () async {
        final token = context.read<AuthProvider>().token;
        if (token != null) {
          await provider.loadConversations(token);
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Conversations', onViewAll: null),
            const SizedBox(height: 12),
            if (conversations.isEmpty)
              _buildEmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No conversations yet',
                subtitle: 'Start a conversation with a friend!',
                onAction: () => _showCreateChatDialog(provider),
              )
            else
              ...conversations.map((c) => _buildChatPreview(c, provider)),
            const SizedBox(height: 24),
            _buildCreateChatCard(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPreview(Conversation conversation, SocialProvider provider) {
    final userId = context.read<AuthProvider>().user?.id ?? '';
    final unreadCount = conversation.getUnread(userId);
    final chatName = conversation.getNameForUser(userId);

    return GestureDetector(
      onTap: () {
        context.push('/messages/${conversation.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFFE4F0),
                  child: Text(
                    conversation.name[0],
                    style: const TextStyle(
                      color: Color(0xFFFE76B8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        chatName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        conversation.lastMessageAt,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage?.content ?? '',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFE76B8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateChatCard(SocialProvider provider) {
    return GestureDetector(
      onTap: () => _showCreateChatDialog(provider),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFE76B8),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Color(0xFFFE76B8)),
            ),
            const SizedBox(width: 16),
            const Text(
              'Start New Conversation',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFFE76B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE76B8),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showLeaveGroupConfirmation(String groupName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Group'),
            content: Text('Are you sure you want to leave "$groupName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showAddFriendDialog() {
    final textController = TextEditingController();
    final socialProvider = context.read<SocialProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Friend',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (query) async {
                if (query.length >= 2) {
                  final token = context.read<AuthProvider>().token;
                  if (token != null) {
                    // Search and show results
                    final users =
                        await socialProvider.searchUsers(token, query);
                    _showSearchResults(users);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final query = textController.text;
                  if (query.length >= 2) {
                    final token = context.read<AuthProvider>().token;
                    if (token != null) {
                      final users =
                          await socialProvider.searchUsers(token, query);
                      _showSearchResults(users);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE76B8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  void _showSearchResults(List<SocialFriend> users) {
    Navigator.pop(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Results (${users.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (users.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No users found'),
                ),
              )
            else
              ...users.take(5).map((u) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFE4F0),
                      child: Text(u.displayName[0]),
                    ),
                    title: Text(u.displayName),
                    subtitle: Text(u.city ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_add),
                      color: const Color(0xFFFE76B8),
                      onPressed: () async {
                        final token = context.read<AuthProvider>().token;
                        final provider = context.read<SocialProvider>();
                        final success =
                            await provider.sendFriendRequest(token!, u.id);
                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Friend request sent to ${u.displayName}!')),
                          );
                        }
                      },
                    ),
                  )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openGroupChat(
      SocialGroup group, SocialProvider provider) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    try {
      final response =
          await provider.socialService.getOrCreateGroupConversation(
        token,
        group.id,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conversationId = data['data']['id'];

        if (mounted) {
          context.push('/messages/$conversationId');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open chat: $e')),
        );
      }
    }
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Group',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Group name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    final token = context.read<AuthProvider>().token;
                    final provider = context.read<SocialProvider>();
                    if (token != null) {
                      await provider.createGroup(
                        token,
                        nameController.text.trim(),
                        descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        false,
                      );
                      Navigator.pop(context);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE76B8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageDialog(SocialFriend friend, SocialProvider provider) async {
    final token = context.read<AuthProvider>().token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not logged in')),
      );
      return;
    }

    try {
      final conversationId =
          await provider.getOrCreateConversation(token, friend.id);
      if (conversationId != null && mounted) {
        context.push('/messages/$conversationId');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create conversation')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showShareOptions(SocialFriend friend) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share with ${friend.displayName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event, color: Color(0xFFFE76B8)),
              ),
              title: const Text('Share Event'),
              subtitle: const Text('Invite to an event'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.article, color: Color(0xFFFE76B8)),
              ),
              title: const Text('Share Post'),
              subtitle: const Text('Share a post or update'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCreateChatDialog(SocialProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Conversation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a friend to start chatting',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (provider.friends.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Add friends first to start a conversation'),
              )
            else
              ...provider.friends.take(5).map((f) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFE4F0),
                      child: Text(f.displayName[0]),
                    ),
                    title: Text(f.displayName),
                    onTap: () {
                      Navigator.pop(context);
                      _showMessageDialog(f, provider);
                    },
                  )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineFriendsSection(SocialProvider provider) {
    final onlineFriends =
        provider.friends.where((f) => f.status == 'online').toList();
    if (onlineFriends.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Online Now', onViewAll: null),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: onlineFriends
                .map((f) => _buildOnlineFriendChip(f, provider))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAllFriendsSection(SocialProvider provider) {
    final friends = provider.friends;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('All Friends', onViewAll: null),
        const SizedBox(height: 12),
        if (friends.isEmpty)
          _buildEmptyState(
            icon: Icons.person_add,
            title: 'No friends yet',
            subtitle: 'Add friends to connect and share events!',
            onAction: _showAddFriendDialog,
          )
        else
          ...friends.map((f) => _buildFriendListItem(f, provider)),
      ],
    );
  }
}

class _DiscoverGroupsSheet extends StatefulWidget {
  final String token;
  final SocialService socialService;
  final VoidCallback onJoinGroup;

  const _DiscoverGroupsSheet({
    required this.token,
    required this.socialService,
    required this.onJoinGroup,
  });

  @override
  State<_DiscoverGroupsSheet> createState() => _DiscoverGroupsSheetState();
}

class _DiscoverGroupsSheetState extends State<_DiscoverGroupsSheet> {
  List<SocialGroup> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final response = await widget.socialService.discoverGroups(widget.token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _groups = (data['data'] as List)
              .map((g) => SocialGroup.fromJson(g))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey)),
            ),
            child: Row(
              children: [
                const Text(
                  'Discover Groups',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groups.isEmpty
                    ? const Center(
                        child: Text('No groups to discover'),
                      )
                    : ListView.builder(
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFFFE4F0),
                              child: const Icon(Icons.group,
                                  color: Color(0xFFFE76B8)),
                            ),
                            title: Text(group.name),
                            subtitle: Text('${group.memberCount} members'),
                            trailing: ElevatedButton(
                              onPressed: () => _joinGroup(group.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFE76B8),
                              ),
                              child: const Text('Join'),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _joinGroup(String groupId) async {
    try {
      final response =
          await widget.socialService.joinGroup(widget.token, groupId);
      if (response.statusCode == 200) {
        widget.onJoinGroup();
        setState(() {
          _groups.removeWhere((g) => g.id == groupId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined group!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    }
  }
}
