const Event = require('../models/Event');
const { calculateHiddenScore } = require('./externalEventService');

const SCORING_WEIGHTS = {
  attendanceLow: 0.4,
  communitySource: 0.3,
  rarityScore: 0.3,
};

const SOURCE_SCORES = {
  discord: 0.9,
  telegram: 0.85,
  eventforge: 0.5,
};

const ATTENDANCE_THRESHOLDS = {
  tiny: 5,
  small: 20,
  medium: 50,
  large: 100,
};

async function calculateEventHiddenScore(event) {
  let score = 0;

  const attendanceWeight = SCORING_WEIGHTS.attendanceLow;
  const attendance = event.attendanceEstimate || event.currentAttendees || 0;
  let attendanceScore;
  if (attendance <= ATTENDANCE_THRESHOLDS.tiny) {
    attendanceScore = 100;
  } else if (attendance <= ATTENDANCE_THRESHOLDS.small) {
    attendanceScore = 80;
  } else if (attendance <= ATTENDANCE_THRESHOLDS.medium) {
    attendanceScore = 60;
  } else if (attendance <= ATTENDANCE_THRESHOLDS.large) {
    attendanceScore = 40;
  } else {
    attendanceScore = 20;
  }
  score += attendanceScore * attendanceWeight;

  const sourceWeight = SCORING_WEIGHTS.communitySource;
  const sourceScore = SOURCE_SCORES[event.source] || 0.5;
  score += sourceScore * sourceWeight * 100;

  const rarityWeight = SCORING_WEIGHTS.rarityScore;
  const categoryCount = await Event.countDocuments({
    category: event.category,
    isPublished: true,
    isExternal: true,
  });
  const totalCount = await Event.countDocuments({
    isPublished: true,
    isExternal: true,
  });
  const rarityRatio = totalCount > 0 ? 1 - (categoryCount / totalCount) : 0.5;
  score += rarityRatio * rarityWeight * 100;

  return Math.round(Math.min(100, Math.max(0, score)));
}

async function recalculateAllHiddenScores() {
  console.log('Recalculating hidden scores for all external events...');

  const events = await Event.find({
    isExternal: true,
    isPublished: true,
  });

  let updated = 0;
  for (const event of events) {
    const newScore = await calculateEventHiddenScore(event);
    if (event.hiddenScore !== newScore) {
      event.hiddenScore = newScore;
      await event.save();
      updated++;
    }
  }

  console.log(`Updated ${updated} event hidden scores`);
  return updated;
}

async function getEventsByHiddenScore(options = {}) {
  const {
    minScore = 60,
    city,
    category,
    page = 1,
    limit = 20,
  } = options;

  const filter = {
    isPublished: true,
    isCancelled: false,
    hiddenScore: { $gte: minScore },
  };

  if (city) {
    filter.city = { $regex: city, $options: 'i' };
  }

  if (category) {
    filter.category = category;
  }

  const events = await Event.find(filter)
    .sort({ hiddenScore: -1, startTime: 1 })
    .skip((page - 1) * limit)
    .limit(limit);

  const total = await Event.countDocuments(filter);

  return { events, total };
}

function isHiddenGem(event) {
  return event.hiddenScore >= 60;
}

function isUnderground(event) {
  return ['reddit', 'discord', 'telegram'].includes(event.source);
}

function getPopularityTier(event) {
  const attendance = event.attendanceEstimate || event.currentAttendees || 0;

  if (attendance <= ATTENDANCE_THRESHOLDS.tiny) return 'tiny';
  if (attendance <= ATTENDANCE_THRESHOLDS.small) return 'small';
  if (attendance <= ATTENDANCE_THRESHOLDS.medium) return 'medium';
  return 'large';
}

async function getEventStats() {
  const totalExternal = await Event.countDocuments({
    isExternal: true,
    isPublished: true,
  });

  const hiddenGems = await Event.countDocuments({
    isExternal: true,
    isPublished: true,
    hiddenScore: { $gte: 60 },
  });

  const underground = await Event.countDocuments({
    isExternal: true,
    isPublished: true,
    source: { $in: ['reddit', 'discord', 'telegram'] },
  });

  const bySource = await Event.aggregate([
    { $match: { isExternal: true, isPublished: true } },
    { $group: { _id: '$source', count: { $sum: 1 } } },
  ]);

  return {
    totalExternal,
    hiddenGems,
    underground,
    bySource: bySource.reduce((acc, item) => {
      acc[item._id] = item.count;
      return acc;
    }, {}),
  };
}

module.exports = {
  calculateEventHiddenScore,
  recalculateAllHiddenScores,
  getEventsByHiddenScore,
  isHiddenGem,
  isUnderground,
  getPopularityTier,
  getEventStats,
  SCORING_WEIGHTS,
  SOURCE_SCORES,
  ATTENDANCE_THRESHOLDS,
};