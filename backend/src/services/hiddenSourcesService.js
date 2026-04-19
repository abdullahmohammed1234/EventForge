const axios = require('axios');
const Event = require('../models/Event');

const EVENT_KEYWORDS = [
  'meetup',
  'tonight',
  'free event',
  'going',
  'join us',
  'everyone welcome',
  'come hang out',
  'hang out',
  'party',
  'gathering',
  'workshop',
  'class',
  'club meeting',
  'game night',
  'open mic',
  'pop-up',
  'event',
];

const REDDIT_SUBREDDITS = [
  'vancouver',
  'vents',
  'AskVancouver',
  'VanRavePass',
  'VanMuso',
  'meetup',
  'Seattle',
  'events',
];

async function fetchRedditPosts(subreddit, limit = 100) {
  const clientId = process.env.REDDIT_CLIENT_ID;
  const clientSecret = process.env.REDDIT_CLIENT_SECRET;
  const password = process.env.REDDIT_PASSWORD;
  const username = process.env.REDDIT_USERNAME;

  if (!clientId || !clientSecret) {
    console.warn('Reddit API credentials not configured');
    return [];
  }

  try {
    let accessToken;
    if (username && password) {
      const authResponse = await axios.post(
        'https://www.reddit.com/api/v1/access_token',
        new URLSearchParams({
          grant_type: 'password',
          username,
          password,
        }),
        {
          auth: { username: clientId, password: clientSecret },
          headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        }
      );
      accessToken = authResponse.data.access_token;
    }

    const response = await axios.get(
      `https://oauth.reddit.com/r/${subreddit}/hot.json`,
      {
        params: { limit, t: 'week' },
        headers: accessToken
          ? { Authorization: `Bearer ${accessToken}` }
          : {},
      }
    );

    return (response.data.data?.children || []).map(child => child.data);
  } catch (error) {
    console.error(`Error fetching Reddit posts from r/${subreddit}:`, error.message);
    return [];
  }
}

function isEventLikePost(post) {
  const title = post.title?.toLowerCase() || '';
  const selftext = post.selftext?.toLowerCase() || '';

  const text = `${title} ${selftext}`;
  const keywordMatches = EVENT_KEYWORDS.filter(keyword => text.includes(keyword.toLowerCase()));
  return keywordMatches.length >= 2;
}

function parseRedditPostToEvent(post, subreddit) {
  const title = post.title || 'Untitled Event';

  const titleLower = title.toLowerCase();
  let category = 'other';
  if (titleLower.includes('music') || titleLower.includes('concert') || titleLower.includes('band')) {
    category = 'music';
  } else if (titleLower.includes('food') || titleLower.includes('eat') || titleLower.includes('dinner')) {
    category = 'food';
  } else if (titleLower.includes('sport') || titleLower.includes('game') || titleLower.includes('play')) {
    category = 'sports';
  } else if (titleLower.includes('art') || titleLower.includes('paint') || titleLower.includes('design')) {
    category = 'arts';
  } else if (titleLower.includes('tech') || titleLower.includes('code') || titleLower.includes('dev')) {
    category = 'technology';
  } else if (titleLower.includes('business') || titleLower.includes('network')) {
    category = 'business';
  } else if (titleLower.includes('outdoor') || titleLower.includes('hike') || titleLower.includes('park')) {
    category = 'outdoor';
  }

  let extractedTime = null;
  const timePatterns = [
    /(\w+day)\s+at\s+(\d{1,2}:\d{2}\s*(?:am|pm)?)/i,
    /tonight\s+at\s+(\d{1,2}:\d{2}\s*(?:am|pm)?)/i,
    /(\d{1,2}\/\d{1,2})\s+at\s+(\d{1,2}:\d{2})/i,
    /this\s+(\w+day)/i,
  ];

  for (const pattern of timePatterns) {
    const match = title.match(pattern);
    if (match) {
      try {
        extractedTime = parseTimeString(match[0]);
        if (extractedTime) break;
      } catch (e) {}
    }
  }

  if (!extractedTime) {
    const now = new Date();
    extractedTime = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  }

  const description = post.selftext || post.permalink || '';
  const score = post.score || 0;
  const numComments = post.num_comments || 0;

  return {
    title: title.substring(0, 200),
    description: description.substring(0, 5000),
    category,
    city: subreddit === 'vancouver' || subreddit === 'AskVancouver' ? 'Vancouver' : 'Unknown',
    address: '',
    location: { type: 'Point', name: null, coordinates: [0, 0] },
    startTime: extractedTime,
    endTime: null,
    coverImageUrl: post.thumbnail || null,
    isExternal: true,
    source: 'reddit',
    externalId: `${subreddit}_${post.id}`,
    popularityScore: Math.min(100, Math.floor(score / 10)),
    attendanceEstimate: Math.min(50, Math.max(5, Math.floor(numComments / 2))),
    hiddenScore: Math.min(100, Math.floor((score + numComments) / 5)),
  };
}

function parseTimeString(timeStr) {
  const now = new Date();

  const tonightMatch = timeStr.match(/tonight\s+at\s+(\d{1,2}:\d{2}\s*(?:am|pm)?)/i);
  if (tonightMatch) {
    const time = parseTime(tonightMatch[1]);
    const result = new Date(now);
    result.setHours(time.hours, time.minutes, 0, 0);
    if (result < now) {
      result.setDate(result.getDate() + 1);
    }
    return result;
  }

  const dayMatch = timeStr.match(/(\w+day)\s+at\s+(\d{1,2}:\d{2}\s*(?:am|pm)?)/i);
  if (dayMatch) {
    const time = parseTime(dayMatch[2]);
    const result = getNextDayOfWeek(dayMatch[1]);
    result.setHours(time.hours, time.minutes, 0, 0);
    return result;
  }

  const dateMatch = timeStr.match(/(\d{1,2}\/\d{1,2})\s+at\s+(\d{1,2}:\d{2})/i);
  if (dateMatch) {
    const [month, day] = dateMatch[1].split('/').map(Number);
    const time = parseTime(dateMatch[2]);
    const result = new Date(now.getFullYear(), month - 1, day, time.hours, time.minutes);
    return result;
  }

  return new Date(now.getTime() + 24 * 60 * 60 * 1000);
}

function parseTime(timeStr) {
  const match = timeStr.match(/(\d{1,2}):(\d{2})\s*(am|pm)?/i);
  if (!match) return { hours: 18, minutes: 0 };

  let hours = parseInt(match[1]);
  const minutes = parseInt(match[2]);
  const period = match[3]?.toLowerCase();

  if (period === 'pm' && hours < 12) hours += 12;
  if (period === 'am' && hours === 12) hours = 0;

  return { hours, minutes };
}

function getNextDayOfWeek(dayName) {
  const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
  const targetDay = dayName.toLowerCase();
  const dayIndex = days.indexOf(targetDay);

  if (dayIndex === -1) {
    return new Date(Date.now() + 24 * 60 * 60 * 1000);
  }

  const now = new Date();
  const currentDay = now.getDay();
  let daysToAdd = dayIndex - currentDay;

  if (daysToAdd <= 0) {
    daysToAdd += 7;
  }

  return new Date(now.getTime() + daysToAdd * 24 * 60 * 60 * 1000);
}

async function ingestRedditEvents(subreddits = REDDIT_SUBREDDITS, limit = 50) {
  console.log('Ingesting Reddit events...');

  const allPosts = [];
  for (const subreddit of subreddits) {
    const posts = await fetchRedditPosts(subreddit, limit);
    const eventLikePosts = posts.filter(isEventLikePost);
    allPosts.push(...eventLikePosts);
  }

  console.log(`Found ${allPosts.length} event-like Reddit posts`);

  const savedEvents = [];
  for (const post of allPosts) {
    try {
      const existingEvent = await Event.findOne({
        source: 'reddit',
        externalId: `${post.subreddit}_${post.id}`,
      });

      if (!existingEvent) {
        const subreddit = post.subreddit?.toLowerCase() || 'vancouver';
        const eventData = parseRedditPostToEvent(post, subreddit);
        const newEvent = new Event({
          ...eventData,
          createdBy: null,
          isPublished: true,
        });
        await newEvent.save();
        savedEvents.push(newEvent);
      }
    } catch (error) {
      console.error('Error saving Reddit event:', error.message);
    }
  }

  console.log(`Saved ${savedEvents.length} new Reddit events`);
  return savedEvents;
}

const DISCORD_CONFIG = {
  enabled: false,
  channels: [],
  requiredRole: null,
};

async function setupDiscordBot(config = {}) {
  if (!config.botToken) {
    console.warn('Discord bot token not configured');
    return null;
  }

  DISCORD_CONFIG.enabled = true;
  DISCORD_CONFIG.channels = config.channels || [];
  DISCORD_CONFIG.requiredRole = config.requiredRole;

  console.log('Discord bot configured');
  return DISCORD_CONFIG;
}

function parseDiscordMessageToEvent(message) {
  const content = message.content || '';
  const titleMatch = content.match(/^(.+?)(?:\n|$)/);
  const title = titleMatch ? titleMatch[1].trim() : 'Discord Event';

  if (!isEventLikePost({ title, selftext: content })) {
    return null;
  }

  const titleLower = title.toLowerCase();
  let category = 'other';
  if (titleLower.includes('game')) category = 'sports';
  else if (titleLower.includes('music')) category = 'music';
  else if (titleLower.includes('food')) category = 'food';

  return {
    title: title.substring(0, 200),
    description: content.substring(0, 5000),
    category,
    city: 'Unknown',
    address: '',
    location: { type: 'Point', name: null, coordinates: [0, 0] },
    startTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
    endTime: null,
    coverImageUrl: null,
    isExternal: true,
    source: 'discord',
    externalId: `discord_${message.id}`,
    popularityScore: 30,
    attendanceEstimate: 10,
    hiddenScore: Math.min(100, Math.floor((message.reactions?.length || 0) * 10)),
  };
}

async function parseDiscordChannel(channelId, client) {
  if (!DISCORD_CONFIG.enabled) return [];

  try {
    const messages = await client.channels.cache.get(channelId)?.messages.fetch();
    if (!messages) return [];

    const eventMessages = messages
      .filter(msg => !msg.author.bot)
      .map(parseDiscordMessageToEvent)
      .filter(Boolean);

    return eventMessages;
  } catch (error) {
    console.error(`Error parsing Discord channel ${channelId}:`, error.message);
    return [];
  }
}

const TELEGRAM_CONFIG = {
  enabled: false,
  channels: [],
};

async function setupTelegramListener(config = {}) {
  if (!config.botToken) {
    console.warn('Telegram bot token not configured');
    return null;
  }

  TELEGRAM_CONFIG.enabled = true;
  TELEGRAM_CONFIG.channels = config.channels || [];

  console.log('Telegram listener configured');
  return TELEGRAM_CONFIG;
}

function parseTelegramMessageToEvent(message) {
  const content = message.text || '';
  const titleMatch = content.match(/^(.+?)(?:\n|$)/);
  const title = titleMatch ? titleMatch[1].trim() : 'Telegram Event';

  if (!isEventLikePost({ title, selftext: content })) {
    return null;
  }

  const titleLower = title.toLowerCase();
  let category = 'other';
  if (titleLower.includes('game')) category = 'sports';
  else if (titleLower.includes('music')) category = 'music';
  else if (titleLower.includes('food')) category = 'food';

  return {
    title: title.substring(0, 200),
    description: content.substring(0, 5000),
    category,
    city: 'Unknown',
    address: '',
    location: { type: 'Point', name: null, coordinates: [0, 0] },
    startTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
    endTime: null,
    coverImageUrl: null,
    isExternal: true,
    source: 'telegram',
    externalId: `telegram_${message.message_id}`,
    popularityScore: 30,
    attendanceEstimate: 10,
    hiddenScore: 80,
  };
}

async function fetchTelegramUpdates(botToken) {
  if (!botToken) {
    console.warn('Telegram bot token not configured');
    return [];
  }

  try {
    const response = await axios.get(
      `https://api.telegram.org/bot${botToken}/getUpdates`
    );

    return response.data.result || [];
  } catch (error) {
    console.error('Error fetching Telegram updates:', error.message);
    return [];
  }
}

async function ingestTelegramEvents(channels = TELEGRAM_CONFIG.channels) {
  if (!TELEGRAM_CONFIG.enabled) {
    console.log('Telegram listener not enabled');
    return [];
  }

  console.log('Ingesting Telegram events...');

  const savedEvents = [];
  for (const channelId of channels) {
    try {
      const updates = await fetchTelegramUpdates(process.env.TELEGRAM_BOT_TOKEN);
      const channelUpdates = updates.filter(
        u => u.message?.chat?.id?.toString() === channelId
      );

      for (const update of channelUpdates) {
        const eventData = parseTelegramMessageToEvent(update.message);
        if (!eventData) continue;

        const existingEvent = await Event.findOne({
          source: 'telegram',
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
      }
    } catch (error) {
      console.error(`Error ingesting Telegram channel ${channelId}:`, error.message);
    }
  }

  console.log(`Saved ${savedEvents.length} new Telegram events`);
  return savedEvents;
}

async function runHiddenSourcesIngestion() {
  console.log('Starting hidden sources ingestion...');

  const savedEvents = [];

  // Discord ingestion (if configured)
  const discordEnabled = process.env.DISCORD_BOT_TOKEN;
  if (discordEnabled) {
    console.log('Discord ingestion enabled');
    // Note: Discord requires the bot to be running and invited to servers
  }

  // Telegram ingestion (if configured)
  const telegramEnabled = process.env.TELEGRAM_BOT_TOKEN;
  if (telegramEnabled) {
    console.log('Telegram ingestion enabled');
    // Telegram events are ingested when their bot receives messages
  }

  console.log('Hidden sources ingestion complete');
  return savedEvents;
}

module.exports = {
  ingestRedditEvents,
  setupDiscordBot,
  parseDiscordChannel,
  setupTelegramListener,
  ingestTelegramEvents,
  runHiddenSourcesIngestion,
  EVENT_KEYWORDS,
  REDDIT_SUBREDDITS,
};