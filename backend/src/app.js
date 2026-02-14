require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const connectDB = require('./config/database');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

const authRoutes = require('./routes/authRoutes');
const eventsRoutes = require('./routes/eventsRoutes');

// Initialize Express app
const app = express();

// Connect to MongoDB
connectDB();

// Security middleware
app.use(helmet());

// CORS configuration
// Allow all origins for public registration endpoint
app.use(
  cors({
    origin: true, // Allow all origins
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Request parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Root endpoint - API info
app.get('/', (req, res) => {
  res.json({
    name: 'StormForge 2026 Event Planner API',
    version: '1.0.0',
    message: 'API server is running. Use /api for endpoints or /health for status.',
    endpoints: {
      health: 'GET /health',
      api: 'GET /api',
      auth: 'POST /api/auth/register, POST /api/auth/login',
      events: 'GET /api/events, POST /api/events',
    },
  });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/events', eventsRoutes);

// API documentation endpoint
app.get('/api', (req, res) => {
  res.json({
    name: 'Event Planner API',
    version: '1.0.0',
    description: 'API for managing events and user authentication',
    endpoints: {
      auth: {
        'POST /api/auth/register': 'Register a new user',
        'POST /api/auth/login': 'Login user',
        'GET /api/auth/me': 'Get current user profile (auth required)',
        'POST /api/auth/logout': 'Logout user (auth required)',
        'PUT /api/auth/profile': 'Update user profile (auth required)',
      },
      events: {
        'GET /api/events': 'Get all events (with pagination & filters)',
        'GET /api/events/:id': 'Get single event by ID',
        'POST /api/events': 'Create new event (auth required)',
        'PUT /api/events/:id': 'Update event (auth required, owner only)',
        'DELETE /api/events/:id': 'Delete event (auth required, owner only)',
        'GET /api/events/my-events': 'Get events created by current user (auth required)',
      },
    },
  });
});

// 404 handler
app.use(notFoundHandler);

// Error handler
app.use(errorHandler);

module.exports = app;
