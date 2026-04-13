const axios = require('axios');
const Event = require('../models/Event');

const EXTERNAL_SOURCES = {
  eventbrite: {
    name: 'Eventbrite',
    apiUrl: 'https://www.eventbriteapi.com/v3',
    rateLimit: 1000,
  },
};

const SOURCE_WEIGHTS = {
  eventbrite: 0.3,
  eventforge: 0.5,
};

function normalizeEventbriteEvent(event, city) {
  const start = event.start.local ? new Date(event.start.local) : new Date();
  const end = event.end?.local ? new Date(event.end.local) : null;

  return {
    title: event.name?.text || event.name?.html || 'Untitled Event',
    description: event.description?.text || event.description?.html || '',
    category: mapCategory(event.category?.taxonomy || 'other'),
    city: city || event.venue?.city || 'Unknown',
    address: event.venue?.address?.localized_address_display || '',
    location: {
      type: 'Point',
      name: event.venue?.name,
      coordinates: event.venue?.longitude && event.venue?.latitude
        ? [event.venue.longitude, event.venue.latitude]
        : [0, 0],
    },
    startTime: start,
    endTime: end,
    coverImageUrl: event.logo?.url || null,
    isExternal: true,
    source: 'eventbrite',
    externalId: event.id,
    popularityScore: Math.min(100, Math.floor(event.capacity / 10) || 50),
    attendanceEstimate: event.capacity || null,
  };
}

function mapCategory(category) {
  const categoryMap = {
    music: 'music',
    'live music': 'music',
    concert: 'music',
    sports: 'sports',
    'sports event': 'sports',
    arts: 'arts',
    'art exhibition': 'arts',
    theater: 'arts',
    food: 'food',
    'food & drink': 'food',
    'food festival': 'food',
    technology: 'technology',
    tech: 'technology',
    conference: 'technology',
    business: 'business',
    networking: 'business',
    social: 'social',
    'social event': 'social',
    community: 'social',
    outdoor: 'outdoor',
    'outdoor event': 'outdoor',
    festival: 'outdoor',
  };

  const lower = category?.toLowerCase() || '';
  return categoryMap[lower] || 'other';
}

async function fetchEventbriteEvents(city, limit = 50) {
  const token = process.env.EVENTBRITE_API_TOKEN;
  if (!token) {
    console.warn('Eventbrite API token not configured');
    return [];
  }

  try {
    const response = await axios.get(
      `${EXTERNAL_SOURCES.eventbrite.apiUrl}/events/search/`,
      {
        params: {
          q: city,
          sort: 'date',
          expand: 'venue',
          page_size: limit,
        },
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );

    return (response.data.events || []).map(e => normalizeEventbriteEvent(e, city));
  } catch (error) {
    console.error('Error fetching Eventbrite events:', error.message);
    return [];
  }
}

async function syncExternalEvents(city = 'Vancouver', limit = 50) {
  console.log(`Syncing external events for ${city}...`);

  const allEvents = [];

  const eventbriteEvents = await fetchEventbriteEvents(city, limit);
  allEvents.push(...eventbriteEvents);

  console.log(`Fetched ${allEvents.length} external events`);

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
  fetchEventbriteEvents,
  syncExternalEvents,
  getExternalEvents,
  getHiddenGemEvents,
  getUndergroundEvents,
  calculateHiddenScore,
  SOURCE_WEIGHTS,
};