const config = require('../config/env');

const errorHandler = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';

  console.error(`[Error] ${req.method} ${req.url} - Status: ${statusCode} - Message: ${message}`);
  if (err.stack && config.env === 'development') {
    console.error(err.stack);
  }

  // Handle Mongoose cast errors or validation errors
  if (err.name === 'ValidationError') {
    statusCode = 400;
    message = Object.values(err.errors).map((val) => val.message).join(', ');
  } else if (err.name === 'CastError') {
    statusCode = 400;
    message = `Resource not found. Invalid field: ${err.path}`;
  }

  res.status(statusCode).json({
    error: message,
    stack: config.env === 'development' ? err.stack : undefined,
  });
};

module.exports = errorHandler;
