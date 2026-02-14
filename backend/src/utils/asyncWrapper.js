/**
 * Async wrapper to catch errors in async route handlers
 * Eliminates need for try-catch in every controller function
 */
const asyncWrapper = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = asyncWrapper;
