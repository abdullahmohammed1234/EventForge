const { validationResult } = require('express-validator');
const User = require('../models/User');
const { generateToken, auth } = require('../middleware/auth');
const asyncWrapper = require('../utils/asyncWrapper');
const { APIError } = require('../middleware/errorHandler');

/**
 * @desc    Register a new user
 * @route   POST /api/auth/register
 * @access  Public
 */
const register = asyncWrapper(async (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array(),
    });
  }

  const { email, password, displayName, city } = req.body;

  // Check if user already exists
  const existingUser = await User.findByEmail(email);
  if (existingUser) {
    return next(new APIError('Email already registered', 400));
  }

  // Create new user
  const user = new User({
    email,
    passwordHash: password,
    displayName: displayName || email.split('@')[0],
    city: city || '',
  });

  await user.save();

  // Generate token
  const token = generateToken(user._id);

  res.status(201).json({
    success: true,
    message: 'Registration successful',
    data: {
      user: {
        id: user._id,
        email: user.email,
        displayName: user.displayName,
        city: user.city,
        createdAt: user.createdAt,
      },
      token,
    },
  });
});

/**
 * @desc    Login user
 * @route   POST /api/auth/login
 * @access  Public
 */
const login = asyncWrapper(async (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array(),
    });
  }

  const { email, password } = req.body;

  // Find user with password
  const user = await User.findOne({ email: email.toLowerCase() }).select(
    '+passwordHash'
  );

  if (!user) {
    return next(new APIError('Invalid email or password', 401));
  }

  // Check if account is active
  if (!user.isActive) {
    return next(new APIError('Account has been deactivated', 401));
  }

  // Verify password
  const isMatch = await user.comparePassword(password);
  if (!isMatch) {
    return next(new APIError('Invalid email or password', 401));
  }

  // Generate token
  const token = generateToken(user._id);

  res.json({
    success: true,
    message: 'Login successful',
    data: {
      user: {
        id: user._id,
        email: user.email,
        displayName: user.displayName,
        city: user.city,
        createdAt: user.createdAt,
      },
      token,
    },
  });
});

/**
 * @desc    Get current user profile
 * @route   GET /api/auth/me
 * @access  Private
 */
const getMe = asyncWrapper(async (req, res, next) => {
  const user = await User.findById(req.userId);
  if (!user) {
    return next(new APIError('User not found', 404));
  }

  res.json({
    success: true,
    data: {
      user: {
        id: user._id,
        email: user.email,
        displayName: user.displayName,
        city: user.city,
        createdAt: user.createdAt,
      },
    },
  });
});

/**
 * @desc    Logout user (client-side token removal)
 * @route   POST /api/auth/logout
 * @access  Private
 */
const logout = asyncWrapper(async (req, res, next) => {
  // Note: JWT is stateless, so logout is handled client-side
  // This endpoint can be used for logging purposes or token blacklisting in v2
  res.json({
    success: true,
    message: 'Logged out successfully',
  });
});

/**
 * @desc    Update user profile
 * @route   PUT /api/auth/profile
 * @access  Private
 */
const updateProfile = asyncWrapper(async (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      errors: errors.array(),
    });
  }

  const { displayName, city } = req.body;

  const user = await User.findByIdAndUpdate(
    req.userId,
    {
      ...(displayName && { displayName }),
      ...(city !== undefined && { city }),
    },
    { new: true, runValidators: true }
  );

  if (!user) {
    return next(new APIError('User not found', 404));
  }

  res.json({
    success: true,
    message: 'Profile updated successfully',
    data: {
      user: {
        id: user._id,
        email: user.email,
        displayName: user.displayName,
        city: user.city,
        updatedAt: user.updatedAt,
      },
    },
  });
});

module.exports = {
  register,
  login,
  getMe,
  logout,
  updateProfile,
};
