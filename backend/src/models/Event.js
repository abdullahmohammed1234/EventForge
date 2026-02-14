const mongoose = require('mongoose');

const eventSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Event title is required'],
      trim: true,
      maxlength: [200, 'Title cannot exceed 200 characters'],
    },
    description: {
      type: String,
      trim: true,
      maxlength: [5000, 'Description cannot exceed 5000 characters'],
    },
    category: {
      type: String,
      enum: [
        'music',
        'sports',
        'arts',
        'food',
        'technology',
        'business',
        'social',
        'outdoor',
        'other',
      ],
      default: 'other',
    },
    city: {
      type: String,
      required: [true, 'City is required'],
      trim: true,
      index: true,
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: [0, 0],
      },
    },
    address: {
      type: String,
      trim: true,
    },
    startTime: {
      type: Date,
      required: [true, 'Start time is required'],
      index: true,
    },
    endTime: {
      type: Date,
    },
    maxAttendees: {
      type: Number,
      min: [1, 'Max attendees must be at least 1'],
    },
    currentAttendees: {
      type: Number,
      default: 0,
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    isPublished: {
      type: Boolean,
      default: true,
    },
    isCancelled: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
    toJSON: {
      virtuals: true,
      transform: (doc, ret) => {
        delete ret.__v;
        return ret;
      },
    },
  }
);

// 2dsphere index for geospatial queries
eventSchema.index({ location: '2dsphere' });

// Compound indexes for common queries
eventSchema.index({ city: 1, startTime: 1 });
eventSchema.index({ category: 1, startTime: 1 });
eventSchema.index({ createdBy: 1, createdAt: -1 });

// Virtual for duration
eventSchema.virtual('duration').get(function () {
  if (this.startTime && this.endTime) {
    return this.endTime - this.startTime;
  }
  return null;
});

// Static method to find upcoming events
eventSchema.statics.findUpcoming = function (limit = 20, skip = 0) {
  return this.find({
    isPublished: true,
    isCancelled: false,
    startTime: { $gte: new Date() },
  })
    .sort({ startTime: 1 })
    .limit(limit)
    .skip(skip)
    .populate('createdBy', 'displayName email avatarUrl city');
};

// Static method to find events by city
eventSchema.statics.findByCity = function (city, limit = 20) {
  return this.find({
    city: { $regex: city, $options: 'i' },
    isPublished: true,
    isCancelled: false,
    startTime: { $gte: new Date() },
  })
    .sort({ startTime: 1 })
    .limit(limit)
    .populate('createdBy', 'displayName email avatarUrl city');
};

// Ensure location is a valid GeoJSON point
eventSchema.pre('save', function (next) {
  if (this.location && this.location.coordinates) {
    // Validate coordinates
    const [lng, lat] = this.location.coordinates;
    if (lng < -180 || lng > 180 || lat < -90 || lat > 90) {
      return next(new Error('Invalid coordinates'));
    }
  }
  next();
});

const Event = mongoose.model('Event', eventSchema);

module.exports = Event;
