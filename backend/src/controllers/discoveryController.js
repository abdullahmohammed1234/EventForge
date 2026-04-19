const Event = require('../models/Event');
const asyncWrapper = require('../utils/asyncWrapper');
const externalEventService = require('../services/externalEventService');
const rankingService = require('../services/rankingService');
const hiddenSourcesService = require('../services/hiddenSourcesService');

const getHiddenGems = asyncWrapper(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const city = req.query.city;
  const category = req.query.category;
  const maxAttendees = req.query.maxAttendees ? parseInt(req.query.maxAttendees) : null;
  const isFree = req.query.isFree === 'true' ? true : req.query.isFree === 'false' ? false : undefined;

  const { events, total } = await externalEventService.getHiddenGemEvents({
    city,
    category,
    page,
    limit,
    maxAttendees,
    isFree,
  });

  res.json({
    success: true,
    data: {
      events,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    },
  });
});

const getUnderground = asyncWrapper(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const city = req.query.city;

  const { events, total } = await externalEventService.getUndergroundEvents({
    city,
    page,
    limit,
  });

  res.json({
    success: true,
    data: {
      events,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    },
  });
});

const getExternalEvents = asyncWrapper(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const source = req.query.source;
  const city = req.query.city;
  const hiddenScoreMin = req.query.hiddenScoreMin ? parseInt(req.query.hiddenScoreMin) : undefined;
  const isUnderground = req.query.isUnderground === 'true';

  const { events, total } = await externalEventService.getExternalEvents({
    source,
    city,
    page,
    limit,
    hiddenScoreMin,
    isUnderground,
  });

  res.json({
    success: true,
    data: {
      events,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    },
  });
});

const syncExternalSources = asyncWrapper(async (req, res, next) => {
  const city = req.query.city || 'Vancouver';
  const limit = parseInt(req.query.limit) || 50;

  const savedEvents = await externalEventService.syncExternalEvents(city, limit);

  res.json({
    success: true,
    message: `Synced ${savedEvents.length} external events`,
    data: { savedCount: savedEvents.length },
  });
});

const ingestHiddenSources = asyncWrapper(async (req, res, next) => {
  const savedEvents = await hiddenSourcesService.runHiddenSourcesIngestion();

  res.json({
    success: true,
    message: `Ingested ${savedEvents.length} hidden source events`,
    data: { savedCount: savedEvents.length },
  });
});

const refreshHiddenScores = asyncWrapper(async (req, res, next) => {
  const updated = await rankingService.recalculateAllHiddenScores();

  res.json({
    success: true,
    message: `Recalculated hidden scores for ${updated} events`,
    data: { updatedCount: updated },
  });
});

const getDiscoveryStats = asyncWrapper(async (req, res, next) => {
  const stats = await rankingService.getEventStats();

  res.json({
    success: true,
    data: stats,
  });
});

const getDiscoverFeed = asyncWrapper(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const city = req.query.city;
  const category = req.query.category;
  const feedType = req.query.feedType || 'all';

  const filter = {
    isPublished: true,
    isCancelled: false,
  };

  if (city) {
    filter.city = { $regex: city, $options: 'i' };
  }

  if (category) {
    filter.category = category;
  }

  switch (feedType) {
    case 'hidden_gems':
      filter.hiddenScore = { $gte: 60 };
      break;
    case 'underground':
      filter.source = { $in: ['reddit', 'discord', 'telegram'] };
      break;
    case 'external':
      filter.isExternal = true;
      break;
    case 'local':
      filter.$or = [
        { source: 'eventforge' },
        { source: { $exists: false } },
        { source: null },
      ];
      break;
    default:
      break;
  }

  const [events, total] = await Promise.all([
    Event.find(filter)
      .sort({ startTime: 1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('createdBy', 'displayName email avatarUrl city'),
    Event.countDocuments(filter),
  ]);

  res.json({
    success: true,
    data: {
      events,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    },
  });
});

module.exports = {
  getHiddenGems,
  getUnderground,
  getExternalEvents,
  syncExternalSources,
  ingestHiddenSources,
  refreshHiddenScores,
  getDiscoveryStats,
  getDiscoverFeed,
};