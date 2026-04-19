const express = require('express');
const socialController = require('../controllers/socialController');
const { auth } = require('../middleware/auth');
const asyncWrapper = require('../utils/asyncWrapper');

const router = express.Router();

/**
 * @desc    Get conversations
 * @route   GET /api/messages
 * @access  Private
 */
router.get('/', auth, asyncWrapper(socialController.getConversations));

/**
 * @desc    Get or create conversation
 * @route   POST /api/messages/conversation
 * @access  Private
 */
router.post('/conversation', auth, asyncWrapper(socialController.getOrCreateConversation));

/**
 * @desc    Get or create group conversation
 * @route   POST /api/messages/group/:groupId
 * @access  Private
 */
router.post('/group/:groupId', auth, asyncWrapper(socialController.getOrCreateGroupConversation));

/**
 * @desc    Get messages in conversation
 * @route   GET /api/messages/:conversationId
 * @access  Private
 */
router.get('/:conversationId', auth, asyncWrapper(socialController.getMessages));

/**
 * @desc    Send message
 * @route   POST /api/messages/:conversationId
 * @access  Private
 */
router.post('/:conversationId', auth, asyncWrapper(socialController.sendMessage));

module.exports = router;