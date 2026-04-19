const { validationResult } = require('express-validator');
const mongoose = require('mongoose');
const Event = require('../models/Event');
const asyncWrapper = require('../utils/asyncWrapper');
const { APIError } = require('../middleware/errorHandler');
const { handleUpload } = require('../utils/upload');

/**
 * @desc    Get all events (with pagination and filters)
 * @route   GET /api/events
 * @access  Public
 */
const getEvents = asyncWrapper(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;

  // Build filter object
  const filter = {
    isPublished: true,
    isCancelled: false,
  };

  // Search by title, description, or city
  if (req.query.search) {
    filter.$or = [
      { title: { $regex: req.query.search, $options: 'i' } },
      { description: { $regex: req.query.search, $options: 'i' } },
      { city: { $regex: req.query.search, $options: 'i' } },
    ];
  }

  // Filter by city
  if (req.query.city) {
    filter.city = { $regex: req.query.city, $options: 'i' };
  }

  // Filter by category
  if (req.query.category) {
    filter.category = req.query.category;
  }

  // Filter by upcoming only
  if (req.query.upcoming === 'true') {
    filter.startTime = { $gte: new Date() };
  }

  // Execute query with pagination
  const [events, total] = await Promise.all([
    Event.find(filter)
      .sort({ startTime: 1 })
      .skip(skip)
      .limit(limit)
      .populate('createdBy', 'displayName email avatarUrl city'),
    Event.countDocuments(filter),
  ]);

  // If user is authenticated, check which events are saved
  let savedEventIds = [];
  if (req.userId) {
    const User = require('../models/User');
    const user = await User.findById(req.userId);
    savedEventIds = user.savedEvents.map(id => id.toString());
  }

  // Add isUserSaved to each event
  const eventsWithSavedStatus = events.map(event => {
    const eventObj = event.toObject();
    eventObj.isUserSaved = savedEventIds.includes(event._id.toString());
    return eventObj;
  });

  res.json({
    success: true,
    data: {
      events: eventsWithSavedStatus,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    },
  });
});

/**
 * @desc    Get single event by ID
 * @route   GET /api/events/:id
 * @access  Public
 */
const getEvent = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id).populate(
    'createdBy',
    'displayName email avatarUrl city'
  );

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  // Check if user is registered (if authenticated)
  let isUserRegistered = false;
  let isUserOrganizer = false;
  let isUserSaved = false;

  if (req.userId) {
    const User = require('../models/User');
    const userObjectId = new mongoose.Types.ObjectId(req.userId);

    // Check if user is the organizer
    if (event.createdBy && event.createdBy._id.toString() === userObjectId.toString()) {
      isUserOrganizer = true;
    }

    // Check if user is registered
    const registration = event.attendees.find(
      (a) => a.user.toString() === userObjectId.toString() && a.status === 'registered'
    );
    isUserRegistered = !!registration;

    // Check if user has saved this event
    const user = await User.findById(req.userId);
    // Convert both to strings for reliable comparison
    const savedEventIdStrings = user.savedEvents.map(id => id.toString());
    isUserSaved = savedEventIdStrings.includes(event._id.toString());
  }

  // Get registered attendees count
  const registeredAttendees = event.attendees.filter(
    (a) => a.status === 'registered'
  );
  const attendeeCount = registeredAttendees.length;

  // Populate attendee details
  const attendeeIds = registeredAttendees.map((a) => a.user);
  const populatedAttendees = await mongoose.model('User').find(
    { _id: { $in: attendeeIds } }
  ).select('displayName avatarUrl');

  // Convert to plain object and add computed fields
  const eventObj = event.toObject();
  eventObj.isUserRegistered = isUserRegistered;
  eventObj.isUserOrganizer = isUserOrganizer;
  eventObj.isUserSaved = isUserSaved;
  eventObj.attendeeCount = attendeeCount;
  eventObj.attendees = populatedAttendees.map((u) => ({
    id: u._id,
    user: {
      id: u._id,
      displayName: u.displayName,
      avatarUrl: u.avatarUrl,
    },
  }));

  res.json({
    success: true,
    data: { event: eventObj },
  });
});

/**
 * @desc    Create new event
 * @route   POST /api/events
 * @access  Private
 */
const createEvent = asyncWrapper(async (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array(),
    });
  }

  const {
    title,
    description,
    category,
    city,
    address,
    latitude,
    longitude,
    startTime,
    endTime,
    maxAttendees,
    coverImageUrl,
    tags,
    locationName,
    organizerType,
    contact,
    highlights,
    isFree,
    price,
  } = req.body;

  // Validate dates
  const start = new Date(startTime);
  if (isNaN(start.getTime())) {
    return next(new APIError('Invalid start time format', 400));
  }

  if (start <= new Date()) {
    return next(new APIError('Start time must be in the future', 400));
  }

  // Build location object
  const location = {
    type: 'Point',
    name: locationName,
    coordinates: [longitude || 0, latitude || 0],
  };

  const event = new Event({
    title,
    description,
    category: category || 'other',
    coverImageUrl,
    tags: tags || [],
    city,
    address,
    location,
    startTime: start,
    endTime: endTime ? new Date(endTime) : null,
    maxAttendees: maxAttendees || null,
    createdBy: req.userId,
    organizer: organizerType,
    contact: contact || {},
    highlights: highlights || [],
    isFree: isFree !== undefined ? isFree : true,
    price: price || 0,
  });

  await event.save();

  // Populate creator info for response
  await event.populate('createdBy', 'displayName email avatarUrl city');

  res.status(201).json({
    success: true,
    message: 'Event created successfully',
    data: { event },
  });
});

/**
 * @desc    Update event
 * @route   PUT /api/events/:id
 * @access  Private (Owner only)
 */
const updateEvent = asyncWrapper(async (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array(),
    });
  }

  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  // Check ownership
  if (event.createdBy.toString() !== req.userId.toString()) {
    return next(new APIError('Not authorized to update this event', 403));
  }

  const {
    title,
    description,
    category,
    city,
    address,
    latitude,
    longitude,
    startTime,
    endTime,
    maxAttendees,
    isPublished,
  } = req.body;

  // Update fields
  if (title) event.title = title;
  if (description !== undefined) event.description = description;
  if (category) event.category = category;
  if (city) event.city = city;
  if (address !== undefined) event.address = address;
  if (latitude !== undefined || longitude !== undefined) {
    event.location = {
      type: 'Point',
      coordinates: [longitude || event.location.coordinates[0], latitude || event.location.coordinates[1]],
    };
  }
  if (startTime) {
    const start = new Date(startTime);
    if (isNaN(start.getTime())) {
      return next(new APIError('Invalid start time format', 400));
    }
    event.startTime = start;
  }
  if (endTime !== undefined) {
    event.endTime = endTime ? new Date(endTime) : null;
  }
  if (maxAttendees !== undefined) {
    event.maxAttendees = maxAttendees;
    // Ensure currentAttendees doesn't exceed new max
    if (event.currentAttendees > maxAttendees) {
      event.currentAttendees = maxAttendees;
    }
  }
  if (isPublished !== undefined) event.isPublished = isPublished;

  await event.save();
  await event.populate('createdBy', 'displayName email avatarUrl city');

  res.json({
    success: true,
    message: 'Event updated successfully',
    data: { event },
  });
});

/**
 * @desc    Delete event
 * @route   DELETE /api/events/:id
 * @access  Private (Owner only)
 */
const deleteEvent = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  // Check ownership
  if (event.createdBy.toString() !== req.userId.toString()) {
    return next(new APIError('Not authorized to delete this event', 403));
  }

  // Soft delete - mark as cancelled
  event.isCancelled = true;
  await event.save();

  res.json({
    success: true,
    message: 'Event deleted successfully',
  });
});

/**
 * @desc    Get events created by current user
 * @route   GET /api/events/my-events
 * @access  Private
 */
const getMyEvents = asyncWrapper(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;

  const [events, total] = await Promise.all([
    Event.find({ createdBy: req.userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('createdBy', 'displayName email city'),
    Event.countDocuments({ createdBy: req.userId }),
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

/**
 * @desc    Register for an event
 * @route   POST /api/events/:id/register
 * @access  Private
 */
const registerForEvent = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  if (event.isCancelled) {
    return next(new APIError('Event has been cancelled', 400));
  }

  // Convert userId to ObjectId for storage
  const userObjectId = new mongoose.Types.ObjectId(req.userId);

  // Check if user is already registered
  const existingRegistration = event.attendees.find(
    (a) => a.user.toString() === userObjectId.toString() && a.status === 'registered'
  );

  if (existingRegistration) {
    return next(new APIError('You are already registered for this event', 400));
  }

  // Check if event is full
  if (event.maxAttendees && event.currentAttendees >= event.maxAttendees) {
    return next(new APIError('Event is full', 400));
  }

  // Check if user was previously registered and cancelled
  const previousRegistration = event.attendees.find(
    (a) => a.user.toString() === userObjectId.toString() && a.status === 'cancelled'
  );

  if (previousRegistration) {
    // Reactivate registration
    previousRegistration.status = 'registered';
    previousRegistration.registeredAt = new Date();
  } else {
    // Add new attendee - store as ObjectId
    event.attendees.push({
      user: userObjectId,
      status: 'registered',
    });
  }

  event.currentAttendees += 1;
  await event.save();

  res.status(201).json({
    success: true,
    message: 'Successfully registered for the event',
    data: {
      eventId: event._id,
      registered: true,
    },
  });
});

/**
 * @desc    Cancel registration for an event
 * @route   POST /api/events/:id/unregister
 * @access  Private
 */
const unregisterFromEvent = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  // Convert userId to ObjectId for comparison
  const userObjectId = new mongoose.Types.ObjectId(req.userId);

  // Check if user is registered
  const registrationIndex = event.attendees.findIndex(
    (a) => a.user.toString() === userObjectId.toString() && a.status === 'registered'
  );

  if (registrationIndex === -1) {
    return next(new APIError('You are not registered for this event', 400));
  }

  // Cancel registration
  event.attendees[registrationIndex].status = 'cancelled';
  event.currentAttendees = Math.max(0, event.currentAttendees - 1);
  await event.save();

  res.json({
    success: true,
    message: 'Successfully cancelled registration',
    data: {
      eventId: event._id,
      registered: false,
    },
  });
});

/**
 * @desc    Get events user has registered for
 * @route   GET /api/events/registered
 * @access  Private
 */
const getRegisteredEvents = asyncWrapper(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;

  // Convert userId to ObjectId for proper MongoDB comparison
  const userObjectId = new mongoose.Types.ObjectId(req.userId);

  const [events, total] = await Promise.all([
    Event.find({
      'attendees.user': userObjectId,
      'attendees.status': 'registered',
      isCancelled: false,
    })
      .sort({ startTime: 1 })
      .skip(skip)
      .limit(limit)
      .populate('createdBy', 'displayName email avatarUrl city'),
    Event.countDocuments({
      'attendees.user': userObjectId,
      'attendees.status': 'registered',
      isCancelled: false,
    }),
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

// Save an event
const saveEvent = asyncWrapper(async (req, res, next) => {
  const User = require('../models/User');

  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const user = await User.findById(req.userId);

  // Use a more reliable comparison for ObjectId
  const eventIdStr = event._id.toString();
  const isAlreadySaved = user.savedEvents.some(
    (id) => id.toString() === eventIdStr
  );
  
  if (isAlreadySaved) {
    return next(new APIError('Event is already saved', 400));
  }

  user.savedEvents.push(event._id);
  await user.save();

  res.status(201).json({
    success: true,
    message: 'Event saved successfully',
    data: { eventId: event._id, saved: true },
  });
});

// Unsave an event
const unsaveEvent = asyncWrapper(async (req, res, next) => {
  const User = require('../models/User');

  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const user = await User.findById(req.userId);

  // Use string comparison for reliable ObjectId matching
  const eventIdStr = event._id.toString();
  const isSaved = user.savedEvents.some(
    (id) => id.toString() === eventIdStr
  );
  
  if (!isSaved) {
    return next(new APIError('Event is not saved', 400));
  }

  user.savedEvents = user.savedEvents.filter(
    (id) => id.toString() !== eventIdStr
  );
  await user.save();

  res.json({
    success: true,
    message: 'Event unsaved successfully',
    data: { eventId: event._id, saved: false },
  });
});

// Get saved events
const getSavedEvents = asyncWrapper(async (req, res, next) => {
  const User = require('../models/User');

  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const skip = (page - 1) * limit;

  const user = await User.findById(req.userId);
  const savedEventIds = user.savedEvents;

  const [events, total] = await Promise.all([
    Event.find({ _id: { $in: savedEventIds }, isCancelled: false })
      .sort({ startTime: 1 })
      .skip(skip)
      .limit(limit)
      .populate('createdBy', 'displayName email avatarUrl city'),
    Event.countDocuments({ _id: { $in: savedEventIds }, isCancelled: false }),
  ]);

  // Add isUserSaved: true to each event since they're saved events
  const eventsWithSavedStatus = events.map(event => {
    const eventObj = event.toObject();
    eventObj.isUserSaved = true;
    return eventObj;
  });

  res.json({
    success: true,
    data: {
      events: eventsWithSavedStatus,
      pagination: { page, limit, total, pages: Math.ceil(total / limit) },
    },
  });
});

module.exports = {
  getEvents,
  getEvent,
  createEvent,
  updateEvent,
  deleteEvent,
  getMyEvents,
  registerForEvent,
  unregisterFromEvent,
  getRegisteredEvents,
  saveEvent,
  unsaveEvent,
  getSavedEvents,
};

/**
 * @desc    Upload event cover image
 * @route   POST /api/events/upload-cover
 * @access  Private
 */
uploadEventCover = asyncWrapper(async (req, res, next) => {
  handleUpload(req, res, async (err) => {
    if (err) {
      return next(err);
    }

    if (!req.file) {
      return next(new APIError('No file uploaded', 400));
    }

    // Debug: log what we got from upload
    console.log('Upload result:', {
      path: req.file.path,
      filename: req.file.filename
    });

    // Check if using Cloudinary or local storage
    let imageUrl;
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const isUsingCloudinary = cloudName && 
      req.file.path && 
      req.file.path.includes(cloudName);
    
    if (isUsingCloudinary) {
      // Construct full Cloudinary URL
      // Cloudinary returns path like: dfk66zbjp/image/upload/v1234567890/folder/filename
      // We need: https://res.cloudinary.com/dfk66zbjp/image/upload/v1234567890/folder/filename
      if (req.file.path.startsWith('http')) {
        imageUrl = req.file.path;
      } else if (req.file.path.startsWith('//')) {
        imageUrl = 'https:' + req.file.path;
      } else {
        // It's a path - prepend the full URL
        imageUrl = `https://res.cloudinary.com/${req.file.path}`;
      }
      console.log('Cloudinary URL:', imageUrl);
    } else {
      // Local storage URL
      imageUrl = `/uploads/${req.file.filename}`;
    }

    res.json({
      success: true,
      message: 'Event cover image uploaded successfully',
      data: {
        coverImageUrl: imageUrl,
      },
    });
  });
});

const getEventCalendar = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const formatDate = (date) => {
    if (!date) return '';
    return new Date(date).toISOString().replace(/[-:]/g, '').replace(/\.\d{3}/, '');
  };

  const uid = event._id.toString();
  const dtstamp = formatDate(new Date());
  const dtstart = formatDate(event.startTime);
  const dtend = formatDate(event.endTime);
  
  let ical = `BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//StormForge 2026//Event Planner//EN
CALSCALE:GREGORIAN
METHOD:PUBLISH
BEGIN:VEVENT
UID:${uid}@stormforge2026
DTSTAMP:${dtstamp}
DTSTART:${dtstart}
DTEND:${dtend}
SUMMARY:${event.title}
DESCRIPTION:${(event.description || '').replace(/\n/g, '\\n')}
LOCATION:${event.address || ''}
END:VEVENT
END:VCALENDAR`;

  res.setHeader('Content-Type', 'text/calendar; charset=utf-8');
  res.setHeader('Content-Disposition', `attachment; filename="${event.title.replace(/[^a-z0-9]/gi, '_')}.ics"`);
  res.send(ical);
});

const addTodoItem = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const { title, description, assignedTo } = req.body;

  if (!title || !title.trim()) {
    return next(new APIError('To-do title is required', 400));
  }

  const todoItem = {
    title: title.trim(),
    description: description?.trim(),
    assignedTo: assignedTo || null,
    createdBy: req.userId,
  };

  event.todoItems.push(todoItem);
  await event.save();

  res.status(201).json({
    success: true,
    message: 'To-do item added',
    data: { todoItem: event.todoItems[event.todoItems.length - 1] },
  });
});

const updateTodoItem = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const todoItem = event.todoItems.id(req.params.todoId);

  if (!todoItem) {
    return next(new APIError('To-do item not found', 404));
  }

  const { title, description, assignedTo, isCompleted } = req.body;

  if (title !== undefined) todoItem.title = title.trim();
  if (description !== undefined) todoItem.description = description?.trim();
  if (assignedTo !== undefined) todoItem.assignedTo = assignedTo;
  if (isCompleted !== undefined) {
    todoItem.isCompleted = isCompleted;
    todoItem.completedAt = isCompleted ? new Date() : null;
  }

  await event.save();

  res.json({
    success: true,
    message: 'To-do item updated',
    data: { todoItem },
  });
});

const deleteTodoItem = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const todoItem = event.todoItems.id(req.params.todoId);

  if (!todoItem) {
    return next(new APIError('To-do item not found', 404));
  }

  todoItem.deleteOne();
  await event.save();

  res.json({
    success: true,
    message: 'To-do item deleted',
  });
});

const addPoll = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const { question, options, isMultipleChoice, allowsNewOptions, expiresAt } = req.body;

  if (!question || !question.trim()) {
    return next(new APIError('Poll question is required', 400));
  }

  if (!options || !Array.isArray(options) || options.length < 2) {
    return next(new APIError('At least 2 options are required', 400));
  }

  const pollOptions = options.map(opt => ({
    text: opt.text || opt,
    votes: [],
  }));

  const poll = {
    question: question.trim(),
    options: pollOptions,
    isMultipleChoice: isMultipleChoice || false,
    allowsNewOptions: allowsNewOptions !== false,
    expiresAt: expiresAt ? new Date(expiresAt) : null,
    createdBy: req.userId,
  };

  event.polls.push(poll);
  await event.save();

  res.status(201).json({
    success: true,
    message: 'Poll created',
    data: { poll: event.polls[event.polls.length - 1] },
  });
});

const voteOnPoll = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const poll = event.polls.id(req.params.pollId);

  if (!poll) {
    return next(new APIError('Poll not found', 404));
  }

  if (!poll.isActive) {
    return next(new APIError('Poll is closed', 400));
  }

  if (poll.expiresAt && new Date(poll.expiresAt) < new Date()) {
    poll.isActive = false;
    await event.save();
    return next(new APIError('Poll has expired', 400));
  }

  const { optionIndex, optionText } = req.body;

  if (!poll.isMultipleChoice) {
    poll.options.forEach(opt => {
      opt.votes = opt.votes.filter(v => v.user.toString() !== req.userId.toString());
    });
  }

  if (optionIndex !== undefined && poll.options[optionIndex]) {
    const alreadyVoted = poll.options[optionIndex].votes.some(
      v => v.user.toString() === req.userId.toString()
    );
    if (!alreadyVoted) {
      poll.options[optionIndex].votes.push({ user: req.userId });
    }
  }

  if (optionText && poll.allowsNewOptions) {
    let existingOption = poll.options.find(
      o => o.text.toLowerCase() === optionText.toLowerCase()
    );
    if (!existingOption) {
      poll.options.push({ text: optionText, votes: [{ user: req.userId }] });
    } else {
      const alreadyVoted = existingOption.votes.some(
        v => v.user.toString() === req.userId.toString()
      );
      if (!alreadyVoted) {
        existingOption.votes.push({ user: req.userId });
      }
    }
  }

  await event.save();

  res.json({
    success: true,
    message: 'Vote recorded',
    data: { poll },
  });
});

const closePoll = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const poll = event.polls.id(req.params.pollId);

  if (!poll) {
    return next(new APIError('Poll not found', 404));
  }

  if (event.createdBy.toString() !== req.userId.toString()) {
    return next(new APIError('Only event organizer can close polls', 403));
  }

  poll.isActive = false;
  await event.save();

  res.json({
    success: true,
    message: 'Poll closed',
    data: { poll },
  });
});

const deletePoll = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const poll = event.polls.id(req.params.pollId);

  if (!poll) {
    return next(new APIError('Poll not found', 404));
  }

  if (poll.createdBy.toString() !== req.userId.toString()) {
    return next(new APIError('Only poll creator can delete poll', 403));
  }

  poll.deleteOne();
  await event.save();

  res.json({
    success: true,
    message: 'Poll deleted',
  });
});

const addComment = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const { content } = req.body;

  if (!content || !content.trim()) {
    return next(new APIError('Comment content is required', 400));
  }

  const comment = {
    content: content.trim(),
    createdBy: req.userId,
  };

  event.comments.push(comment);
  await event.save();

  res.status(201).json({
    success: true,
    message: 'Comment added',
    data: { comment: event.comments[event.comments.length - 1] },
  });
});

const deleteComment = asyncWrapper(async (req, res, next) => {
  const event = await Event.findById(req.params.id);

  if (!event) {
    return next(new APIError('Event not found', 404));
  }

  const comment = event.comments.id(req.params.commentId);

  if (!comment) {
    return next(new APIError('Comment not found', 404));
  }

  if (comment.createdBy.toString() !== req.userId.toString()) {
    return next(new APIError('Only comment author can delete comment', 403));
  }

  comment.deleteOne();
  await event.save();

  res.json({
    success: true,
    message: 'Comment deleted',
  });
});

module.exports = {
  getEvents,
  getEvent,
  createEvent,
  updateEvent,
  deleteEvent,
  getMyEvents,
  registerForEvent,
  unregisterFromEvent,
  getRegisteredEvents,
  saveEvent,
  unsaveEvent,
  getSavedEvents,
  uploadEventCover,
  getEventCalendar,
  addTodoItem,
  updateTodoItem,
  deleteTodoItem,
  addPoll,
  voteOnPoll,
  closePoll,
  deletePoll,
  addComment,
  deleteComment,
};
