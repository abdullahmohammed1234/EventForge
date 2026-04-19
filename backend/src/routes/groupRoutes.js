const express = require('express');
const socialController = require('../controllers/socialController');
const { auth } = require('../middleware/auth');
const asyncWrapper = require('../utils/asyncWrapper');

const router = express.Router();

/**
 * @desc    Get current user's groups
 * @route   GET /api/groups
 * @access  Private
 */
router.get('/', auth, asyncWrapper(socialController.getMyGroups));

/**
 * @desc    Create a new group
 * @route   POST /api/groups
 * @access  Private
 */
router.post('/', auth, asyncWrapper(socialController.createGroup));

/**
 * @desc    Get group by ID
 * @route   GET /api/groups/:id
 * @access  Private
 */
router.get('/:id', auth, asyncWrapper(socialController.getGroup));

/**
 * @desc    Join a group
 * @route   POST /api/groups/:id/join
 * @access  Private
 */
router.post('/:id/join', auth, asyncWrapper(socialController.joinGroup));

/**
 * @desc    Leave a group
 * @route   POST /api/groups/:id/leave
 * @access  Private
 */
router.post('/:id/leave', auth, asyncWrapper(socialController.leaveGroup));

/**
 * @desc    Invite user to group (admin only)
 * @route   POST /api/groups/:id/invite
 * @access  Private
 */
router.post('/:id/invite', auth, asyncWrapper(socialController.inviteUserToGroup));

module.exports = router;