require('dotenv').config();
const app = require('./src/app');

const PORT = process.env.PORT || 3000;
const ENV = process.env.NODE_ENV || 'development';

// Start server
const server = app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════════════════╗
║                   Event Planner API                       ║
╠═══════════════════════════════════════════════════════════╣
║  Environment: ${ENV.padEnd(46)}║
║  Server:     http://localhost:${PORT}${''.padEnd(34 - PORT.toString().length)}║
║  API Docs:   http://localhost:${PORT}/api${''.padEnd(29)}║
║  Health:     http://localhost:${PORT}/health${''.padEnd(30)}║
╚═══════════════════════════════════════════════════════════╝
  `);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('Unhandled Promise Rejection:', err);
  // Close server & exit process
  server.close(() => process.exit(1));
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received. Shutting down gracefully...');
  server.close(() => {
    console.log('Process terminated');
    process.exit(0);
  });
});

module.exports = server;
