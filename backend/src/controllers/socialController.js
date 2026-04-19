const User = require('../models/User');
const Group = require('../models/Group');
const { Message, Conversation } = require('../models/Message');
const mongoose = require('mongoose');

// @desc    Get current user's groups
// @route   GET /api/groups
// @access  Private
const getMyGroups = async (req, res, next) => {
  try {
    const groups = await Group.find({ 'members.user': req.user.id })
      .populate('members.user', 'displayName avatarUrl')
      .sort({ updatedAt: -1 });
    
    res.json({
      success: true,
      data: groups,
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
    
    await group.populate('members.user', 'displayName avatarUrl');
    
    res.status(201).json({
      success: true,
      data: group,
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
    
    if (!group) {
      return res.status(404).json({
        success: false,
        error: 'Group not found',
      });
    }
    
    res.json({
      success: true,
      data: group,
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
    
    group.members = group.members.filter(
      member => member.user.toString() !== req.user.id
    );
    
    await group.save();
    
    res.json({
      success: true,
      message: 'Left group successfully',
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

// @desc    Get friends list
// @route   GET /api/friends
// @access  Private
const getFriends = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    
    const friends = await User.find({
      _id: { $in: user.friends },
    }).select('displayName avatarUrl city isActive');
    
    res.json({
      success: true,
      data: friends,
    });
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
      .populate('friendRequests.from', 'displayName avatarUrl city');
    
    const pendingRequests = user.friendRequests.filter(
      req => req.status === 'pending'
    );
    
    res.json({
      success: true,
      data: pendingRequests,
    });
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
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'User ID is required',
      });
    }
    
    // Can't add yourself
    if (userId === req.user.id) {
      return res.status(400).json({
        success: false,
        error: 'Cannot add yourself',
      });
    }
    
    const targetUser = await User.findById(userId);
    
    if (!targetUser) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }
    
    const currentUser = await User.findById(req.user.id);
    
    // Check if already friends
    if (currentUser.friends.includes(userId)) {
      return res.status(400).json({
        success: false,
        error: 'Already friends',
      });
    }
    
    // Check if request already sent
    const existingRequest = targetUser.friendRequests.find(
      req => req.from.toString() === req.user.id && req.status === 'pending'
    );
    
    if (existingRequest) {
      return res.status(400).json({
        success: false,
        error: 'Request already sent',
      });
    }
    
    targetUser.friendRequests.push({
      from: req.user.id,
      status: 'pending',
    });
    
    await targetUser.save();
    
    res.json({
      success: true,
      message: 'Friend request sent',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Accept friend request
// @route   POST /api/friends/accept/:requestId
// @access  Private
const acceptFriendRequest = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    
    const request = user.friendRequests.id(req.params.requestId);
    
    if (!request) {
      return res.status(404).json({
        success: false,
        error: 'Request not found',
      });
    }
    
    if (request.status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: 'Request already processed',
      });
    }
    
    // Add friends to both users
    const requester = await User.findById(request.from);
    
    user.friends.push(request.from);
    requester.friends.push(user._id);
    
    request.status = 'accepted';
    
    await user.save();
    await requester.save();
    
    res.json({
      success: true,
      message: 'Friend request accepted',
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get user by search
// @route   GET /api/friends/search
// @access  Private
const searchUsers = async (req, res, next) => {
  try {
    const { q } = req.query;
    
    if (!q || q.length < 2) {
      return res.status(400).json({
        success: false,
        error: 'Search query must be at least 2 characters',
      });
    }
    
    const currentUser = await User.findById(req.user.id);
    
    // Search by name or email
    const users = await User.find({
      $and: [
        { _id: { $ne: req.user.id } },
        { _id: { $nin: currentUser.friends } },
        {
          $or: [
            { displayName: { $regex: q, $options: 'i' } },
            { email: { $regex: q, $options: 'i' } },
          ],
        },
      ],
    }).select('displayName avatarUrl email city').limit(20);
    
    res.json({
      success: true,
      data: users,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get friend suggestions
// @route   GET /api/friends/suggestions
// @access  Private
const getSuggestions = async (req, res, next) => {
  try {
    const currentUser = await User.findById(req.user.id);
    
    // Get user's friends
    const userFriends = currentUser.friends;
    
    // Find users who are friends of friends (friends of friends)
    let suggestions = [];
    
    // Get friends of friends
    if (userFriends.length > 0) {
      const friendOfFriends = await User.aggregate([
        { $match: { _id: { $in: userFriends } } },
        { $unwind: '$friends' },
        { $group: { _id: '$friends' } },
        { $match: { _id: { $nin: [...userFriends, req.user.id] } } },
        { $limit: 10 }
      ]);
      
      const friendIds = friendOfFriends.map(f => f._id);
      suggestions = await User.find({ _id: { $in: friendIds } })
        .select('displayName avatarUrl city');
    }
    
    // If not enough suggestions, add users from same city
    if (suggestions.length < 5 && currentUser.city) {
      const citySuggestions = await User.find({
        _id: { $nin: [...userFriends, req.user.id, ...suggestions.map(s => s._id)] },
        city: currentUser.city,
      }).select('displayName avatarUrl city').limit(10 - suggestions.length);
      
      suggestions = [...suggestions, ...citySuggestions];
    }
    
    // If still not enough, add random active users
    if (suggestions.length < 5) {
      const randomSuggestions = await User.find({
        _id: { $nin: [...userFriends, req.user.id, ...suggestions.map(s => s._id)] },
        isActive: true,
      }).select('displayName avatarUrl city').limit(5 - suggestions.length);
      
      suggestions = [...suggestions, ...randomSuggestions];
    }
    
    res.json({
      success: true,
      data: suggestions,
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get conversations
// @route   GET /api/messages
// @access  Private
const getConversations = async (req, res, next) => {
  try {
    const conversations = await Conversation.find({
      participants: req.user.id,
    })
      .populate('participants', 'displayName avatarUrl')
      .populate('lastMessage')
      .sort({ lastMessageAt: -1 });
    
    res.json({
      success: true,
      data: conversations,
    });
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
    
    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'User ID is required',
      });
    }
    
    // Find existing conversation
    let conversation = await Conversation.findOne({
      type: 'direct',
      participants: { $all: [req.user.id, userId] },
    }).populate('participants', 'displayName avatarUrl');
    
    if (!conversation) {
      // Create new conversation
      conversation = await Conversation.create({
        type: 'direct',
        participants: [req.user.id, userId],
      });
      await conversation.populate('participants', 'displayName avatarUrl');
    }
    
    res.json({
      success: true,
      data: conversation,
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
    
    // Check if user is participant
    if (!conversation.participants.includes(req.user.id)) {
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
  joinGroup,
  leaveGroup,
  inviteUserToGroup,
  getFriends,
  getFriendRequests,
  sendFriendRequest,
  acceptFriendRequest,
  searchUsers,
  getConversations,
  getOrCreateConversation,
  getMessages,
  sendMessage,
};