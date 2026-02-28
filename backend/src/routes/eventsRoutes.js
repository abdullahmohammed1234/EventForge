const express = require('express');
const { body, query } = require('express-validator');
const eventsController = require('../controllers/eventsController');
const { auth, optionalAuth } = require('../middleware/auth');
const asyncWrapper = require('../utils/asyncWrapper');

const router = express.Router();

/**
 * @desc    Get all events
 * @route   GET /api/events
 * @access  Public
 */
router.get(
  '/',
  optionalAuth,
  [
    query('page')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Page must be a positive integer'),
    query('limit')
      .optional()
      .isInt({ min: 1, max: 100 })
      .withMessage('Limit must be between 1 and 100'),
    query('city')
      .optional()
      .trim()
      .isLength({ max: 100 })
      .withMessage('City cannot exceed 100 characters'),
    query('category')
      .optional()
      .isIn([
        'music',
        'sports',
        'arts',
        'food',
        'technology',
        'business',
        'social',
        'outdoor',
        'other',
      ])
      .withMessage('Invalid category'),
  ],
  asyncWrapper(eventsController.getEvents)
);

/**
 * @desc    Get events user has registered for
 * @route   GET /api/events/registered
 * @access  Private
 */
router.get('/registered', auth, asyncWrapper(eventsController.getRegisteredEvents));

/**
 * @desc    Get events created by current user
 * @route   GET /api/events/my-events
 * @access  Private
 */
router.get('/my-events', auth, asyncWrapper(eventsController.getMyEvents));

/**
 * @desc    Get single event by ID
 * @route   GET /api/events/:id
 * @access  Public
 */
router.get('/:id', optionalAuth, asyncWrapper(eventsController.getEvent));

/**
 * @desc    Create new event
 * @route   POST /api/events
 * @access  Private
 */
router.post(
  '/',
  auth,
  [
    body('title')
      .trim()
      .notEmpty()
      .withMessage('Event title is required')
      .isLength({ max: 200 })
      .withMessage('Title cannot exceed 200 characters'),
    body('description')
      .optional()
      .trim()
      .isLength({ max: 5000 })
      .withMessage('Description cannot exceed 5000 characters'),
    body('category')
      .optional()
      .isIn([
        'music',
        'sports',
        'arts',
        'food',
        'technology',
        'business',
        'social',
        'outdoor',
        'other',
      ])
      .withMessage('Invalid category'),
    body('city')
      .trim()
      .notEmpty()
      .withMessage('City is required')
      .isLength({ max: 100 })
      .withMessage('City cannot exceed 100 characters'),
    body('address')
      .optional()
      .trim()
      .isLength({ max: 500 })
      .withMessage('Address cannot exceed 500 characters'),
    body('latitude')
      .optional()
      .isFloat({ min: -90, max: 90 })
      .withMessage('Latitude must be between -90 and 90'),
    body('longitude')
      .optional()
      .isFloat({ min: -180, max: 180 })
      .withMessage('Longitude must be between -180 and 180'),
    body('startTime')
      .notEmpty()
      .withMessage('Start time is required')
      .isISO8601()
      .withMessage('Invalid start time format'),
    body('endTime')
      .optional()
      .isISO8601()
      .withMessage('Invalid end time format'),
    body('maxAttendees')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Max attendees must be a positive integer'),
  ],
  asyncWrapper(eventsController.createEvent)
);

/**
 * @desc    Update event
 * @route   PUT /api/events/:id
 * @access  Private (Owner only)
 */
router.put(
  '/:id',
  auth,
  [
    body('title')
      .optional()
      .trim()
      .notEmpty()
      .withMessage('Title cannot be empty')
      .isLength({ max: 200 })
      .withMessage('Title cannot exceed 200 characters'),
    body('description')
      .optional()
      .trim(),
    body('category')
      .optional()
      .isIn([
        'music',
        'sports',
        'arts',
        'food',
        'technology',
        'business',
        'social',
        'outdoor',
        'other',
      ])
      .withMessage('Invalid category'),
    body('city')
      .optional()
      .trim()
      .isLength({ max: 100 })
      .withMessage('City cannot exceed 100 characters'),
    body('address')
      .optional()
      .trim(),
    body('latitude')
      .optional()
      .isFloat({ min: -90, max: 90 })
      .withMessage('Latitude must be between -90 and 90'),
    body('longitude')
      .optional()
      .isFloat({ min: -180, max: 180 })
      .withMessage('Longitude must be between -180 and 180'),
    body('startTime')
      .optional()
      .isISO8601()
      .withMessage('Invalid start time format'),
    body('endTime')
      .optional()
      .isISO8601()
      .withMessage('Invalid end time format'),
    body('maxAttendees')
      .optional()
      .isInt({ min: 1 })
      .withMessage('Max attendees must be a positive integer'),
    body('isPublished')
      .optional()
      .isBoolean()
      .withMessage('isPublished must be a boolean'),
  ],
  asyncWrapper(eventsController.updateEvent)
);

/**
 * @desc    Delete event
 * @route   DELETE /api/events/:id
 * @access  Private (Owner only)
 */
router.delete('/:id', auth, asyncWrapper(eventsController.deleteEvent));

/**
 * @desc    Register for an event
 * @route   POST /api/events/:id/register
 * @access  Private
 */
router.post('/:id/register', auth, asyncWrapper(eventsController.registerForEvent));

/**
 * @desc    Cancel registration for an event
 * @route   POST /api/events/:id/unregister
 * @access  Private
 */
router.post('/:id/unregister', auth, asyncWrapper(eventsController.unregisterFromEvent));

/**
 * @desc    Get events user has registered for
 * @route   GET /api/events/registered
 * @access  Private
 */
router.get('/registered', auth, asyncWrapper(eventsController.getRegisteredEvents));

module.exports = router;
