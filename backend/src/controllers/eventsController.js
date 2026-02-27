const { validationResult } = require('express-validator');
const mongoose = require('mongoose');
const Event = require('../models/Event');
const asyncWrapper = require('../utils/asyncWrapper');
const { APIError } = require('../middleware/errorHandler');

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

  // Search by title or description
  if (req.query.search) {
    filter.$or = [
      { title: { $regex: req.query.search, $options: 'i' } },
      { description: { $regex: req.query.search, $options: 'i' } },
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
  if (req.userId) {
    const userObjectId = new mongoose.Types.ObjectId(req.userId);
    const registration = event.attendees.find(
      (a) => a.user.toString() === userObjectId.toString() && a.status === 'registered'
    );
    isUserRegistered = !!registration;
  }

  // Convert to plain object and add isUserRegistered
  const eventObj = event.toObject();
  eventObj.isUserRegistered = isUserRegistered;

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
    coordinates: [longitude || 0, latitude || 0],
  };

  const event = new Event({
    title,
    description,
    category: category || 'other',
    city,
    address,
    location,
    startTime: start,
    endTime: endTime ? new Date(endTime) : null,
    maxAttendees: maxAttendees || null,
    createdBy: req.userId,
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
};
