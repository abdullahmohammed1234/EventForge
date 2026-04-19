const User = require('../models/User');
const Group = require('../models/Group');
const { Message, Conversation } = require('../models/Message');
const mongoose = require('mongoose');

// @desc    Get friends
// @route   GET /api/friends
// @access  Private
const getFriends = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select('friends');
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    const friends = await User.find({ _id: { $in: user.friends } })
      .select('displayName avatarUrl city');
    
    res.json({ success: true, data: friends });
  } catch (error) {
    next(error);
  }
};

// @desc    Get friend requests
// @route   GET /api/friends/requests
// @access  Private
const getFriendRequests = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id)
      .populate('friendRequests', 'displayName avatarUrl city');
    
    res.json({ success: true, data: user.friendRequests || [] });
  } catch (error) {
    next(error);
  }
};

// @desc    Send friend request
// @route   POST /api/friends/request
// @access  Private
const sendFriendRequest = async (req, res, next) => {
  try {
    const { userId } = req.body;
    const targetUser = await User.findById(userId);
    
    if (!targetUser) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    // Check if already friends
    if (targetUser.friends.includes(req.user.id)) {
      return res.status(400).json({ success: false, error: 'Already friends' });
    }
    
    // Add to target user's friend requests if not already there
    if (!targetUser.friendRequests.includes(req.user.id)) {
      targetUser.friendRequests.push(req.user.id);
      await targetUser.save();
    }
    
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

// @desc    Accept friend request
// @route   POST /api/friends/request/accept
// @access  Private
const acceptFriendRequest = async (req, res, next) => {
  try {
    const { userId } = req.body;
    const user = await User.findById(req.user.id);
    const friendUser = await User.findById(userId);
    
    if (!friendUser) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    // Add each other as friends
    if (!user.friends.includes(userId)) {
      user.friends.push(userId);
    }
    if (!friendUser.friends.includes(req.user.id)) {
      friendUser.friends.push(req.user.id);
    }
    
    // Remove from friend requests
    user.friendRequests = user.friendRequests.filter(
      id => id.toString() !== userId
    );
    
    await Promise.all([user.save(), friendUser.save()]);
    
    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};

// @desc    Search users
// @route   GET /api/friends/search
// @access  Private
const searchUsers = async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q) {
      return res.json({ success: true, data: [] });
    }
    
    const user = await User.findById(req.user.id);
    const friends = user.friends || [];
    const requests = user.friendRequests || [];
    
    const users = await User.find({
      _id: { $nin: [...friends, ...requests, req.user.id] },
      $or: [
        { displayName: { $regex: q, $options: 'i' } },
        { email: { $regex: q, $options: 'i' } }
      ]
    }).select('displayName avatarUrl city').limit(20);
    
    res.json({ success: true, data: users });
  } catch (error) {
    next(error);
  }
};

// @desc    Get conversations
// @route   GET /api/messages
// @access  Private
const getConversations = async (req, res, next) => {
  try {
    const userGroups = await Group.find({ 'members.user': req.user.id }).select('_id');
    const groupIds = userGroups.map(g => g._id);
    
    const conversations = await Conversation.find({
      $or: [
        { participants: req.user.id },
        { type: 'group', groupId: { $in: groupIds } },
      ],
    })
      .populate('participants', 'displayName avatarUrl')
      .populate('groupId', 'name')
      .populate('lastMessage')
      .sort({ updatedAt: -1 });
    
    res.json({ success: true, data: conversations });
  } catch (error) {
    next(error);
  }
};

// @desc    Get or create direct conversation
// @route   POST /api/messages/conversation
// @access  Private
const getOrCreateConversation = async (req, res, next) => {
  try {
    const { userId } = req.body;
    
    let conversation = await Conversation.findOne({
      type: 'direct',
      participants: { $all: [req.user.id, userId] },
    }).populate('participants', 'displayName avatarUrl');
    
    if (!conversation) {
      conversation = await Conversation.create({
        type: 'direct',
        participants: [req.user.id, userId],
      });
      await conversation.populate('participants', 'displayName avatarUrl');
    }
    
    res.json({ success: true, data: conversation });
  } catch (error) {
    next(error);
  }
};

// @desc    Get or create group conversation
// @route   POST /api/messages/group/:groupId
// @access  Private
const getOrCreateGroupConversation = async (req, res, next) => {
  try {
    const { groupId } = req.params;
    
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({ success: false, error: 'Group not found' });
    }
    
    const isMember = group.members.some(m => m.user.toString() === req.user.id);
    if (!isMember) {
      return res.status(403).json({ success: false, error: 'Not a member of this group' });
    }
    
    let conversation = await Conversation.findOne({ groupId });
    if (!conversation) {
      conversation = await Conversation.create({
        type: 'group',
        participants: group.members.map(m => m.user),
        groupId: group._id,
      });
    }
    
    await conversation.populate('participants', 'displayName avatarUrl');
    await conversation.populate('groupId', 'name');
    
    res.json({ success: true, data: conversation });
  } catch (error) {
    next(error);
  }
};

// @desc    Get current user's groups (with user role)
// @route   GET /api/groups
// @access  Private
const getMyGroups = async (req, res, next) => {
  try {
    const groups = await Group.find({ 'members.user': req.user.id })
      .populate('members.user', 'displayName avatarUrl')
      .sort({ updatedAt: -1 });
    
    const groupsWithRole = groups.map(group => {
      const currentUserMember = group.members.find(
        m => m.user._id.toString() === req.user.id
      );
      const groupData = group.toObject();
      groupData.isCurrentUserAdmin = currentUserMember?.role === 'admin';
      groupData.userRole = currentUserMember?.role || 'none';
      return groupData;
    });
    
    res.json({
      success: true,
      data: groupsWithRole,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Create a new group
// @route   POST /api/groups
// @access  Private
const createGroup = async (req, res, next) => {
  try {
    const { name, description, isPrivate } = req.body;
    
    const group = await Group.create({
      name,
      description: description || '',
      creator: req.user.id,
      members: [{
        user: req.user.id,
        role: 'admin',
      }],
      isPrivate: isPrivate || false,
    });
    
    // Create a conversation for the group
    const conversation = await Conversation.create({
      type: 'group',
      participants: [req.user.id],
      groupId: group._id,
    });
    
    await group.populate('members.user', 'displayName avatarUrl');
    
    res.status(201).json({
      success: true,
      data: group,
      conversationId: conversation._id,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get group by ID
// @route   GET /api/groups/:id
// @access  Private
const getGroup = async (req, res, next) => {
  try {
const group = await Group.findById(req.params.id)
      .populate('members.user', 'displayName avatarUrl');
    
    // Add current user's admin status
    const currentUserMember = group.members.find(
      m => m.user._id.toString() === req.user.id
    );
    const isCurrentUserAdmin = currentUserMember?.role === 'admin';
    
    const groupData = group.toObject();
    groupData.isCurrentUserAdmin = isCurrentUserAdmin;
    groupData.userRole = currentUserMember?.role || 'none';
    
    res.json({
      success: true,
      data: groupData,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get all groups (with current user role)
// @route   GET /api/groups
// @access  Private
const getMyGroupsWithRole = async (req, res, next) => {
  try {
    const groups = await Group.find({ 'members.user': req.user.id })
      .populate('members.user', 'displayName avatarUrl')
      .sort({ updatedAt: -1 });
    
    const groupsWithRole = groups.map(group => {
      const currentUserMember = group.members.find(
        m => m.user._id.toString() === req.user.id
      );
      const groupData = group.toObject();
      groupData.isCurrentUserAdmin = currentUserMember?.role === 'admin';
      groupData.userRole = currentUserMember?.role || 'none';
      return groupData;
    });
    
    res.json({
      success: true,
      data: groupsWithRole,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get discoverable (public) groups
// @route   GET /api/groups/discover
// @access  Private
const discoverGroups = async (req, res, next) => {
  try {
    const { search = '', page = 1, limit = 20 } = req.query;
    
    // Get groups user is NOT a member of
    const myGroupIds = await Group.find({ 'members.user': req.user.id }).select('_id');
    const excludedIds = myGroupIds.map(g => g._id);
    
    const query = {
      _id: { $nin: excludedIds },
      isPrivate: false,
    };
    
    if (search) {
      query.name = { $regex: search, $options: 'i' };
    }
    
    const groups = await Group.find(query)
      .populate('members.user', 'displayName avatarUrl')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit));
    
    const total = await Group.countDocuments(query);
    
    res.json({
      success: true,
      data: groups,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Join a group
// @route   POST /api/groups/:id/join
// @access  Private
const joinGroup = async (req, res, next) => {
  try {
    const group = await Group.findById(req.params.id);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        error: 'Group not found',
      });
    }
    
    // Check if already a member
    const isMember = group.members.some(
      member => member.user.toString() === req.user.id
    );
    
    if (isMember) {
      return res.status(400).json({
        success: false,
        error: 'Already a member',
      });
    }
    
    group.members.push({
      user: req.user.id,
      role: 'member',
    });
    
    await group.save();
    await group.populate('members.user', 'displayName avatarUrl');
    
    // Create conversation for group
    let conversation = await Conversation.findOne({ groupId: group._id });
    if (!conversation) {
      conversation = await Conversation.create({
        type: 'group',
        participants: group.members.map(m => m.user),
        groupId: group._id,
      });
    }
    
    res.status(201).json({
      success: true,
      data: group,
      conversationId: conversation._id,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Invite user to group (admin only)
// @route   POST /api/groups/:id/invite
// @access  Private
const inviteUserToGroup = async (req, res, next) => {
  try {
    const { userId } = req.body;
    const group = await Group.findById(req.params.id);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        error: 'Group not found',
      });
    }
    
    // Check if current user is admin
    const isAdmin = group.members.some(
      m => m.user.toString() === req.user.id && m.role === 'admin'
    );
    
    if (!isAdmin) {
      return res.status(403).json({
        success: false,
        error: 'Only admins can invite users',
      });
    }
    
    // Check if user is already a member
    const isMember = group.members.some(m => m.user.toString() === userId);
    
    if (isMember) {
      return res.status(400).json({
        success: false,
        error: 'User is already a member',
      });
    }
    
    group.members.push({
      user: userId,
      role: 'member',
    });
    
    await group.save();
    await group.populate('members.user', 'displayName avatarUrl');
    
    res.json({
      success: true,
      data: group,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Leave a group
// @route   POST /api/groups/:id/leave
// @access  Private
const leaveGroup = async (req, res, next) => {
  try {
    const group = await Group.findById(req.params.id);
    
    if (!group) {
      return res.status(404).json({
        success: false,
        error: 'Group not found',
      });
    }
    
    const memberIndex = group.members.findIndex(
      m => m.user.toString() === req.user.id
    );
    
    if (memberIndex === -1) {
      return res.status(400).json({
        success: false,
        error: 'Not a member of this group',
      });
    }
    
    // Check if user is the last admin
    if (group.members[memberIndex].role === 'admin') {
      const adminCount = group.members.where(m => m.role === 'admin').length;
      if (adminCount <= 1) {
        return res.status(400).json({
          success: false,
          error: 'Cannot leave as the last admin. Assign another admin first.',
        });
      }
    }
    
    group.members.splice(memberIndex, 1);
    await group.save();
    
    res.json({
      success: true,
      data: group,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Update member role (promote/demote)
// @route   PUT /api/groups/:id/members/:userId/role
// @access  Private (Admin only)
const updateMemberRole = async (req, res, next) => {
  try {
    const { role } = req.body;
    const { id: groupId, userId } = req.params;
    
    const group = await Group.findById(groupId);
    if (!group) {
      return res.status(404).json({
        success: false,
        error: 'Group not found',
      });
    }
    
    // Check if current user is admin
    const currentUserIsAdmin = group.members.some(
      m => m.user.toString() === req.user.id && m.role === 'admin'
    );
    
    if (!currentUserIsAdmin) {
      return res.status(403).json({
        success: false,
        error: 'Only admins can change roles',
      });
    }
    
    // Find the member to update
    const memberIndex = group.members.findIndex(
      m => m.user.toString() === userId
    );
    
    if (memberIndex === -1) {
      return res.status(404).json({
        success: false,
        error: 'Member not found in group',
      });
    }
    
    // Cannot demote the last admin
    if (role !== 'admin') {
      const adminCount = group.members.where(m => m.role === 'admin').length;
      if (adminCount <= 1 && group.members[memberIndex].role === 'admin') {
        return res.status(400).json({
          success: false,
          error: 'Cannot demote the last admin',
        });
      }
    }
    
    group.members[memberIndex].role = role;
    await group.save();
    await group.populate('members.user', 'displayName avatarUrl');
    
    res.json({
      success: true,
      data: group,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get messages in conversation
// @route   GET /api/messages/:conversationId
// @access  Private
const getMessages = async (req, res, next) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    
    const conversation = await Conversation.findById(req.params.conversationId);
    
    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found',
      });
    }
    
    // Check if user is participant
    if (!conversation.participants.includes(req.user.id)) {
      return res.status(403).json({
        success: false,
        error: 'Not authorized',
      });
    }
    
    const messages = await Message.find({
      conversationId: req.params.conversationId,
    })
      .populate('sender', 'displayName avatarUrl')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(parseInt(limit));
    
    res.json({
      success: true,
      data: messages,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Send message
// @route   POST /api/messages/:conversationId
// @access  Private
const sendMessage = async (req, res, next) => {
  try {
    const { content, type, eventId } = req.body;
    
    if (!content) {
      return res.status(400).json({
        success: false,
        error: 'Message content is required',
      });
    }
    
    const conversation = await Conversation.findById(req.params.conversationId);
    
    if (!conversation) {
      return res.status(404).json({
        success: false,
        error: 'Conversation not found',
      });
    }
    
    // Check if user is participant OR member of the group
    let isAuthorized = conversation.participants.includes(req.user.id);
    
    // For group conversations, check if user is a member of the group
    if (!isAuthorized && conversation.type === 'group' && conversation.groupId) {
      const group = await Group.findById(conversation.groupId);
      if (group) {
        isAuthorized = group.members.some(m => m.user.toString() === req.user.id);
      }
    }
    
    if (!isAuthorized) {
      return res.status(403).json({
        success: false,
        error: 'Not authorized',
      });
    }
    
    const message = await Message.create({
      conversationId: req.params.conversationId,
      sender: req.user.id,
      content,
      type: type || 'text',
      eventId: eventId || null,
    });
    
    // Update conversation
    conversation.lastMessage = message._id;
    conversation.lastMessageAt = new Date();
    await conversation.save();
    
    await message.populate('sender', 'displayName avatarUrl');
    
    res.status(201).json({
      success: true,
      data: message,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getMyGroups,
  createGroup,
  getGroup,
  discoverGroups,
  joinGroup,
  leaveGroup,
  inviteUserToGroup,
  updateMemberRole,
  getFriends,
  getFriendRequests,
  sendFriendRequest,
  acceptFriendRequest,
  searchUsers,
  getConversations,
  getOrCreateConversation,
  getOrCreateGroupConversation,
  getMessages,
  sendMessage,
};