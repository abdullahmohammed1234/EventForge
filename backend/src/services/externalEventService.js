const axios = require('axios');
const Event = require('../models/Event');

const EXTERNAL_SOURCES = {
  discord: {
    name: 'Discord',
    apiUrl: 'https://discord.com/api',
    rateLimit: 100,
  },
};

const SOURCE_WEIGHTS = {
  discord: 0.3,
  eventforge: 0.5,
};

async function syncExternalEvents(city = 'Vancouver', limit = 50) {
  console.log(`Syncing external events for ${city}...`);

  const allEvents = [];

  const savedEvents = [];
  for (const eventData of allEvents) {
    try {
      const existingEvent = await Event.findOne({
        source: eventData.source,
        externalId: eventData.externalId,
      });

      if (!existingEvent) {
        const newEvent = new Event({
          ...eventData,
          createdBy: null,
          isPublished: true,
        });
        await newEvent.save();
        savedEvents.push(newEvent);
      }
    } catch (error) {
      console.error('Error saving external event:', error.message);
    }
  }

  console.log(`Fetched ${allEvents.length} external events`);
  console.log(`Saved ${savedEvents.length} new external events`);
  return savedEvents;
}

async function getExternalEvents(options = {}) {
  const {
    source,
    city,
    page = 1,
    limit = 20,
    hiddenScoreMin,
    isUnderground,
  } = options;

  const filter = {
    isExternal: true,
    isPublished: true,
    isCancelled: false,
  };

  if (source) {
    filter.source = source;
  }

  if (city) {
    filter.city = { $regex: city, $options: 'i' };
  }

  if (hiddenScoreMin !== undefined) {
    filter.hiddenScore = { $gte: hiddenScoreMin };
  }

  if (isUnderground) {
    filter.source = { $in: ['reddit', 'discord', 'telegram'] };
  }

  const events = await Event.find(filter)
    .sort({ hiddenScore: -1, startTime: 1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .populate('createdBy', 'displayName email avatarUrl city');

  const total = await Event.countDocuments(filter);

  return { events, total };
}

async function getHiddenGemEvents(options = {}) {
  const {
    city,
    page = 1,
    limit = 20,
    maxAttendees,
    isFree,
    category,
  } = options;

  const filter = {
    isExternal: true,
    isPublished: true,
    isCancelled: false,
    hiddenScore: { $gte: 60 },
  };

  if (city) {
    filter.city = { $regex: city, $options: 'i' };
  }

  if (maxAttendees) {
    filter.$or = [
      { attendanceEstimate: { $lte: maxAttendees } },
      { maxAttendees: { $lte: maxAttendees } },
    ];
  }

  if (isFree !== undefined) {
    filter.isFree = isFree;
  }

  if (category) {
    filter.category = category;
  }

  const events = await Event.find(filter)
    .sort({ hiddenScore: -1, startTime: 1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .populate('createdBy', 'displayName email avatarUrl city');

  const total = await Event.countDocuments(filter);

  return { events, total };
}

async function getUndergroundEvents(options = {}) {
  const {
    city,
    page = 1,
    limit = 20,
  } = options;

  const filter = {
    isExternal: true,
    isPublished: true,
    isCancelled: false,
    source: { $in: ['reddit', 'discord', 'telegram'] },
  };

  if (city) {
    filter.city = { $regex: city, $options: 'i' };
  }

  const events = await Event.find(filter)
    .sort({ hiddenScore: -1, startTime: 1 })
    .skip((page - 1) * limit)
    .limit(limit)
    .populate('createdBy', 'displayName email avatarUrl city');

  const total = await Event.countDocuments(filter);

  return { events, total };
}

function calculateHiddenScore(event) {
  let score = 0;
  let weight = 0;

  const attendanceWeight = 0.4;
  const sourceWeight = 0.3;
  const rarityWeight = 0.3;

  const attendance = event.attendanceEstimate || event.currentAttendees || 0;
  const normalizedAttendance = attendance > 100 ? 100 : attendance;
  score += (1 - normalizedAttendance / 100) * attendanceWeight * 100;
  weight += attendanceWeight;

  const sourceWeightValue = SOURCE_WEIGHTS[event.source] || 0.5;
  score += sourceWeightValue * sourceWeight * 100;
  weight += sourceWeight;

  score += 50 * rarityWeight;
  weight += rarityWeight;

  return Math.round(score / weight);
}

module.exports = {
  syncExternalEvents,
  getExternalEvents,
  getHiddenGemEvents,
  getUndergroundEvents,
  calculateHiddenScore,
  SOURCE_WEIGHTS,
};