const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const config = require('./config/env');
const connectDB = require('./config/db');
const initSocket = require('./socket/index');
const apiRoutes = require('./routes/index');
const apiLimiter = require('./middleware/rateLimit.middleware');
const errorHandler = require('./middleware/error.middleware');

const app = express();
const server = http.createServer(app);

// Connect to MongoDB
connectDB();

// Secure app with Helmet headers
app.use(helmet());

// Enable CORS for frontend clients
app.use(
  cors({
    origin: '*', // Accept requests from any client origin for mobile compatibility
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Gzip compression
app.use(compression());

// Parse JSON request bodies
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// HTTP Request logging
if (config.env !== 'test') {
  app.use(morgan('dev'));
}

// Apply rate limiter to all REST API endpoints
app.use('/api', apiLimiter);

// Mount core endpoints
app.use('/api', apiRoutes);

// API Health Check
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK', environment: config.env, time: new Date() });
});

// Catch-all route not found (404)
app.use((req, res, next) => {
  const error = new Error('Endpoint not found');
  error.statusCode = 404;
  next(error);
});

// Register Global Error Boundary
app.use(errorHandler);

// Initialize Socket.io Server
initSocket(server);

// Boot server
const PORT = config.port;
server.listen(PORT, () => {
  console.log(`🚀 Wavvv Server listening on port ${PORT} in [${config.env}] mode.`);
});

module.exports = server;
