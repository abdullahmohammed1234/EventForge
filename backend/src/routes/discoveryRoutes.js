const express = require('express');
const { query } = require('express-validator');
const discoveryController = require('../controllers/discoveryController');
const { auth, optionalAuth } = require('../middleware/auth');
const asyncWrapper = require('../utils/asyncWrapper');

const router = express.Router();

router.get(
  '/feed',
  optionalAuth,
  [
    query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
    query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('feedType').optional().isIn(['all', 'hidden_gems', 'underground', 'external', 'local']).withMessage('Invalid feed type'),
    query('city').optional().trim().isLength({ max: 100 }),
    query('category').optional().trim().isLength({ max: 50 }),
  ],
  asyncWrapper(discoveryController.getDiscoverFeed)
);

router.get(
  '/hidden-gems',
  optionalAuth,
  [
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('city').optional().trim(),
    query('category').optional().trim(),
    query('maxAttendees').optional().isInt({ min: 1 }),
    query('isFree').optional().isBoolean(),
  ],
  asyncWrapper(discoveryController.getHiddenGems)
);

router.get(
  '/underground',
  optionalAuth,
  [
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('city').optional().trim(),
  ],
  asyncWrapper(discoveryController.getUnderground)
);

router.get(
  '/external',
  optionalAuth,
  [
    query('page').optional().isInt({ min: 1 }),
    query('limit').optional().isInt({ min: 1, max: 100 }),
    query('source').optional().isIn(['discord', 'telegram']),
    query('city').optional().trim(),
    query('hiddenScoreMin').optional().isInt({ min: 0, max: 100 }),
    query('isUnderground').optional().isBoolean(),
  ],
  asyncWrapper(discoveryController.getExternalEvents)
);

router.post(
  '/sync',
  auth,
  [
    query('city').optional().trim().isLength({ max: 100 }),
    query('limit').optional().isInt({ min: 1, max: 200 }),
  ],
  asyncWrapper(discoveryController.syncExternalSources)
);

router.post(
  '/ingest-hidden',
  auth,
  asyncWrapper(discoveryController.ingestHiddenSources)
);

router.post(
  '/refresh-scores',
  auth,
  asyncWrapper(discoveryController.refreshHiddenScores)
);

router.get(
  '/stats',
  optionalAuth,
  asyncWrapper(discoveryController.getDiscoveryStats)
);

module.exports = router;