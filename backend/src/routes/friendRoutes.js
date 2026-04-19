const express = require('express');
const socialController = require('../controllers/socialController');
const { auth } = require('../middleware/auth');
const asyncWrapper = require('../utils/asyncWrapper');

const router = express.Router();

/**
 * @desc    Get friends list
 * @route   GET /api/friends
 * @access  Private
 */
router.get('/', auth, asyncWrapper(socialController.getFriends));

/**
 * @desc    Get friend requests
 * @route   GET /api/friends/requests
 * @access  Private
 */
router.get('/requests', auth, asyncWrapper(socialController.getFriendRequests));

/**
 * @desc    Search users
 * @route   GET /api/friends/search
 * @access  Private
 */
router.get('/search', auth, asyncWrapper(socialController.searchUsers));

/**
 * @desc    Get friend suggestions
 * @route   GET /api/friends/suggestions
 * @access  Private
 */
router.get('/suggestions', auth, asyncWrapper(socialController.getSuggestions));

/**
 * @desc    Send friend request
 * @route   POST /api/friends/request
 * @access  Private
 */
router.post('/request', auth, asyncWrapper(socialController.sendFriendRequest));

/**
 * @desc    Accept friend request
 * @route   POST /api/friends/accept/:requestId
 * @access  Private
 */
router.post('/accept/:requestId', auth, asyncWrapper(socialController.acceptFriendRequest));

module.exports = router;